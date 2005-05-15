#!/bin/sh
#
# DESCRIPTION: a simple program to count up or down to a given number
# BUGS:
#   - the program assumes the user will input a number
#   - the program assumes the user will input "up" "down" or "quit" when prompted for 
#     what to do with the number

INPUT=""
COUNTER=0

count_number()
{
    if [ $2 = "up" ];then 
        while true; do
            if [ $1 != $COUNTER ]; then
                COUNTER=$(($COUNTER+1))
                echo $COUNTER
            elif [ $1 -eq $COUNTER ]; then
                exit
            fi
        done
    else
        COUNTER=$INPUT
        while true; do
            if [ $COUNTER -gt 0 ]; then
                COUNTER=$(($COUNTER-1)) 
                echo $COUNTER
            elif [ $COUNTER -eq 0 ]; then
                exit
            fi
        done
    fi
}

while true; do
    echo "Please enter a number"
    read INPUT
    if [ "x$INPUT" = "x" -o $INPUT -lt 0  ]; then
        break
    fi
    echo "How do you want to count to that number [up|down|quit]"
    read INPUT2
    case $INPUT2 in
        q*)
            exit
            ;;
        u*)
            echo 0
            count_number $INPUT "up"
            ;;
        d*)
            COUNTER=$INPUT
            echo $COUNTER
            count_number $INPUT "down"
            ;;
    esac
done
