#!/bin/bash
# Last modified: 2002-Apr-03
# Luis Mondesi < lemsx1@hotmail.com >
# 
# DESCRIPTION: use this script to untar
# a whole directory with extensions: .bz2
# or .gz, .tgz

echo -e "tarring tar.bz2 \n";
for i in `ls $1`; do
    #echo -e "$i \n";
    tar -cjvf $1/$i.tar.bz2 $1/$i;
done

