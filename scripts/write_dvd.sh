#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A simple script to burn a .iso DVD Video to the drive
# USAGE: write_dvd.sh dvd.iso
# CHANGELOG:
# LICENSE: GPL

if [ -f $1 ]; then
    growisofs -dvd-compat -Z /dev/dvd=$1 -dvd-video
else 
    echo "Usage: write_dvd.sh dvd.iso"
fi
