#!/bin/sh
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@hotmail.com >
#
# Prints tcp and udp connections that are listening
# similar to "netstat -l"
if [ $1 ]; then
    netstat -na | egrep -i "(tcp|udp)" | egrep -i "$1"
else
    netstat -na | egrep -i "(tcp|udp)"
fi
