#!/bin/sh
#
# Luis Mondesi < lemsx1@hotmail.com >
#
# Script to distribute commands to 
# an array of servers. Useful for
# clusters and maintaining lots of servers
#

HOSTS="`cat ~/.remote-hosts`"
RSH=ssh

if [ "x$1" != "x" ]; then
    for i in $HOSTS; do
        echo -e "$RSH $i $@ \n"
        $RSH $i $@
    done
else
    echo -e "Usage: $0 CMD \n \t Where CMD is any command \n Put your remote hosts names/ips (one per line) in ~/.remote-hosts"
fi
