#!/bin/sh
#
# DESCRIPTION: a simple program to show a holiday for e/a month
# BUG: 
#  - program assumes that user will input month names in english or their number
#  - program assumes that the months names are in lower case

get_holiday()
{
    case $1 in
        1|jan*)
            echo "New Years"
            ;;
        2|feb*)
            echo "Valentine's day"
            ;;
        3|mar*)
            echo "Saint Patrick's day"
            ;;
        4|apr*)
            echo "April fools"
            ;;
        5|may*)
            echo "Mother's day"
            ;;
        6|jun*)
            echo "Father's day"
            ;;
        7|jul*)
            echo "Independence day"
            ;;
        8|aug*)
            echo "No holidays"
            ;;
        9|sep*)
            echo "Labor day"
            ;;
        10|oct*)
            echo "Columbus day"
            ;;
        11|nov*)
            echo "Veteran's day"
            ;;
        12|dec*)
            echo "Christmas day"
            ;;
        # catch all
        *)
            echo "No holidays. Not a valid month"
            ;;
    esac
}

echo "Enter the name of a month (lowercase) or its number: "
read MONTH
if [ "x$MONTH" != "x" ]; then
    get_holiday $MONTH
else
    echo "Please enter a month of the year like: january"
fi
