#!/bin/sh
if [ -d $1 -a -d $2 ]
	mount -t iso9660 -o ro,loop $1 $2
fi

