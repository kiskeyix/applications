#!/bin/sh
# $Id: vnctunnel.sh,v 1.5 2003-09-10 05:21:53 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Sep-10
#
# DESCRIPTION:

echo "USAGE: $0 SERVER [USER] [PORT]"

VNCVIEWER=vncviewer
# ssh arguments
ARG=" -X "

if [ x$3 != "x" ]; then
    #  -a $3 -ge 5900
    echo "Connect using the command '$VNCVIEWER localhost:$3'"
else
    echo "Connect using the command '$VNCVIEWER localhost:5900'"
fi

if [ x$2 != "x" -a  x$3 == "x" ]; then
    ssh $ARG -L 5900:localhost:5900 $2@$1
elif [ x$3 != "x" ]; then
    ssh $ARG -L $3:localhost:$3 $2@$1
else
    ssh $ARG -L 5900:localhost:5900 $1
fi



