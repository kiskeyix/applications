#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@gmail.com >
# Last modified: 2004-Nov-25
#
# DESCRIPTION: purges redhat services that are set to on by default
# USAGE: $0
# LICENSE: GPL

PURGE_SERVICES="isdn lm_sensors apmd mDNSResponder cups rhnsd pcmcia iptables"

for i in $PURGE_SERVICES; do
    if [ -x /sbin/chkconfig ]; then
        sudo /sbin/chkconfig --del $i
    fi
    if [ -x /sbin/service ]; then
        sudo /sbin/service $i stop
    fi
done
