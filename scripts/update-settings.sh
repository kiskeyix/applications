#!/bin/bash
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Sep-28
#
# DESCRIPTION: A simple script to update my settings in $HOME
# USAGE: $0 [remove|verbose]
#
# If remove is passed, the FILES will be deleted after downloading them
#
PATH=/bin:/usr/bin:/usr/local/bin

WGET="`command -v wget`"

URL="http://lems1.latinomixed.com"
FILES="bashrc.tar.bz2 vimrc.tar.bz2 muttrc.tar.bz2 bin.tar.bz2"
VERBOSE=""
WGET_ARGS="-c"
REMOVE_FILES=0

if [[ $1 = "verbose" || $2 = "verbose" ]]; then
    VERBOSE="v"
else
    WGET_ARGS="-nv ${WGET_ARGS}"
fi
if [[ $1 = "remove" || $2 = "remove" ]]; then
    REMOVE_FILES=1
fi
for i in $FILES; do
    if [[ ! -d "$TMP" ]]; then
        TMP="/tmp"
        export TMP
    fi
    cd "$TMP"
    $WGET ${WGET_ARGS} "$URL/$i";
    if [[ $? -eq 0 ]]; then
        echo "Setting $i"
        cd $HOME
        command tar x${VERBOSE}jf "$TMP/$i"
        if [[ $REMOVE_FILES -eq 1 ]]; then
            command rm -f "$TMP/$i"
        fi
    else
        echo "Error getting $i"
    fi
done
