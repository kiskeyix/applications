#!/bin/bash
# Last modified: 2002-Jul-30
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

echo -e "unzipping .zip \n";

if [ -z "$1" ]; then
    DIR=$1;
else
    DIR=.
fi
for i in `ls $1/*.zip`; do
    #echo -e "$i \n";
        unzip $DIR/$i.zip;
done

