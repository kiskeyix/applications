#!/bin/sh
# $Id: vnctunnel.sh,v 1.7 2004-01-19 02:34:32 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Jan-18
#
# DESCRIPTION: creates a tunnel between 2 servers for Vnc

echo "USAGE: $0 SERVER [USER] [PORT]"

VNCVIEWER=vncviewer
# ssh arguments
ARG=" -X "
DPORT="5901" # default port

if [ x$3 != "x" ]; then
    #  -a $3 -ge 5900
    echo "Connect using the command '$VNCVIEWER 127.0.0.1:$3'"
else
    echo "Connect using the command '$VNCVIEWER 127.0.0.1:$DPORT'"
fi

if [ x$2 != "x" -a  x$3 = "x" ]; then
    ssh $ARG -L $DPORT:127.0.0.1:$DPORT $2@$1
elif [ x$3 != "x" ]; then
    ssh $ARG -L $3:127.0.0.1:$3 $2@$1
else
    ssh $ARG -L $DPORT:127.0.0.1:$DPORT $1
fi



