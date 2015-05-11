#!/bin/bash

################################################################################
# Constantes de base

# definition, si ce n'est pas une variable d'environnement, du time-out
if [ -z "$MAXTIME" ] ; then
	MAXTIME="30" 
fi

if [ -z "$SSHP" ] ; then
	SSHP="2222" 
fi

# if [ -z "$PROCESSOR" ] ; then
# 	MAXTIME="C1" 
# fi

################################################################################
# Decoder la ligne de commandes

if [ "$1" = "-help" ] ; then
	echo "usage "`basename $0`" [-help]"
	echo "      "`basename $0`" disk-image command-to-operate [-tool toolname] [-test testname]"
	exit
elif [ $# -lt 2 ] ; then
	echo "bad invocation, please run '"`basename $0`" -help' for documentation"
	exit
fi
VMPATH="$1"
COMMAND="$2"
shift 2
if [ "$1" = "-tool" ] ; then
	THE_TOOL_NAME=$2
	shift 2
else
	THE_TOOL_NAME="no_tool"
fi
if [ "$1" = "-test" ] ; then
	THE_TEST_NAME=$2
	shift 2
else
	THE_TEST_NAME="test_with_no_name"
fi

if [ -z "$RUN_IDENTIFIER" ] ; then
	RUN_IDENTIFIER="run-id"
fi

################################################################################
# Parametrages divers

if [ -z "$A_F_RADIX" ] ; then
	LOG_FILE="$OUTPUT_DIR/node_${NODE_NUMBER}_CSV/run-${THE_TOOL_NAME}-${THE_TEST_NAME}-${RUN_IDENTIFIER}.csv"
else
	LOG_FILE="$OUTPUT_DIR/node_${NODE_NUMBER}_CSV/run-${A_F_RADIX}-${THE_TOOL_NAME}-${THE_TEST_NAME}-${RUN_IDENTIFIER}.csv"
fi

if [ -z "$SUM_FILE" ] ; then
	SUM_FILE="/data1/CSV/summary-${THE_TOOL_NAME}.csv"	
fi # sinon elle este xportee par l'appelant

STDERR_FILE="$OUTPUT_DIR/node_${NODE_NUMBER}_OUTPUTS/log-${THE_TOOL_NAME}-${THE_TEST_NAME}-${RUN_IDENTIFIER}.stderr"

################################################################################
# Au travail!!!

# demarrer la VM
sh vm.sh $VMPATH 2> /dev/null
# lancer la commande
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$BENCHKIT_DIR/bk-private_key" -p "$SSHP" $VM_LOGIN@localhost "$COMMAND" 2>> "$STDERR_FILE"
# arreter la VM
#ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$BENCHKIT_DIR/bk-private_key" -p "$SSHP" root@localhost "halt"
