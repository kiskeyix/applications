#!/bin/sh
# Last modified: 2003-Feb-05
# Luis Mondesi < lemsx1@hotmail.com >
# $Revision: 1.2 $
# 
# DESCRIPTION: use this script to untar
# a whole directory with extensions: .bz2
# or .gz, .tgz

if [ -d $1 ]; then
    echo -e "looking for .bz2 \n";
    for i in `ls $1/*.bz2`; do
        #echo -e "$i \n";
        tar -xjvf $i;
    done

    echo -e "looking for .*gz \n";
    for i in `ls $1/*.*gz`; do
        tar -xzvf $i;
    done
else
    echo "Usage: $0 DIRECTORY"
fi
