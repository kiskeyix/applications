#!/bin/sh
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com >
# This script moves all files containing name NAME
# case insensitive,
# from directory one to directory two... recursively!
# what a relieve!
# 
if [ -d $1 -a -d $3 -a $2 ]; then
    clear;
    # find in directory $1 without descending to directory $3,
    # the files containing $2 insensitively
    # and then execute mv verbosely ...
    find $1 -path "$3" -prune -o -iname "*$2*" -type f -exec mv -iv {} $3 \; ;
else
    echo "Usage: mvall.sh PATHfromDIR NAMEofFILE PATHtoDIRtoMOVEto";
fi
