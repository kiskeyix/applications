#!/bin/sh
# convert-int-to-text
# interactive program to convert a number to its text representation
# Known bugs: 
#   * the program assumes user will input numbers for e/a
#      operation

MIN=0
MAX=30

usage()
{
	echo "Please enter a valid number between $MIN and $MAX to convert to text"
}

get_tenth()
{
    case $1 in
        10)
            echo "ten"
            ;;
        11)
            echo "eleven"
            ;;
        12)
            echo "twelve"
            ;;
        13)
            echo "thirteen"
            ;;
        14)
            echo "fourteen"
            ;;
        15)
            echo "fifteen"
            ;;
        16)
            echo "sixteen"
            ;;
        17)
            echo "seventeen"
            ;;
        18)
            echo "eighteen"
            ;;
        19)
            echo "nineteen"
            ;;
        20)
            echo "twenty"
            ;;
        2?)
            echo "twenty-"
            ;;
        30)
            echo "thirty"
            ;;
        3?)
            echo "thirty-"
            ;;
        40)
            echo "forty"
            ;;
        4?)
            echo "forty-"
            ;;
        50)
            echo "fifty"
            ;;
        5?)
            echo "fifty-"
            ;;
        60)
            echo "sixty"
            ;;
        6?)
            echo "sixty-"
            ;;
        70)
            echo "seventy"
            ;;
        7?)
            echo "seventy-"
            ;;
        80)
            echo "eighty"
            ;;
        8?)
            echo "eighty-"
            ;;
        90)
            echo "ninety"
            ;;
        9?)
            echo "ninety-"
            ;;
    esac
}

get_oneth()
{
    case $1 in
        10)
            exit
            ;;
        11)
            exit
            ;;
        12)
            exit
            ;;
        13)
            exit
            ;;
        14)
            exit
            ;;
        15)
            exit
            ;;
        16)
            exit
            ;;
        17)
            exit
            ;;
        18)
            exit
            ;;
        19)
            exit
            ;;
        0)
            echo "zero"
            ;;
        *1)
            echo "one"
            ;;
        *2)
            echo "two"
            ;;
        *3)
            echo "three"
            ;;
        *4)
            echo "four"
            ;;
        *5)
            echo "five"
            ;;
        *6)
            echo "six"
            ;;
        *7)
            echo "seven"
            ;;
        *8)
            echo "eight"
            ;;
        *9)
            echo "nine"
            ;;
    esac
}

echo "Enter a number [0-30]? "
read INPUT 
# sanity checks:
#  - we accept numbers between 1 and 99 only
#  - if user simply hits enter, we exit
#  TODO we should make sure what was entered was a number, but this will not work anyway
if [ $INPUT -lt 0 -o $INPUT -gt 30 -o "x$INPUT" = "x" ]; then
    usage
    exit 1
fi
if [ $INPUT -gt 9 ]; then
    TEXT="`get_tenth $INPUT`"
fi
# if the next number is 0, we should exit
TEXT="$TEXT`get_oneth $INPUT`"
echo $TEXT
