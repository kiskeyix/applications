#!/bin/sh
# $Id: rcp.sh,v 1.1 2002-09-15 00:31:59 luigi Exp $
# Last modified: 2002-Aug-30
# Luis Mondesi < lemsx1@hotmail.com >
#
# Script to distribute files to 
# an array of servers. Useful for
# clusters and maintaining lots of servers
#

HOSTS="sal carlo julio mardou"
RSYNC="rsync -e ssh -auvz"
if [ "x$1" != "x" ]; then
    for i in $HOSTS; do
        echo ">>>-------<<< \n $RSYNC $1 $i:$1 \n"
        $RSYNC $1 "$i:$1"
    done
else
    echo "Usage: $0 /path/to/file \n \n"
fi
