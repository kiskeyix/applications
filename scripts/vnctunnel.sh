#!/bin/sh
# $Id: vnctunnel.sh,v 1.6 2003-11-03 16:58:56 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Nov-03
#
# DESCRIPTION: creates a tunnel between 2 servers for Vnc

echo "USAGE: $0 SERVER [USER] [PORT]"

VNCVIEWER=vncviewer
# ssh arguments
ARG=" -X "
DPORT="5901" # default port

if [ x$3 != "x" ]; then
    #  -a $3 -ge 5900
    echo "Connect using the command '$VNCVIEWER localhost:$3'"
else
    echo "Connect using the command '$VNCVIEWER localhost:$DPORT'"
fi

if [ x$2 != "x" -a  x$3 = "x" ]; then
    ssh $ARG -L $DPORT:localhost:$DPORT $2@$1
elif [ x$3 != "x" ]; then
    ssh $ARG -L $3:localhost:$3 $2@$1
else
    ssh $ARG -L $DPORT:localhost:$DPORT $1
fi



