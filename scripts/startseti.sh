#!/bin/sh
# Luis Mondesi <lemsx1@hotmail.com> 
# DESCRIPTION:
# An advanced setiathome startup script that takes care of:
#   - ensuring that one copy of this script is running
#   - run setiathome in a tight loop that gives time for
#     seti to cleanup after itself
#   - conditionally stop setiathome if the load of the system is higher
#     than the user defined MAXLOAD (defaults to 5)
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
#   start       - starts seti if LOAD is less than MAXLOAD
#   stop        - stops seti unconditionally
#   condstop    - stops seti if LOAD is greater or equal to MAXLOAD
#
# TIPS: 
# Usually is better to start from a cron job like the following:
# # minute hour dayofmonth month dayofweek user    command
# 00 */4 * * 1-5 ~/bin/startseti.sh start &
# */12 * * * *   ~/bin/startseti.sh condstop
# 
# This will start seti everyday 4 hours, if not already running,
# from monday through friday
# and kill it if the load is higher than 5 every 12 minutes,
# but leave it running through the weekend (saturday & sunday).
#
# You don't have to edit this script. You can simply copy the variables
# in a file called "startsetirc" inside your seti directory as suggested
# below.
#
# TODO:
#   - determine if the temperature of the CPU/motherboard is too high
#     using "sensors"

DEBUG=0 # set to anything other than zero to see debugging messages

# =========================== BEGIN ================================= #
# We allow our path to include the current directory
PATH=/usr/bin:/bin:.
# these settings can be modified on a per computer basis. just
# copy them to a file named "startsetirc" inside your $SETI directory
NICE=19
# work load average at which point we would stop seti momentarily
MAXLOAD=5
SLEEP=7200                      # 2 hours sleep
SETI="$HOME/Develop/boinc"
PIDF="$SETI/.startseti.pid"     # process id file
PROCESS="boinc"            # name of the seti binary
PKILL="/usr/bin/pkill -U $UID"  # pkill is smart about process names 
                                # and -U for the processes run by a 
                                # given user.
CAT="/bin/cat"                  
PIDOF="/bin/pidof"              # pidof returns process id 
                                # of "process_name". i.e:
                                #   pidof vim
                                # yields PID number of vim processes
                                # and:
                                #   pidof -x startseti.sh 
                                # yields the process ID of this script.

######################################################################
#                           END CONFIG                               #
######################################################################

CPID=$$ # current process id is saved
EXIT=1  # always assume we will need to exit, 
        # unless we are doing condstop

if [ ! $1 ]; then
    echo "Usage: $0 start|stop|condstop"
    exit 1
fi

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
        if [ $DEBUG -ne 0 ]; then
            echo "Hasta la vista seti"
        fi
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
    if [ $DEBUG -ne 0 ]; then
        echo "Called killold"
    fi
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
        elif [ $DEBUG -ne 0 ]; then
            echo "Not killing $i [because we are $CPID]"
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

# set LOAD to 0 if you want to disable this check
LOAD=$(uptime|sed -e "s/.*: \([^,]*\).*/\1/" -e "s/ //g" -e "s/^\([0-9]\+\)\..*/\1/" )

# are we stopping? 
# LOAD > MAXLOAD and condstop are set, we stop OR stop was passed to us
if [ $LOAD -ge $MAXLOAD -a x$1 = "xcondstop" ]; then
    # stop setiathome but leave startseti.sh running
    EXIT=0 # do not kill previous startseti.sh
    echo -n "Load is high stopping $PROCESS "
    $PKILL $PROCESS &&\
        echo "[ok]" &&\
        exit 0
    # else
    echo "[failed]" && exit 1
elif [ x$1 = "xstop" ]; then
    # completely stop seti and startseti.sh
    echo -n "Stopping $PROCESS " 
    # cleanup startseti.sh processes if any...
    $PKILL $PROCESS && \
        echo "[ok]"
    killold && exit 0
    # else echo failed and exit 1
    echo "[failed]" && exit 1
elif [ x$1 = "xcondstop" ]; then
    # load is not high enough, exit
    if [ $DEBUG -ne 0 ]; then
        echo "Load no high enough [$LOAD < $MAXLOAD]"
    fi
    EXIT=0 # do not kill previous startseti.sh
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
            if [ $DEBUG -ne 0 ]; then
                echo "$0 is already running"
            fi
            RUNNING=1
        fi
    done
    if [ $RUNNING -eq 0 -a $LOAD -lt $MAXLOAD ]; then
        # $0 is not running, so, we update the PID file
        # and try to launch a new $PROCESS later
        echo $CPID > $PIDF
    else
        EXIT=0
        exit 0
    fi
fi

echo -n "Starting seti "
if [ $LOAD -lt $MAXLOAD -a x$1 = "xstart" ]; then
    echo "[ok]" # assume seti will work...
    while true; do
        # seti is smart enough to know if it's already running
        nohup ./$PROCESS > /dev/null 2>&1 &
        # old setiathome: -nice $NICE
        sleep $SLEEP
    done
else
    # we should never reach here
    echo "[failed]"
    echo "Load $LOAD is not less than $MAXLOAD"
fi

