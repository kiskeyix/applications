#!/bin/sh
# $Id: vnctunnel.sh,v 1.1 2003-01-31 09:25:42 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jan-31
#
# DESCRIPTION:
# USAGE: $0 SERVER [USER]
# CHANGELOG:
#

VNCVIEWER=vncviewer

echo "Connect using the command '$VNCVIEWER $1:5900' from a different terminal (at localhost)"

if [ $2 ]; then
    ssh -L 5900:localhost:5900 $2@$1
else
    ssh -L 5900:localhost:5900 $1
fi



