#!/bin/bash

# BK_EXAMINATION: it is a string that identifies your "examination"

export PATH="$PATH:/home/mcc/BenchKit/bin/"

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

do_verif ()
{
	id=123
	echo "FORMULA $id TRUE TECHNIQUES NET_UNFOLDING SAT_SMT"
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
