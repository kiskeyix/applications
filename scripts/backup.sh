#!/bin/sh
# Last modified: 2002-Jul-30
# Luis Mondesi < lemsx1@hotmail.com >
# backup a site every night
# 
# Keep the 7th backup

NAME="mri-nyc"; # name of the file
BAK="/var/www/mri-backup";
# List of files matching pattern to exclude
# these files sit inside one of the 
# directories being backup
EXCLUDES="--exclude=*.soc --exclude=*.sock --exclude=mri-backup";  

DIRS="/etc /var/www /var/lib/mysql /var/ftp /var/mail /var/spool /usr/local/lib/webstats /var/lib/tripwire /home";


######## NO NEED TO MODIFY #################

TAR="tar $EXCLUDES -cjvf ";  # j for bz2 ... do not modify this!!
DAY=`date +%w` # 0-6
FDATE=`date -I` # iso format
WEEK=`date +%U` # week only 0-53

cd $BAK;

if [ -f 4 ]; then
    # this is the fourth week of the month
    # time to reset
    rm -f 4
    touch 1
    # delete all files and keep only the nightly backup
    rm -f $NAME*[0-6].tar.bz2
fi

# k, I don't want to do a while look to find up to
# what week number we are... (lazy?) we only have
# 4 weeks, so...
if [ $DAY -eq 6 ]; then
        #increase week number by one
        # lazy code:
        if [ -f 1 ]; then
            rm -f 1
            touch 2
        fi
        if [ -f 2 ]; then
            rm -f 2
            touch 3
        fi
        if [ -f 3 ]; then
            rm -f 3
            touch 4
        fi
        # that was not that painful... no while loop needed! :-)
        rm -f $NAME-$FDATE-$WEEK-[0-5].tar.bz2;
        $TAR $NAME-$FDATE-$WEEK-$DAY.tar.bz2 $DIRS 2>&1 > /dev/null;
fi

# in every other case do:
if [ $DAY -ne 6 ]; then
        # now move the nightly backup to yesterday week/day pair
        # and then do a new nightly for today
        # 
        DAY=$(($DAY-1))
        mv -f $NAME-nightly.tar.bz2 $NAME-$FDATE-$WEEK-$DAY.tar.bz2
        $TAR $NAME-nightly.tar.bz2 $DIRS 2>&1 > /dev/null;
fi
