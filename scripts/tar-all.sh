#!/bin/bash
# Last modified: 2003-Sep-29
# Luis Mondesi < lemsx1@hotmail.com >
# 
# DESCRIPTION: use this script to tar
# a bunch of directories with extensions: .bz2

set -e
echo -e "tarring tar.bz2 \n";
for i in `ls $1`; do
    #echo -e "$i \n";
    tar -cjvf $1/$i.tar.bz2 $1/$i;
done

