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
#   start       - starts seti if LOAD is less than MAXLOAD (optional)
#   stop        - stops seti unconditionally
#   condstop    - stops seti if LOAD is greater or equal to MAXLOAD
#
# TIPS: 
# Usually is better to start from a cron job like the following:
# # minute hour dayofmonth month dayofweek user    command
# 00 */4 * * 1-5 exec ~/bin/startseti.sh start &
# */12 * * * *   exec ~/bin/startseti.sh condstop
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

HOSTNAME="`hostname`"
EXIT=1 # assume we want to kill all $PROCESS automatically when we exit

if [ x$1 = "xhelp" -o x$1 = "x--help" -o x$1 = "x-help" -o x$1 = "x-?" ]; then
    echo "Usage: $0 [start|stop|condstop]"
    exit 1
fi

#
# Functions
#

## trap some signals:
## our exit function removes the .pid file
function _exit()        # function to run upon exit of shell
{
    if [ $EXIT -eq 1 ]; then
        $PKILL $PROCESS # kill all seti processes by me
        if [ $DEBUG -ne 0 ]; then
            echo "Hasta la vista seti $HOSTNAME"
        fi
    fi  
    # reenable signals
    trap EXIT HUP TERM INT
    exit 0
}
# hint: trap -l (displays signals)
# SIGTERM (15) is sent to us from init when rebooting
trap _exit EXIT HUP TERM INT

function killold ()
{
    if [ $DEBUG -ne 0 ]; then
        echo "" # yeah, echo -e "\nstr\n" but...
        echo "Called killold"
    fi
    SUCCESS=0 # assume we will fail
    OLD_PID=""
    if [ -f $PIDF ]; then
        OLD_PID=`$CAT $PIDF`
    fi
    MPID=$($PIDOF -x $0)
    for i in $MPID; do
        if [ x$OLD_PID = x$i ]; then
            # kill startseti.sh old PID
            if [ $DEBUG -ne 0 ]; then
                echo "Killing $0 with PID number $i at $HOSTNAME"
            fi
            kill -9 $i
            rm -f $PIDF
            SUCCESS=1
        elif [ x$CPID != x$i ]; then
            # cleanup lost children (whose PIDF don't exist)
            if [ $DEBUG -ne 0 ]; then
                echo "Murdering $0 number $i at $HOSTNAME"
            fi
            kill -9 $i
            SUCCESS=1
        elif [ $DEBUG -ne 0 ]; then
            # we don't kill ourselves! that would be suicide
            echo "Not killing $i [because we are $CPID]"
        fi
    done
    return $SUCCESS;
}

function is_running ()
{
    if [ $DEBUG -ne 0 ]; then
        echo -n "Checking if $0 is running "
    fi
    IS_RUNNING=0 # assume is not running
    OLD_PID=""
    if [ -f $PIDF ];then 
       OLD_PID=`$CAT $PIDF`
    fi
    # get all process id's for all running processes
    MPID=$($PIDOF -x $0)
    # determine if the process id is for an older process
    for i in $MPID; do
        if [ -f $PIDF -a x$OLD_PID = x$i ]; then
            if [ $DEBUG -ne 0 ]; then
                echo "$0 is already running at $HOSTNAME [$i]"
            fi
            IS_RUNNING=1
        fi
    done
    if [ $DEBUG -ne 0 ]; then
        echo "[$IS_RUNNING]"
    fi
    return $IS_RUNNING
}

cd $SETI || exit 1
[ -f startsetirc ] && . startsetirc # load defaults for this system

# set LOAD to 0 if you want to disable this check
LOAD=$(uptime|sed -e "s/.*: \([^,]*\).*/\1/" -e "s/ //g" -e "s/^\([0-9]\+\)\..*/\1/" )

# are we stopping? 
# LOAD > MAXLOAD and condstop are set, we stop OR stop was passed to us
if [ $LOAD -ge $MAXLOAD -a x$1 = "xcondstop" ]; then
    # stop setiathome but leave startseti.sh running
    echo -n "Load is high at $HOSTNAME. Stopping $PROCESS "
    $PKILL $PROCESS &&\
        echo "[ok]" &&\
        exit 0
    # else
    echo "[failed]" && exit 1
elif [ x$1 = "xstop" ]; then
    # completely stop seti and startseti.sh remove all pid files
    echo -n "Stopping $PROCESS at $HOSTNAME " 
    # kill seti_at_home process:
    $PKILL $PROCESS
    # cleanup old startseti.sh processes if any...
    killold 
    exit 0
elif [ x$1 = "xcondstop" ]; then
    # load is not high enough, exit
    EXIT=0 # but do not kill all PROCESSes when exiting...
    if [ $DEBUG -ne 0 ]; then
        echo "Load no high enough at $HOSTNAME [$LOAD < $MAXLOAD]"
    fi
    exit 0
fi

# Assuming a [cond]stop argument won't passed previous checks...
# then:
# are we starting? [start arg is optional]
# if yes, create pid file
# else
# try to guess if startseti.sh that is running is old
START=0
if [ ! is_running -o x$1 = "xstart" -o x$1 = "x"  -o x$1 = "xlog" ]; then
    echo $CPID > $PIDF 
    START=1
else
    echo "We are not running?"
fi

# this is indeed redundant at this point... but, just to make sure:
# - tests whether pid file exist
if [ is_running ]; then
    echo -n "Starting seti at $HOSTNAME "
    if [ $LOAD -lt $MAXLOAD -a $START ]; then
        echo "[ok]" # seti is a loooong process. assume seti will work...
        while true; do
            # seti is smart enough to know if it's already running
            if [ x$2 = "xlog" -o x$1 = "xlog" ]; then
                ./$PROCESS
            else
                # do not show log
                nohup ./$PROCESS > /dev/null 2>&1 &
            fi
            # old setiathome: -nice $NICE
            sleep $SLEEP
        done
    else
        echo "[failed]"
        echo "Load $LOAD is not less than $MAXLOAD at $HOSTNAME"
    fi
else
    echo "Strange error: $PIDF exist, but we are not running?"
fi

