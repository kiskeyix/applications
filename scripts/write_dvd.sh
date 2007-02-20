#!/bin/sh
# $Revision: 1.7 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A simple script to burn a .iso DVD Video to the drive
# USAGE: write_dvd.sh {/path/to/dvd.iso|/path/to/dir} [LABEL]
# CHANGELOG:
# LICENSE: GPL

if [ -f "$1" ]; then
    growisofs -dvd-compat -Z "/dev/dvd=$1"
elif [ -d "$1" ]; then
    if [ -n "$2" ]; then
        growisofs -V "$2" -dvd-video -udf -dvd-compat -Z /dev/dvd "$1"
    else
        growisofs -V "$1" -dvd-video -udf -dvd-compat -Z /dev/dvd "$1"
    fi
else 
    echo "Usage: write_dvd.sh {dvd.iso|directory} [LABEL]"
fi
