#!/bin/bash
# Luis Mondesi <lemsx1@hotmail.com>
# Use this to add a file or series of files to
# CVS in one shot!
# Usage: cvsadd.sh filename [filename ...]
#
# Changelog:
# 2003-09-27 04:53 EDT made silent

if [ -f $1 ]; then
    for file in $*; do
        cvs add ${file} 2> /dev/null
        if [ $? == 0 ]; then
            cvs commit -m "first commit" ${file} 
        else
            echo "Error adding = ${file} = to the repository. Please add it by hand"

        fi

    done
else 
    echo "Usage: cvsadd.sh filename [filename2]"
fi
