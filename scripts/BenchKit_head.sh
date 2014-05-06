#!/bin/bash
# BK_EXAMINATION: it is a string that identifies your "examination"
# BK_INPUT: it is a string that identifies your test (used to build the name of the directory where you execute)

#export BK_EXAMINATION=ReachabilityDeadlock

export PATH="$PATH:$HOME/BenchKit/bin/"

function debug () {
	echo "bkh:" $* >&2
}

function info () {
	echo "bkh:" $* >&2
}

runit () {

	debug "Translating the formula ..."
	mcc2cunf < "$BK_EXAMINATION.xml" > "cunf.spec"
	if [ "$?" != 0 ]; then
		info "Error: mcc2cunf returns error state, aborting"
		echo "DO_NOT_COMPETE"
		exit 0
	fi

	debug "Translating PNML into PEP (+ place-replication encoding)..."
	pnml2pep.py < model.pnml | cont2pr.pl > model.ll_net

	debug "Running Cunf ..."
	cunf model.ll_net cunf.spec > cunf.out 2> cunf.err
	if [ "$?" != 0 ]; then
		info "Error: cunf returns an error state, aborting"
		cat cunf.out >&2
		cat cunf.err >&2
		echo "CANNOT_COMPUTE"
		exit 0
	fi

	# FIXME here
	debug "cunf stdout:"
	cat cunf.out >&2
	debug "cunf stderr:"
	cat cunf.err >&2
}

function main () {
	debug "PWD '$PWD'"
	debug "BK_EXAMINATION '$BK_EXAMINATION'"
	debug "iscolored `cat iscolored`"

	if [ "$(cat iscolored)" == "TRUE" ]; then
		echo "DO_NOT_COMPETE"
		exit 0
	fi

	case "$BK_EXAMINATION" in

		"ReachabilityDeadlock")
			runit
			;;

		*)
			debug "cannot handle this examination"
			echo "DO_NOT_COMPETE"
			;;
	esac
	exit 0
}

main
