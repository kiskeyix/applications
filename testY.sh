#!/bin/bash
#some systems don't support -x
if [ -f '/sbin/ping' ]
then
	/sbin/ping -s 1 -i 30 yahoo.com
else
	ping -s 1 -i 30 yahoo.com
fi
