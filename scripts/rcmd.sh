#!/bin/sh
#
# Luis Mondesi < lemsx1@hotmail.com >
#
# Script to distribute commands to 
# an array of servers. Useful for
# clusters and maintaining lots of servers
#

HOSTS="sal japhy carlo julio mardou"
RSH=rsh

if [ "x$1" != "x" ]; then
    for i in $HOSTS; do
        echo -e "$RSH $i $@ \n"
        $RSH $i $@
    done
else
    echo -e "Usage: $0 CMD \n \t Where CMD is any command \n"
fi
