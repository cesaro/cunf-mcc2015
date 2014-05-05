#!/bin/bash
# BK_EXAMINATION: it is a string that identifies your "examination"
# BK_INPUT: it is a string that identifies your test (used to build the name of the directory where you execute)

#export BK_EXAMINATION=ReachabilityDeadlock

export PATH="$PATH:$HOME/BenchKit/bin/"

debug ()
{
	echo "bkh:" "$*" >&2
}

info ()
{
	echo "bkh:" "$*"
}

timeit ()
{
	/usr/bin/time -f '%e\n%M' -o bk.time "$@"
	EXITST=$?
	WALLTIME=$(head -n1 bk.time)s
	MAXRSS=$(($(tail -n1 bk.time) / 1024))MB
}

mycat ()
{
	cat "$@"
	#cat "$@" >&2
}

do_verif ()
{
	#debug "Translating the formula ..."
	timeit mcc2cunf < "$BK_EXAMINATION.xml" > "cunf.spec"
	info "mcc2cunf: time $WALLTIME maxrss $MAXRSS" | tee -a ri.times
	if [ "$EXITST" != 0 ]; then
	#if [ "$?" != 0 ]; then
		info "Error: mcc2cunf returns error state, aborting"
		echo "DO_NOT_COMPETE"
		exit 0
	fi

	#debug "Translating PNML into PEP (+ place-replication encoding)..."
	timeit sh -c 'pnml2pep_mcc14.py < model.pnml 2> model.err | cont2pr.pl > model.ll_net'
	info "pnml2pep: time $WALLTIME maxrss $MAXRSS" | tee -a ri.times
	if [ "$(cat model.err)" ]; then
		info "Error: problems while translating PNML to PEP"
		info "Error: quite probably the net is not 1-safe"
		echo "DO_NOT_COMPETE"
		exit 0
	fi

	#debug "Running Cunf ..."
	timeit cunf model.ll_net cunf.spec > cunf.out 2> cunf.err
	info "cunf    : time $WALLTIME maxrss $MAXRSS" | tee -a ri.times
	if [ "$EXITST" != 0 ]; then
	#if [ "$?" != 0 ]; then
		if grep -q 'is not safe' cunf.err; then
			info "Error: cunf seems to detect the net is not safe, aborting"
			mycat cunf.out
			mycat cunf.err
			echo "DO_NOT_COMPETE"
			exit 0
		fi
		info "Error: cunf returns an error state, aborting"
		mycat cunf.out
		mycat cunf.err
		echo "CANNOT_COMPUTE"
		exit 0
	fi

	#debug "Mixing formula ids and verification results"
	grep '^#' cunf.spec > tmp.ids
	grep '^Result   :' cunf.out > tmp.results

	#echo "Result   : UNSAT" > tmp.results
	#> tmp.results

	let "n = $(wc -l < tmp.ids)"
	let "m = $(wc -l < tmp.results)"
	#debug "$n lines in tmp.ids; $m lines in tmp.results"
	if [ "$n" != "$m" ]; then
		info "WARNING: mismatch between # of formula ids and # of result lines"
		info "Specification file:"
		mycat cunf.spec
		info "Results file:"
		mycat cunf.out
	fi

	exec 3< tmp.ids
	exec 4< tmp.results
	for ((i = 1; i <= n; i++))
	do
		read -u 3 lineid
		read -u 4 lineres
		negate=${lineid:2:1}
		id=${lineid:4}
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

	#debug "cunf spec file:"
	#mycat cunf.spec >&2
	#debug "cunf stdout:"
	#mycat cunf.out >&2
	#debug "cunf stderr:"
	#mycat cunf.err >&2
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
