#!/bin/sh
#
# Luis Mondesi < lemsx1@hotmail.com >
#
# Script to distribute commands to 
# an array of servers. Useful for
# clusters and maintaining lots of servers
#
# FILES: ~/.remote-hosts    # user's remote hosts. formatted like /etc/hosts (man 5 hosts)
#

# TODO add hostname ( \2 )
HOSTS="`sed 's/^\([0-9\.]\+\) \([a-zA-Z\.]\).*/\1/' ~/.remote-hosts`"
RSH=ssh

R_CMD="$@"

OLD_IFS="$IFS"

#echo "hosts: $HOSTS"

if [ "x$1" != "x" ]; then
    #IFS=";"
    for i in $HOSTS; do
        # IFS=""
        #set -- `echo $i`
        #IP="$1.$2.$3.$4"
        #echo "IP: $i []"
        #HOST=$@
        echo "$RSH $i $R_CMD"
        $RSH $i $@
        #done
    done
else
    echo -e "Usage: $0 CMD \n \t Where CMD is any command \n Put your remote hosts names/ips (one per line) in ~/.remote-hosts (man 5 hosts)"
fi

IFS=$OLD_IFS
