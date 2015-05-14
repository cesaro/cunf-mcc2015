#!/bin/bash

# running on the virtual maching the examination $EXAM for all models in
# doc/models-1

#EXAM=ReachabilityDeadlock
EXAM=ReachabilityFireability
#EXAM=ReachabilityFireabilitySimple

VMDK=/x/home/saiph/vm/mcc2015/mcc2015.vmdk

cd ToolSubmissionKit
for M in `cat ../doc/models-1 | grep -v '^#'`; do
	echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	echo "processing '$M'"
	./BenchKitStart.sh $VMDK $EXAM cunf $M
done

