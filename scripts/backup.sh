#!/bin/sh
# Last modified: 2002-Oct-16
# Luis Mondesi < lemsx1@hotmail.com >
# backup a site every night
# 
# Out of daily backups keep the 7th backup
# for e/a week. At the end of the month
# delete all previous backups for that month.

NAME="latinomixed"; # name of the file
BAK="/home/bak";
# List of files matching pattern to exclude
# these files sit inside one of the 
# directories being backup
EXCLUDES="--exclude=*.pid --exclude=*.soc --exclude=*.sock --exclude=*.log";

DIRS="/etc /usr/var/www/html/latinomixed.com /usr/var/www/html/accplusli.com /usr/var/www/cvs /var/lib/jabber /var/lib/mysql /var/mail /var/spool /usr/local/lib/webstats /var/lib/ldap ";

######## NO NEED TO MODIFY #################

TAR="tar $EXCLUDES -cjf ";  # j for bz2 ... do not modify this!!
WDAY=`date +%w`     # 0-6 day of the week
MDAY=`date +%d`     # 1-32 day of the month
FDATE=`date -I`     # iso format. full date. for informational purposes only
WEEK=`date +%U`     # week only 0-53

cd $BAK;

# k, I don't want to do a while loop to find up to
# what week number we are... (lazy?) we only have
# 4 weeks, so...
if [ $WDAY -eq 6 ]; then
        # on the sixth day, remove from Sun to Fri files
        rm -f $NAME*$WEEK-[0-5].tar.bz2;
        # then create one for the 6th
        $TAR $NAME-$FDATE-$MDAY-$WEEK-$WDAY.tar.bz2 $DIRS  > /dev/null 2>&1;
fi

# if Saturday happens to be 30th or 31th, then we will be double working
# ... will deal with this somehow later...
if [ $MDAY -eq 30 -o $MDAY -eq 31 ]; then
    # keep only the nightly
    rm -f $NAME*[0-31]*6*
fi

# in every other case do:
if [ $WDAY -ne 6 ]; then
        # now move the nightly backup to yesterday week/day pair
        # and then do a new nightly for today
        # 
        WDAY=$(expr $WDAY - 1)
        MDAY=$(expr $MDAY - 1)
        
        if [ -f $NAME-nightly.tar.bz2 ]; then
            mv -f $NAME-nightly.tar.bz2 $NAME-$FDATE-$MDAY-$WEEK-$WDAY.tar.bz2
        fi
        $TAR $NAME-nightly.tar.bz2 $DIRS > /dev/null 2>&1;
fi
