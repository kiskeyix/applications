#!/bin/sh
# $Id: vnctunnel.sh,v 1.8 2004-09-09 17:12:24 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Sep-08
#
# DESCRIPTION: creates a tunnel between 2 servers for Vnc

echo "USAGE: $0 [USER@]SERVER [PORT]"

LOCALHOST="127.0.0.1"
VNCVIEWER=vncviewer
# ssh arguments
ARG=" -X "
DPORT="5901" # default port

if [ x$2 != "x" ]; then
    echo "Connect using the command: $VNCVIEWER $LOCALHOST:$2"
else
    echo "Connect using the command: $VNCVIEWER $LOCALHOST:$DPORT"
fi

if [ x$2 != "x" ]; then
    ssh $ARG -L $2:$LOCALHOST:$2 "$1"
else
    ssh $ARG -L $DPORT:$LOCALHOST:$DPORT "$1"
fi



