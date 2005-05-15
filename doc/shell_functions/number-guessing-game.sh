#!/bin/sh
#
# DESCRIPTION: a number guessing game that allows the computer to pick a number and the user to try to guess this number

COUNTER=0
GUESS=`date +%S`

while true; do
    echo "Enter your guess"
    read NUM
    if [ $NUM -eq $GUESS ]; then
        echo "You are a genius number was $NUM"
        echo "Number of tries: $COUNTER"
        exit
    elif [ $NUM -lt $GUESS ]; then
        echo "The number you chose is lower"
    elif [ $NUM -gt $GUESS ]; then
        echo "The number you chose is higher"
    fi
    COUNTER=$(($COUNTER+1))
done
