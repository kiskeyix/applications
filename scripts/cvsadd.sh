#!/bin/bash
# Luis Mondesi <lemsx1@hotmail.com>
# Use this to add a file or series of files to
# CVS in one shot!
# Usage: cvsadd.sh filename

if [ -f $1 ]; then
    for file in $*; do
        echo "Adding ${file} to current CVS tree";
        cvs add ${file};
        cvs commit -m "first commit" ${file};
    done
else 
    echo "Usage: cvsadd.sh filename [filename2]";
fi
