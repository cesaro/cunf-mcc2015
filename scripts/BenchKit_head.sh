#!/bin/bash

# BK_EXAMINATION: it is a string that identifies your "examination"

export PATH="$PATH:$HOME/BenchKit/bin/"

debug ()
{
	echo "bkh:" "$*" >&2
}

info ()
{
	echo "bkh:" "$*" >&2
}

timeit ()
{
	if uname -a | grep -qi darwin; then
		timeit_mac $*
	else
		timeit_linux $*
	fi
}

timeit_mac ()
{
	/usr/bin/time -l -- $* 2> bk.time
	EXITST=$?
	WALLTIME=$(head -n1 bk.time | sed 's/real.*//g;s/ //g')s
	M=$(head -n2 bk.time | tail -n1 | sed 's/max.*//g;s/ //g')
	MAXRSS=$(($M / 1024 / 1024))MB
}

timeit_linux ()
{
	/usr/bin/time -f '%e\n%M' -o bk.time "$@"
	EXITST=$?
	WALLTIME=$(head -n1 bk.time)s
	MAXRSS=$(($(tail -n1 bk.time) / 1024))MB
}


mycat ()
{
	#cat "$@"
	cat "$@" >&2
}

translate_model ()
{
	if test -f model.ll_net; then return 0; fi
	debug "translating PNML into contextual PEP ..."
	#mcc15-helper.py pnml2pep model.pnml model-ra.ll_net >&2
	mcc15-helper.py pnml2pep model.pnml model.ll_net >&2
	if [ "$?" != "0" ]; then
		info "Error: pnml2pep: PNML translation failed, quite probably the net is not 1-safe"
		echo "DO_NOT_COMPETE"
		exit 0
	fi
	debug "translating contextual PEP into PR..."
	#cont2pr.pl < model-ra.ll_net > model.ll_net
	#rm model-ra.ll_net > /dev/null
}

translate_spec ()
{
	if test -f $BK_EXAMINATION.cunf; then return 0; fi
	debug "translating specification..."
	mcc15-helper.py xml2cunf $BK_EXAMINATION.xml $BK_EXAMINATION.cunf >&2
	if [ "$?" != "0" ]; then
		info "Error: xml2cunf: returns error state, aborting"
		echo "DO_NOT_COMPETE"
		exit 0
	fi
}

cunf_unsafe_net ()
{
	info "Error: cunf seems to detect the net is not safe, aborting"
	mycat cunf.out
	mycat cunf.err
	echo "DO_NOT_COMPETE"
	exit 0
}

do_verif ()
{
	translate_model
	translate_spec

	debug "running cunf ..."
	cunf -i model.ll_net $BK_EXAMINATION.cunf > cunf.out 2> cunf.err
	#info "cunf    : time $WALLTIME maxrss $MAXRSS" | tee -a ri.times
	#if [ "$EXITST" != 0 ]; then
	if [ "$?" != 0 ]; then
		if grep -q 'is not safe' cunf.err; then cunf_unsafe_net; fi
		info "Error: cunf returns an error state, aborting"
		mycat cunf.out
		mycat cunf.err
		echo "CANNOT_COMPUTE"
		exit 0
	fi

	grep "cpu\|memory\|^events\|tor co\|tor mrk\|cutoff" cunf.out >&2
	#mycat cunf.out

	#debug "Mixing formula ids and verification results"
	grep '^#' $BK_EXAMINATION.cunf > tmp.ids
	grep '^Result   :' cunf.out > tmp.results

	#mycat tmp.ids
	#mycat tmp.results
	#return 0

	let "n = $(wc -l < tmp.ids)"
	let "m = $(wc -l < tmp.results)"
	#debug "$n lines in tmp.ids; $m lines in tmp.results"
	if [ "$n" != "$m" ]; then
		info "WARNING: mismatch between # of formula ids and # of result lines"
		info "Specification file:"
		mycat $BK_EXAMINATION.cunf
		info "Results file:"
		mycat cunf.out
	fi

	exec 3< tmp.ids
	exec 4< tmp.results
	for ((i = 1; i <= n; i++))
	do
		read -u 3 lineid
		read -u 4 lineres
		negate=${lineid:9:1}
		id=`echo "${lineid:14}" | sed 's/ txt=.*//g'`
		res=${lineres:11}
		#debug "negate '$negate' id '$id' result '$res'"

		if [ "$negate" == "Y" ]; then
			if [ "$res" == "SAT" ]; then
				res=UNSAT
			elif [ "$res" == "UNSAT" ]; then
				res=SAT
			fi
		fi
		if [ "$res" == "SAT" ]; then
			echo "FORMULA $id TRUE TECHNIQUES NET_UNFOLDING SAT_SMT"
		elif [ "$res" == "UNSAT" ]; then
			echo "FORMULA $id FALSE TECHNIQUES NET_UNFOLDING SAT_SMT"
		else
			echo "FORMULA $id CANNOT_COMPUTE"
		fi
	done
}

function main () {
	#debug "PWD '$PWD'"
	#debug "BK_EXAMINATION '$BK_EXAMINATION'"
	#debug "iscolored `cat iscolored`"

	if [ "$(cat iscolored)" == "TRUE" ]; then
		echo "DO_NOT_COMPETE"
		exit 0
	fi

	case "$BK_EXAMINATION" in

		"ReachabilityDeadlock" | \
		"ReachabilityFireability" | \
		"ReachabilityFireabilitySimple" )
			do_verif
			;;

		*)
			info "cannot handle this examination"
			echo "DO_NOT_COMPETE"
			;;
	esac
	exit 0
}

main
