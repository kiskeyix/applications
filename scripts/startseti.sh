#!/bin/bash
NICE=10
SLEEP=14400 # 4 hours
SETI="$HOME/Develop/seti"
cd $SETI || exit 1
while true; do
    nohup ./setiathome -nice $NICE > /dev/null 2>&1
    sleep $SLEEP
done

