#!/bin/bash
# $Revision: 1.5 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2005-Jan-20
#
# DESCRIPTION: A simple script to update my settings in $HOME
# USAGE: $0 [remove] [verbose] [bashrc|vimrc|muttrc|applications]
#
# If remove is passed, the FILES will be deleted after downloading them
#
PATH=/bin:/usr/bin:/usr/local/bin

WGET="`command -v wget`"

URL="http://lems1.latinomixed.com"
FILES="bashrc.tar.bz2 vimrc.tar.bz2 muttrc.tar.bz2 Applications.tar.bz2"
VERBOSE=""
WGET_ARGS="--continue --timestamping"
REMOVE_FILES=0

if [[ $1 = "verbose" || $2 = "verbose" ]]; then
    VERBOSE="v"
else
    WGET_ARGS="-nv ${WGET_ARGS}"
fi
if [[ $1 = "remove" || $2 = "remove" ]]; then
    REMOVE_FILES=1
fi
if [[ ! -d "$TMP" ]]; then
    TMP="/tmp"
    export TMP
fi
for i in $FILES; do
    cd "$TMP"
    SKIP_FILE=1 # assume YES
    if [[ ! -f "$i" ]]; then
        $WGET ${WGET_ARGS} "$URL/$i"
        SKIP_FILE=$?
    else
        echo "Local file used for $i "
        SKIP_FILE=0
    fi
    if [[ $SKIP_FILE -eq 0 ]]; then
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
