#!/bin/sh
######################################################################
# Last modified: 2003-Feb-05
# Luis Mondesi < lemsx1@hotmail.com >
# $Revision: 1.8 $
# 
# DESC: backup a site every night
#       Out of daily backups keep the 7th backup
#       for e/a week. At the end of the month
#       delete all previous backups for that month.
# USAGE: backup.sh
#
# This reads $HOME/.backuprc which is a file containing the following
# configurations:
#   
#   NAME="backupname"; # name of the file
#   BAK="/home/bak";
## List of files matching pattern to exclude
## these files sit inside one of the 
## directories being backup
#   EXCLUDES="--exclude=*.pid --exclude=*.soc \
#           --exclude=*.sock --exclude=*.log";
#
#   DIRS="/etc /var/lib /var/mail /var/spool ";
#
# TODO:
#       - take care of bugs
#
######################################################################

if [ -f $HOME/.backuprc ]; then
# source config file
    . $HOME/.backuprc
else 
    echo "no $HOME/.backuprc file found";
    exit 1;
fi


############# NO NEED TO MODIFY #################

TAR="tar $EXCLUDES -cjf ";  # j for bz2 ... do not modify this!!
WDAY=`date +%w`     # 0-6 day of the week
MDAY=`date +%d`     # 1-32 day of the month
FDATE=`date +%Y-%m-%d`     # iso format. full date. for informational purposes only
WEEK=`date +%U`     # week only 0-53

if [ -d $BAK ]; then
    cd $BAK;
else
    echo "$BAK is not a directory";
    exit 1;
fi

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
        if [ $WDAY != 0 ]; then
            WDAY=$(expr $WDAY - 1)
        else
            # sunday is 0 and 7, so
            # saturday is 6
            WDAY=6
        fi
       
        if [ $MDAY != 1 ]; then
            MDAY=$(expr $MDAY - 1)
        else
            # the fact that some months
            # don't have 31 days doesn't matter
            # for this script...
            # this is a known bug!
            MDAY=31
        fi
        
        if [ -f $NAME-nightly.tar.bz2 ]; then
            mv -f $NAME-nightly.tar.bz2 $NAME-$FDATE-$MDAY-$WEEK-$WDAY.tar.bz2
        fi
        $TAR $NAME-nightly.tar.bz2 $DIRS > /dev/null 2>&1;
fi
