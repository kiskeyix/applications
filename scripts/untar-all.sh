#!/bin/sh
# Last modified: 2004-Sep-09
# Luis Mondesi < lemsx1@hotmail.com >
# 
# DESCRIPTION: use this script to untar
# a bunch of files with extensions: .tar.bz2, .tar.gz

set -e
echo "untarring tar.gz"
for i in `/bin/ls -1 *.tar.gz`; do
    #echo "$i"
    if [ -f $i ]; then
        tar xzf $i
    else
        echo "Skipping $i. Not file"
    fi
done
echo "untarring tar.bz2"
for i in `/bin/ls -1 *.tar.bz2`; do
    #echo "$i"
    if [ -f $i ]; then
        tar xjf $i
    else
        echo "Skipping $i. Not file"
    fi
done
