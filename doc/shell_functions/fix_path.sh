#!/bin/sh

SED="/bin/sed"
LS_FILES=`/bin/ls *.m3u`
#PWD=`pwd`

for i in $LS_FILES; do
    #BASENAME=`basename $i`
    # foreach file $i open it and look in every line for this string
    # and replace it with ".." the output of which will be written
    # to .$i.tmp
    $SED "s@^/\+home/Shared/pub/multimedia/Music@..@"  "$i" > ".$i.tmp"
    # rename .$i.tmp back to $i
    mv -f ".$i.tmp" "$i"
done

