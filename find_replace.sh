#!/bin/sh
# Luis Mondesi < lemsx1@hotmail.com >
# DESCRIPTION:
#   it uses vim to replace a given string for 
#   another in a  number of files
#
# usage:
#   find_replace.sh file "string" "replace"
#
if [ $1 -a $2 -a $3 ]; then
    for i in `find . -name "$1" -type f | xargs grep -l $2`; do
        # how do search and replace
        # the screen might flicker... vim opening and closing...
        vim -c ":%s/$2/$3/g" -c ":wq" $i
    done
    exit 0
fi
# I should never reach here
echo -e "USAGE: find_replace.sh file 'string' 'replace' \n\n"
exit 1
