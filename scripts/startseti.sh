#!/bin/sh
# Luis Mondesi <lemsx1@hotmail.com> 
# DESCRIPTION:
# An advanced setiathome startup script that takes care of:
#   - ensuring that one copy of this script is running
#   - run setiathome in a tight loop that gives time for
#     seti to cleanup after itself
#   - conditionally stop setiathome if the load of the system is high
#   - automatically detect if old copies of this script had been
#     improperly killed and attempt to cleanup and start a new script
#   - all options are configurable in a startsetirc shell source
#     in which you can put the variables below with different values
# 
# BUGS:
#   - assumes that a given user will run only one setiathome process.
#     this can easily be modified, but it's usually the case.
#
# USAGE: startseti.sh [start|stop|constop] &
#   start       - starts seti if LOAD is less than 5
#   stop        - stops seti unconditionally
#   condstop    - stops seti if LOAD is greater than 5
#
# TIPS: 
# Usually is better to start from a cron job like the following:
# # minute hour dayofmonth month dayofweek user    command
# 00 03 * * 1-5 ~/bin/startseti.sh start &
# 00 08 * * *   ~/bin/startseti.sh condstop
#
# This will start seti everyday from monday through friday at 3am
# and kill it at 8am but leave it running through the weekend 
# (saturday & sunday).
#
# Note that "ps ax" is not fool proof as it will detect anything that
# has "startseti" in it :-) that includes processes like: vim startseti.
# Which obviously might have nothing to do with this ;-) This is why
# this script uses /bin/pidof (usually part of killall5) to detect 
# process ids and pkill to kill processes by automatically determining
# their process ids.
#
# TODO:
#   - determine if the temperature of the CPU/motherboard is too high

# =========================== BEGIN ================================= #
# We allow our path to include the current directory
PATH=/usr/bin:/bin:.
# these settings can be modified on a per computer basis. just
# copy them to a file named "startsetirc" inside your $SETI directory
NICE=19
# work load average at which point we would stop seti momentarily
MAXLOAD=5 
SLEEP=3 #4400 # 4 hours
SETI="$HOME/Develop/seti"
PIDF="$SETI/.startseti.pid" # process id file
PROCESS="setiathome" # name of the seti binary
PKILL="/usr/bin/pkill -U $UID" # pkill is smart about process names and -U for the processes run by a given user
CAT="/bin/cat"          # std unix command
PIDOF="/bin/pidof"      # returns process id of "process_name":
                        # i.e: pidof vim. yields PID number of vim processes
                        # and pidof -x startseti.sh yields the process
                        # of this script.

######################################################################
#                           END CONFIG                               #
######################################################################

CPID=$$ # current process id is saved
EXIT=1 # always assume we will need to exit, unless we are doing condstop

#
# Functions
#

# trap some signals:
# our exit function removes the .pid file
function _exit()        # function to run upon exit of shell
{
    # we exit when EXIT is not doing condstop and LOAD is not gt MAXLOAD
    if [ $EXIT -ne 0 ]; then
        rm -f $PIDF # removes PID file of this script
        $PKILL $PROCESS # kill all seti processes by me
        echo "Hasta la vista seti" 
        # reenable signals
        trap EXIT HUP TERM INT
        exit 0
    fi
}
# hint: trap -l (displays signals)
# SIGTERM (15) is sent to us from init when rebooting
trap _exit EXIT HUP TERM INT

function killold ()
{
    echo "Called killold"
    SUCCESS=0 # assume we will fail
    MPID=$($PIDOF -x $0)
    for i in $MPID; do
        if [ x`$CAT $PIDF` = x$i -a x$CPID != x$i ]; then
            # kill startseti.sh old PID
            echo "Killing $0 number $i"
            kill -9 `$CAT $PIDF` &&\
            rm -f $PIDF &&\
            SUCCESS=1
        elif [ x$CPID != x$i ]; then
            echo "Murdering $0 number $i"
            kill -9 $i &&\
            SUCCESS=1
        else
            echo "Not killing $i [We are $CPID]"
        fi
    done
    if [ $SUCCESS ]; then
        return 0
    else
        return 1
    fi
}

cd $SETI || exit 1
[ -f startsetirc ] && . startsetirc # load defaults for this system

#echo "Started Seti: `date`" > startseti.log

# set LOAD to 0 if you want to disable this check
LOAD=$(uptime|sed -e "s/.*: \([^,]*\).*/\1/" -e "s/ //g" -e "s/^\([0-9]\+\)\..*/\1/" )

# are we stopping? 
# LOAD > MAXLOAD and condstop are set, we stop OR stop was passed to us
if [ $LOAD -gt $MAXLOAD -a x$1 = "xcondstop" -o x$1 = "xstop" ]; then
    echo -n "Stopping $PROCESS " 
    # cleanup startseti.sh processes if any...
    $PKILL $PROCESS && \
        echo "[ok]"
    killold && exit 0
    # else echo failed and exit 1
    echo "[failed]" && exit 1
elif [ x$1 = "xcondstop" ]; then
    # load is not high enough, exit
    EXIT=0 # do not exit
    exit 0
fi

# Assuming a *stop argument won't passed previous checks...
# then:
# are we starting?
# if yes, create pid file
# else
# try to guess if startseti.sh that is running is old
if [ x$1 = "xstart" -a ! -f $PIDF ]; then
    echo $CPID > $PIDF 
else
    RUNNING=0 # assume startseti.sh ($0) is not running
    MPID=$($PIDOF -x $0)
    for i in $MPID; do
        if [ x`$CAT $PIDF` = x$i ]; then
            echo "$0 is already running"
            RUNNING=1
        fi
    done
    if [ $RUNNING -eq 0 -a $LOAD -lt 5 ]; then
        # $0 is not running, so, we update the PID file
        # and try to launch a new $PROCESS later
        echo $CPID > $PIDF
    else
        EXIT=0
        exit 0
    fi
fi

if [ $LOAD -lt 5 -a x$1 = "xstart" ]; then
    echo "Starting seti [ok]" # assume seti will work...
    while true; do
        # seti is smart enough to know if it's already running
        nohup ./$PROCESS -nice $NICE > /dev/null 2>&1 &
        sleep $SLEEP
    done
fi

