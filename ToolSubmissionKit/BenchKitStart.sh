#!/bin/bash

display_usage () {
	echo "usage: $0 [-m <val>] [-vnc <val>] [-ssh <val>] <disk-image> <bk-examination> <tool-name> <input>"
	echo "       -m: <val> Mbyte of memory confinment are assumed (default is 1024)"
	echo "     -vnc: <val> is the VNC port for the launched VM (default is 42)"
	echo "     -ssh: <val> is the SSH port for the launched VM (default is 2222)"
	echo
	echo "     <disk-image>     : the path of the disk image to be booted and executed by the VM"
	echo "     <bk-examination> : see BenchKit documentation, the variable defining what operation is to be executed on the VM"
	echo "     <tool-name>      : see BenchKit documentation, the name of the tool"
	echo "     <input>          : see BenchKit documentation, the name of the directory where the tool is executed"
	echo
	echo "IMPORTANT: you must run $0 in the directory you unpack the distribution."
}

export BENCHKIT_VERSION="version MCC2014 (monitoring deactivated, Feb 23, 2014)"

if [ $# -eq 0 -o "$1" = "--help" -o "$1" = "-h" ] ; then
	display_usage
	exit
fi

export MAXTIME="120" # no effect because it is disabled

if [ "$1" = "-m" ] ; then
	export MAXMEM="$2"
	shift 2
else
	export MAXMEM="1024"
	echo "   no memory confinment provided, assuming $MAXMEM MBytes"
fi

export OUTPUT_DIR="/tmp/BenchKit"

if [ "$1" = "-vnc" ] ; then
	export VNC="$2"
	shift 2
else
	export VNC="42"
	echo "   no VNC port specified, assuming $VNC"
fi

if [ "$1" = "-ssh" ] ; then
	export SSHP="$2"
	shift 2
else
	export SSHP="2222"
	echo "   no ssh redirection port specified, assuming $SSHP"
fi

if [ $# -ne 4 ]; then
	display_usage
	exit	
else
	export DIMG_FILE="$1"
	export VM_LOGIN="mcc"
	export RUN_IDENTIFIER="testing-run"
	export AN_EXAMINATION="$2"
	export TOOL_NAME="$3"
	export AN_INPUT="$4"
fi

if [ ! -f "$DIMG_FILE" ] ; then
	echo 
	echo "$DIMG_FILE should be a file of a format supported by qemu-kvm"
	exit
fi

export NODE_NUMBER="00"  # no special meaning for PersonnalBenchKit
export BENCHKIT_DIR=$(pwd) # we assume all files are local

if [ -d "$OUTPUT_DIR" ] ; then
   if [ ! -d "$OUTPUT_DIR/node_${NODE_NUMBER}_CSV" ] ; then
      mkdir "$OUTPUT_DIR/node_${NODE_NUMBER}_CSV"
   fi
   if [ ! -d "$OUTPUT_DIR/node_${NODE_NUMBER}_OUTPUTS" ] ; then
      mkdir "$OUTPUT_DIR/node_${NODE_NUMBER}_OUTPUTS"
   fi
   if [ ! -d "$OUTPUT_DIR/node_${NODE_NUMBER}_CONFIGURATIONS" ] ; then
      mkdir "$OUTPUT_DIR/node_${NODE_NUMBER}_CONFIGURATIONS"
   fi
else
   mkdir "$OUTPUT_DIR"
   mkdir "$OUTPUT_DIR/node_${NODE_NUMBER}_CSV"
   mkdir "$OUTPUT_DIR/node_${NODE_NUMBER}_OUTPUTS"
   mkdir "$OUTPUT_DIR/node_${NODE_NUMBER}_CONFIGURATIONS"
fi

(echo 
echo "execution on "`uname -n`" (runId=$RUN_IDENTIFIER)"
echo "====================================================================="
sh launch_a_run.sh "$DIMG_FILE" "$AN_INPUT" ) | tee $OUTPUT_DIR/node_${NODE_NUMBER}_OUTPUTS/$RUN_IDENTIFIER.output










