#!/bin/sh
# $Revision: 1.4 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A simple script to burn a .iso DVD Video to the drive
# USAGE: write_dvd.sh {/path/to/dvd.iso|/path/to/dir}
# CHANGELOG:
# LICENSE: GPL

if [ -f $1 ]; then
    growisofs -dvd-video -udf -dvd-compat -Z /dev/dvd=$1
elif [ -d $1 ]; then
    growisofs -dvd-video -udf -dvd-compat -Z /dev/dvd $1
else 
    echo "Usage: write_dvd.sh {dvd.iso|directory}"
fi
