#!/bin/bash

main ()
{

	# this script re-adds the .txt files from the original .tgz files into the
	# repacked ones, since Fabrice's scripts aparently rely on them ...

	#set -x
	ORIG=/x/research/mcc/2015/cunf-mcc2015/INPUTS-known-2015
	MODIF=/x/research/mcc/2015/cunf-mcc2015/INPUTS-repacked
	DEST=~/repack-dest

	rm -Rf "$DEST"
	mkdir -p "$DEST"

	for M in `ls $ORIG | grep PT | sed 's/.tgz$//'`; do
		echo "================================================="
		echo "processing '$M'"
		rm -Rf $DEST/tmp
		mkdir -p $DEST/tmp

		# unpack modified
		echo "tar x"
		cd $DEST/tmp
		tar xzvf "$MODIF/$M.tgz"

		# add .txt files from the original
		echo "tar x"
		tar xzvf "$ORIG/$M.tgz" --wildcards '*.txt'

		# display, repack, and leave
		echo "ls"
		ls -lh "$M"
		tar czf $M.tgz $M
		mv $M.tgz ..
		cd ..

		echo "result:"
		ls -lh $DEST/$M.tgz
	done
}

main
