#!/bin/sh
# $Revision: 1.3 $
# $Date: 2007-03-01 21:41:46 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION:
# Script to distribute commands to 
# an array of servers. Useful for
# clusters and maintaining lots of servers
# USAGE: $0 <cmd> [args]
# LICENSE: GPL
# FILES: ~/.remote-hosts    # user's remote hosts. formatted like /etc/hosts (man 5 hosts)

# TODO add hostname ( \2 )
HOSTS="`sed 's/^\([0-9\.]\+[0-9]\+\).*/\1/' ~/.remote-hosts`"
RSH="ssh"

R_CMD="$@"

#echo "hosts: $HOSTS"

if [ "x$1" != "x" ]; then
    # at least one command was given
    for i in $HOSTS; do
        echo "$RSH $i $R_CMD"
        $RSH $i $@
    done
else
    printf "Usage: $0 <CMD> [args] \n \t Where CMD is any command \n Put your remote hosts names/ips (one per line) in ~/.remote-hosts (man 5 hosts)"
fi
