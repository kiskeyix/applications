#!/bin/bash
# Last modified: 2002-Mar-31
# Luis Mondesi < lemsx1@hotmail.com >
# 
# DESCRIPTION: use this script to untar
# a whole directory with extensions: .bz2
# or .gz, .tgz

echo -e "Untarring .bz2 \n";
for i in `ls $1/*.bz2`; do
    #echo -e "$i \n";
    tar -xjvf $i;
done

echo -e "Untarring .*gz \n";
for i in `ls $1/*.*gz`; do
    tar -xzvf $i;
done
