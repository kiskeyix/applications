#!/bin/sh
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com
#
# Prints tcp and udp connections that are listening
# similar to "netstat -l"
netstat -na | egrep -i "(tcp|udp)"
