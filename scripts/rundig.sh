#!/bin/sh

# rundig.sh
# a script to drive ht://Dig updates
# Copyright (c) 1998 Colin Viebrock <cmv@shmooze.net>
# Copyright (c) 1998-1999 Geoff Hutchison <ghutchis@wso.williams.edu>
#
# Modified for Mandrake by Luis Mondesi < lemsx1@hotmail.com >
# 2002-08-09 12:03
# Last modified: 2002-Aug-12
#
# ht://Dig version 3.2.0

if [ "$1" = "-v" ]; then
    verbose="-v"
fi

# This is the directory where htdig lives
BASEDIR=/usr/

# This is the db dir
DBDIR=/var/lib/htdig/

# This is the name of a temporary report file
REPORT=/tmp/htdig.report

# This is who gets the report
REPORT_DEST="root@localhost"
export REPORT_DEST

# This is the subject line of the report
SUBJECT="cron: htdig report for localhost"

# This is the name of the conf file to use
CONF=/etc/htdig/htdig.conf

# This is the directory htdig will use for temporary sort files
TMPDIR=/tmp
export TMPDIR

# This is the PATH used by this script. Change it if you have problems
#  with not finding wc or grep.
PATH=/usr/local/bin:/usr/bin:/bin

##### Dig phase
STARTTIME=`date`
echo Start time: $STARTTIME
echo rundig: Start time:   $STARTTIME > $REPORT
$BASEDIR/bin/htdig $verbose -s -a -c $CONF >> $REPORT
TIME=`date`
echo Done Digging: $TIME
echo rundig: Done Digging: $TIME >> $REPORT

##### Merge Phase
$BASEDIR/bin/htmerge $verbose -s -a -c $CONF >> $REPORT
TIME=`date`
echo Done Merging: $TIME
echo rundig: Done Merging: $TIME >> $REPORT

##### Cleanup Phase
# To enable htnotify or the soundex search, uncomment the following lines
 $BASEDIR/bin/htnotify $verbose >>$REPORT
 $BASEDIR/bin/htfuzzy $verbose soundex

# Move 'em into place. Since we only need db.wordlist to do update digs
# and we always use -a, we just leave it as .work
# mv $BASEDIR/db/db.wordlist.work $BASEDIR/db/db.wordlist
# We need the .work for next time as an update dig, plus the copy for searching
cp $DBDIR/db.docdb.work $DBDIR/db.docdb
# These are generated from htmerge, so we don't want copies of them.
mv $DBDIR/db.docs.index.work $DBDIR/db.docs.index
mv $DBDIR/db.words.db.work $DBDIR/db.words.db
# mandrake's dig 3.2.x
#
mv $DBDIR/db.excerpts.work $DBDIR/db.excerpts
mv $DBDIR/db.words.db.work_weakcmpr $DBDIR/db.words.db_weakcmpr

END=`date`
echo End time: $END
echo rundig: End time:     $END >> $REPORT
echo 

# Grab the important statistics from the report file
# All lines begin with htdig: or htmerge:
fgrep "htdig:" $REPORT  
echo 
fgrep "htmerge:" $REPORT
echo
fgrep "rundig:" $REPORT
echo

WC=`wc -l $REPORT`
echo Total lines in $REPORT: $WC

# Send out the report ...
mail -s "$SUBJECT - $STARTTIME" $REPORT_DEST < $REPORT

# ... and clean up
rm $REPORT
