#!/bin/sh
# Last modified: 2004-Sep-09
# Luis Mondesi < lemsx1@hotmail.com >
# 
# DESCRIPTION: use this script to tar
# a bunch of directories with extensions: .bz2

set -e
echo "tarring tar.bz2"
for i in `/bin/ls -1 $1`; do
    #echo "$i"
    if [ -d $i ]; then
        tar cjvf $1/$i.tar.bz2 $1/$i
    else
        echo "Skipping $i. Not directory"
    fi
done

