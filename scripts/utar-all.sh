#!/bin/sh
# Last modified: 2003-Sep-26
# Luis Mondesi < lemsx1@hotmail.com >
# $Revision: 1.3 $
# 
# DESCRIPTION: use this script to untar
# a whole directory with extensions: .bz2
# or .gz, .tgz

if [ -d $1 ]; then
    echo -e "looking for .bz2 \n";
    for i in `ls $1/*tar.bz2`; do
        #echo -e "$i \n";
        tar -xjvf $i;
    done
    for i in `ls $1/*.tbz2`; do
        tar -xzvf $i;
    done

    echo -e "looking for .*gz \n";
    for i in `ls $1/*tar.gz`; do
        tar -xzvf $i;
    done
    for i in `ls $1/*.tgz`; do
        tar -xzvf $i;
    done
else
    echo "Usage: $0 DIRECTORY"
fi
