#!/bin/bash
# Last modified: 2002-Sep-19
# Luis Mondesi < lemsx1@hotmail.com >
# 
# DESCRIPTION: use this script to unzip
# a whole directory with extensions: .zip
# 
# USAGE: unzip-all.sh DIR
#
# TODO: generalize this to do commands given
# the extension as a second argument: uall.sh DIR EXT
#

if [ -d "$1" ]; then

    if [ "$2" ]; then
        for i in `/bin/ls $1/*.$2`; do
            if [ $2 -eq "zip" ];then
                unzip $1/$i;
            elif [ $2 -eq "gz" ]; then
                gunzip $1/$i;
            elif [ $2 -eq "bz2" ]; then
                bunzip2 $1/$i;
            fi
        done
    else
        for i in `/bin/ls $1/*.zip`; do
            #echo -e "$i \n";
            unzip $i;
        done
    fi

fi
