#!/bin/sh
# $Id: vnctunnel.sh,v 1.2 2003-03-26 01:54:12 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Mar-25
#
# DESCRIPTION:
# USAGE: $0 SERVER [USER]
# CHANGELOG:
#

VNCVIEWER=vncviewer

echo "Connect using the command '$VNCVIEWER localhost:5900'"

if [ $2 ]; then
    ssh -L 5900:localhost:5900 $2@$1
else
    ssh -L 5900:localhost:5900 $1
fi



