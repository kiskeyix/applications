#!/bin/bash
# Luis Mondesi < lemsx1@hotmail.com >
# This script half-syncs a folder with a remote one
# meaning that if certain files are not in the local directory
# those files will be deleted from the remote directory
# if directory $1 doesn't exist in remote server,
# it will be created, unless $3 (argument 3) is passed
# in which case this directory will be the one being half-sync'ed
# ;-)
# Usage is: halfSync.sh DIR IP (or SERVER.COM) [DIR2]

# some globals:
RUSER='luigi'; # set this to remote user
ARG='-Pauvz --bwlimit=9 --delete --partial';  # Progress, all, update, verbose, compress(?), delete remote files that are not in local directory. bandwidth limit, continue partial files

#Local Var
USAGE="Usage: halfSync.sh DIR IP [DIR2]";

if [ -d $1 ]; then
    LOCALPATH="$1";
else
        echo "$USAGE";
        exit 0;
fi

if [ $3 ]; then
    REMOTEPATH=$3;
else
    REMOTEPATH=$1;
fi

if [ $2 ]; then
    rsync -e ssh $ARG --exclude=.* $LOCALPATH/ $RUSER@$2:$REMOTEPATH ;
else
    echo "$USAGE";
fi

