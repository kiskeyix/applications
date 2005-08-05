#!/bin/bash
# Luis Mondesi <lemsx1@hotmail.com>
# Use this to add a file or series of files to
# CVS in one shot!
# Usage: cvsadd.sh filename [filename ...]
#
# Changelog:
# 2003-09-27 04:53 EDT made silent

if [ $# -gt 0 ]; then
    for file in $*; do
        if [ ! -f ${file} ]; then
            echo "Skipping non-file '$file'"
            continue
        fi
        cvs add ${file} 2> /dev/null
        if [ $? == 0 ]; then
            cvs commit -m "first commit" ${file} 
        else
            echo "Error adding = ${file} = to the repository. Please add it by hand"

        fi
    done
else 
    cvs update > /tmp/.cvsadd.list.txt
    if [ `grep M /tmp/.cvsadd.list.txt` ]; then
        echo "Please run 'cvs commit' first"
        exit
    fi

    read -p "Do you want to add new files to the repository? [y/N]" YESNO
    if [ $YESNO = "y" -o $YESNO = "Y" ]; then
        for i in $(< /tmp/.cvsadd.list.txt); do
            cvs add $i
        done
    fi
fi
