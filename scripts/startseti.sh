#!/bin/sh
# Luis Mondesi <lemsx1@hotmail.com> 
# USAGE: startseti.sh [start|stop|constop] &
#   start       - starts seti if LOAD is less than 5
#   stop        - stops seti unconditionally
#   condstop    - stops seti if LOAD is greater than 5
#
# TIPS: 
# make sure that you kill all startseti.sh processes before
# starting this script. That way you won't have multiple versions 
# running, taking up valuable memory and resources!
# 
# Usually is better to start from a cron job like the following:
# # m h dom mon dow user    command
# 00 03 * * 1-5 ~/bin/startseti.sh start &
# 00 08 * * *   ~/bin/startseti.sh condstop
#
# This will start seti everyday from monday through friday at 3am
# and kill it at 8am but leave it running through the weekend 
# (saturday & sunday).
# Note that "ps ax" is not fool proof as it will detect anything that
# has "startseti" in it :-) that includes processes like: vim startseti.
# Which obviously might have nothing to do with this ;-)
#

# We allow our path to include the current directory
PATH=/usr/bin:/bin:.
NICE=10
SLEEP=14400 # 4 hours
SETI="$HOME/Develop/seti"
PIDF="$SETI/.startseti.pid" # process id file
PROCESS="setiathome" # name of the seti binary
PKILL="pkill" # pkill is smart about process names

######################################################################
#                           END CONFIG                               #
######################################################################

CPID=$$ # current process id is saved

cd $SETI || exit 1

# set LOAD to 0 if you want to disable this check
LOAD=$(uptime|sed -e "s/.*: \([^,]*\).*/\1/" -e "s/ //g" -e "s/^\([0-9]\+\)\..*/\1/" )

# are we stopping?
if [ $LOAD -gt 5 -a x$1 = "xcondstop" -o x$1 = "xstop" ]; then
    echo -n "Stopping $PROCESS "
    # cleanup startseti.sh processes if any...
    $PKILL $PROCESS && \
    echo "[ok]" && \
    kill `cat $PIDF` && \
    rm -f $PIDF && \
    exit 0
    # else echo failed and exit 1
    echo "[failed]" && exit 1
elif [ x$1 = "xcondstop" ]; then
    # load is not high enough, exit
    exit 0
fi

# are we starting?
# exit 1 if not "start" & $PIDF exists
# otherwise create PID file & save our process id 
if [ x$1 = "xstart" -a ! -f $PIDF ]; then
    echo $CPID > $PIDF 
else
    echo "$PIDF exists. We can't start seti until you remove this file"
    exit 1
fi
if [ $LOAD -lt 5 -a x$1 = "xstart" ]; then
        echo "Starting seti [ok]" # assume seti will work...
    while true; do
        # seti is smart enough to know if it's already running
        nohup ./$PROCESS -nice $NICE > /dev/null 2>&1 &
        sleep $SLEEP
    done
fi

