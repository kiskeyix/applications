#!/bin/sh
# $Revision: 1.1 $

# if temperature is higher than:
LIMIT=50

# start killing these programs (separate by spaces)
LIST="setiathome"

# command to cleanup the temperature
# it gets the CPU line out of the output
# of "sensors" and then cleans it up
TEMP=`sensors | grep CPU | cut -d" " -f4 | sed "s/\..*//g" | sed "s/[\+\.cC]//g"`

# this is the real deal
if [ $TEMP -gt $LIMIT ]; then
    echo "Temp is too high $TEMP"
    for i in $LIST; do
        echo "killing $i"
        killall $i
        sleep 3
    done
#else
    #echo "Ditto. Temp is fine: $TEMP"
fi
