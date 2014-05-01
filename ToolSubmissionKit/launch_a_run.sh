#!/bin/bash
#set -x

################################################################################
# Decoder la ligne de commandes

if [ $# -lt 2 ] ; then
	echo "usage "`basename $0`" disk-image-name test-name"
	exit
fi
DISK_IMAGE="$1"
A_TEST="$2"

if [ "$TOOL_NAME" ] ; then
	A_TOOL="$TOOL_NAME"
else
	A_TOOL=`basename $DISK_IMAGE | cut -d '.' -f 1`
fi

################################################################################
# Au travail!!!

export SUM_FILE="$OUTPUT_DIR/node_${NODE_NUMBER}_CSV/summary-$A_TOOL.csv"
TMP_FILE="/tmp/tmp-"$$

echo "runnning $A_TOOL on $A_TEST ($AN_EXAMINATION)"
CONF_FILE="$OUTPUT_DIR/node_${NODE_NUMBER}_CONFIGURATIONS/$A_TEST-$AN_EXAMINATION.conf"
cat invocation_template.txt | sed -e "
s/__TEST_NAME__/$A_TEST/g
s/__TOOL_NAME__/$A_TOOL/g
s/__BENCHKIT_VERSION__/$BENCHKIT_VERSION/g
s/__EXAMINATION_TYPE__/$AN_EXAMINATION/g
" > $CONF_FILE

sh launch_a_command.sh "$DISK_IMAGE" "`cat $CONF_FILE`" -tool $A_TOOL -test $A_TEST > $TMP_FILE
BEFORE=`grep ^START $TMP_FILE | cut -d ' ' -f 2`
AFTER=`grep ^STOP $TMP_FILE | cut -d ' ' -f 2`
if [ -z "$AFTER" ] ; then
	DIFFERENCE="-"
else
	DIFFERENCE=`expr $AFTER - $BEFORE`
fi
echo "We got on stdout:"
cat $TMP_FILE
