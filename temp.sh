#!/bin/sh
# $Revision: 1.5 $
# 
# DESC: close program given by "list" if temperature
#       is higher than "limit"
      
# if temperature is higher than:
LIMIT=50

# start killing these programs (separate by spaces)
LIST="setiathome"
# commands separated by semi-colons
COMMANDS="/etc/init.d/utserver stop;"

# 
# command to cleanup the temperature
# it gets the CPU line out of the output
# of "sensors" and then cleans it up
# -m ("max line matches") ... only works for grep 2.5.x
# -i ("insensitive")
#
TEMP=`sensors | grep -i "CPU temp" | cut -d" " -f4 | sed "s/\..*//g" | sed "s/[\+\.cC]//g"`

# this is the real deal
if [ $TEMP -gt $LIMIT ]; then
    echo "Temp is too high $TEMP"
    for i in $LIST; do
        echo "killing $i"
        killall $i
        sleep 3
    done

    echo "Executing $COMMANDS"
    $COMMANDS
#else
#    echo "Ditto. Temp is fine: $TEMP"
fi
