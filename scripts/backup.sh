#!/bin/sh
##################################################################
# Last modified: 2003-Mar-11
# Luis Mondesi < lemsx1@hotmail.com >
# $Revision: 1.9 $
# 
# DESC: run in a cron job to 
#       backup a site every night.
#       and another cron job for weekly or monthly
#       backups
#
# USAGE: backup.sh nightly
#        backup.sh weekly
#        backup.sh monthly
#
#       This reads $HOME/.backuprc which is a file containing 
#       the following
#       configurations:
#   
#       NAME="backupname"; # name of the file
#       BAK="/home/bak";
#       EXCLUDES="--exclude=*.pid --exclude=*.soc \
#           --exclude=*.sock --exclude=*.log";
#
#       DIRS="/etc /var/lib /var/mail /var/spool ";
#
#################################################################

if [ -f $HOME/.backuprc ]; then
# source config file
    . $HOME/.backuprc
else 
    echo "no $HOME/.backuprc file found";
    exit 1;
fi


############# NO NEED TO MODIFY #################

TAR="tar $EXCLUDES -cjf ";  # j for bz2 ... do not modify this!!
MDATE=`date +%m`;
FDATE=`date +%Y-%m-%d`;      # iso 8601 format. full date. 

if [ -d $BAK ]; then
    cd $BAK;
else
    echo "$BAK is not a directory";
    exit 1;
fi

case "$1" in
    'nightly')
        $TAR $NAME-nightly.tar.bz2 $DIRS > /dev/null 2>&1;
    ;;
    
    'weekly')
        $TAR $NAME-$FDATE.tar.bz2 $DIRS > /dev/null 2>&1;
    ;;
    
    'monthly')
        # delete all files for this month
        rm -f $NAME-*-$MDATE-*.tar.bz2;
        # call yourself with nightly argument
        $0 nightly;
    ;;
    
    *)
        echo "Usage: $0 nightly|weekly|monthly"
        exit 1
    ;;
esac
