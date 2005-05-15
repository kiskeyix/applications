#!/bin/sh
#
# DESCRIPTION: keeps track of number of numbers inputted by user and when 999 is input, exits and displays stat of how many numbers were typed
# BUGS:
#  - program assumes the user will input valid numbers

INPUT=""
INPUT_HIGH=0
INPUT_LOW=0
INPUT_NUM=0
INPUT_AVG=0
INPUT_SUM=0

FLAG=0 # keeps track of the first time the user input a number

while true; do
    echo "Please enter number (999 to exit): "
    read INPUT
    if [ $INPUT -eq 999 ]; then
        echo "Highest Number: $INPUT_HIGH"
        echo "Lowest Number: $INPUT_LOW"
        echo "Sum of the numbers: $INPUT_SUM"
        echo "Average of the numbers: $INPUT_AVG"
        exit
    fi
    if [ $FLAG -eq 0 ];then
        INPUT_HIGH=$INPUT
        INPUT_LOW=$INPUT
        FLAG=1
    fi
    if [ $INPUT -lt $INPUT_LOW ];then
        INPUT_LOW=$INPUT
    fi
    if [ $INPUT -gt $INPUT_HIGH ]; then
        INPUT_HIGH=$INPUT
    fi
    INPUT_NUM=$(($INPUT_NUM+1))
    INPUT_SUM=$(($INPUT_SUM+$INPUT))
    INPUT_AVG=$(($INPUT_SUM/$INPUT_NUM))
done
