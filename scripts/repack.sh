#!/bin/bash

translate_model ()
{
	if test -f model.ll_net; then
		rm -f model.pnml
		return
	fi

	#mcc15-helper.py pnml2pep model.pnml model-ra.ll_net
	mcc15-helper.py pnml2pep model.pnml model.ll_net
	if [ "$?" != "0" ]; then
		echo "Error: PNML translation failed, is net safe?"
		rm -f model.ll_net
		return
	fi
	#cont2pr.pl < model-ra.ll_net > model.ll_net
	#rm model-ra.ll_net > /dev/null

	# remove pnml if we successfully generated the ll_net
	if test -f model.ll_net; then rm -f model.pnml; fi
}

translate_spec ()
{
	EXAM="$1"
	if test -f $EXAM.cunf; then
		rm -f $EXAM.xml
		return
	fi
	mcc15-helper.py xml2cunf $EXAM.xml $EXAM.cunf
	if [ "$?" != "0" ]; then
		echo "Error: property translation failed"
		rm -f $EXAM.cunf
		return
	fi
	# remove xml if we successfully generated the .cunf
	if test -f $EXAM.cunf; then rm -f $EXAM.xml; fi
}

main ()
{
	# this script takes as input the original set of .tgz files in the
	# ~/BenchKit/INPUTS folder, translates specifications into Cunf's format and
	# removes unnecesary files

	#set -x
	export PATH="$PATH:$HOME/BenchKit/bin/"
	BKHOME=~/BenchKit
	DEST=~/repack-dest

	rm -Rf "$DEST"
	mkdir -p "$DEST"

	for M in `cat /tmp/models | grep -v '^#'`; do
		echo "================================================="
		echo "processing '$M'"
		rm -Rf $DEST/tmp
		mkdir -p $DEST/tmp

		# unpack
		cd $DEST/tmp
		tar xzvf "$BKHOME/INPUTS/$M.tgz"
		cd "$M"

		# translate
		translate_model
		for P in Reachability{Deadlock,Fireability,FireabilitySimple}; do
			translate_spec $P
		done

		# remove useless files
		rm -f *.txt
		rm -f CTL*.xml LTL*.xml
		rm -f Reach*{Bounds,Cardinality,ComputeBounds}.xml

		# display, repack, and leave
		cd ..
		ls -lh "$M"
		tar czf $M.tgz $M
		mv $M.tgz ..
		cd

		echo "result:"
		ls -lh $DEST/$M.tgz
	done
}

main
