#!/bin/sh
# $Id: vnctunnel.sh,v 1.3 2003-08-24 02:53:07 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Aug-18
#
# DESCRIPTION:

echo "USAGE: $0 SERVER [USER] [PORT]"

VNCVIEWER=vncviewer
# ssh arguments
ARG=" -X "

if [ $3 -ge 5900 ]; then
    echo "Connect using the command '$VNCVIEWER localhost:$3'"
else
    echo "Connect using the command '$VNCVIEWER localhost:5900'"
fi

if [ $2 -a ! $3 ]; then
    ssh $ARG -L 5900:localhost:5900 $2@$1
elif [ $3 -ge 5900 ]; then
    ssh $ARG -L $3:localhost:$3 $2@$1
else
    ssh $ARG -L 5900:localhost:5900 $1
fi



