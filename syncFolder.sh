#!/bin/bash

#lems1
#modified  
#pass extra arg to rsync, eg: v 
#archive, verbose, update (don't override newer files),compress (z)
# --delete (deletes files in receiver that are not in the sender)
# --force forces deletion
# --exclude=PATTERN (eg *.o) excludes files 
# -P partial progress
# -u, --update updated files only (do not override newer files) NOTE:
# since update is so important, I made it an invariant, not an argument
#

ARG='-Pavz'
#remote user
RUSER='luigi'
#local dir where stuff will be saved
if [ -d $1 ] 
then
	LOCALPATH="$1";
else
	echo "Directory must exist locally: usage: syncFolder DIR IP [REMOTEPATH]";
	exit 0;
fi	
#remote ip or domain name
if [ "$2" ] #command line argument was passed and not NULL?
then
	REMOTEIP="$2";
else
	echo "You must specify an ip address or domain: usage: syncFolder DIR IP [REMOTEPATH]";
	exit 0;
fi

if [ "$3" ]
then
	REMOTEPATH="$3";
else
	REMOTEPATH=$LOCALPATH;
fi
#assume local is the latest and send that first
#do not upload any dot file
rsync -e ssh $ARG --update --exclude=.* $LOCALPATH/ $RUSER@$REMOTEIP:$REMOTEPATH;
#now get whatever server has
rsync -e ssh $ARG --update --exclude=.* $RUSER@$REMOTEIP:$REMOTEPATH/ $LOCALPATH;

