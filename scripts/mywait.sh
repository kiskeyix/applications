#!/bin/sh
# Luis Mondesi < lemsx1@hotmail.com >
#
# Pauses for SLEEP seconds until command CMD executes
# repeatedly ...
# 
# usage: mywait.sh SECONDS CMD
#
# BUGS: only accepts 127 arguments... will fix later

#SLEEP=20

if [ "x$1" != "x" -a "x$2" != "x" ]; then
    SLEEP=$1
    CMD=`echo $@ | cut -d" " -f2-127`
    while true;
    do
        #echo ${2+"$@"}
        $CMD
        sleep $SLEEP
    done
fi
