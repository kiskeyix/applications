#!/bin/sh
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jan-30
#
# DESCRIPTION: a script to start|stop "webcam"
# USAGE: webcam.sh [start|stop|restart] 
#

EMAILUSER=yes           # should an email notification be sent to $USER?
EMAILADDRESS="lemsx1@hotmail.com" # public email or local user
EMAILBIN="/usr/bin/mutt"    # a client that supports -s (subject)

MV="/bin/mv -fu"    # force move only updated files (fu)

USER=luigi
PHOTO=$HOME/Documents/mypicts/tmp   # this should be set in a ~/.rc. This directory holds all new picts

PID=$HOME/webcam.pid   # Process ID of current server

PATH=/bin:/usr/bin  # path to search for commands

DAEMON=/usr/bin/webcam
REALDAEMON=/usr/bin/webcam                      # used when stopping
                                                # if no PID is known
NAME=webcam            # name of the binary
DESC="Zoom USB Camera with Webcam"

CMDLINE=""          # extra arguments to daemon?

APPENDTONAME=`date +%Y-%m%d`

##############################################################
#                       End configuration                    #
##############################################################

CHUID=""            # change uid command. Leave blank. It will provide a user here to use instead of root (id 0)
MESSAGE=""

if test ! -f $DAEMON; then
    MESSAGE="Daemon $DAEMON doesn't exist"
    echo $MESSAGE
    
    if [ $EMAILUSER = "yes" ]; then
        echo $MESSAGE | $EMAILBIN -s "$DESC error" $EMAILADDRESS $USER
    fi
    exit 1
fi

if test $UID -eq 0; then
    CHUID="--chuid $USER"
fi

set -e

case "$1" in
    start)

    if test -f $PID; then
        MESSAGE="PID file $PID exists. This usually mean that $DESC is running. Stop $DESC before starting a new one or remove the file if this is an error."
        echo $MESSAGE

        if [ $EMAILUSER = "yes" ]; then
            echo $MESSAGE | $EMAILBIN -s "$DESC error" $EMAILADDRESS $USER
        fi
        exit 1
    fi

	echo -n "Starting $DESC: "
        /sbin/start-stop-daemon --background $CHUID --start \
            --make-pidfile --pidfile $PID \
            --verbose --exec $DAEMON $CMDLINE || echo -n "<Failed> "
        echo -n "$NAME"
        if [ $EMAILUSER = "yes" -a -f $PID ]; then
            MESSAGE="$DESC succesfully started"
            echo $MESSAGE | $EMAILBIN -s "$DESC success" $EMAILADDRESS $USER
        else
            MESSAGE="$DESC startup failed"
            echo $MESSAGE | $EMAILBIN -s "$DESC error" $EMAILADDRESS $USER

        fi
        ;;

    stop)
        echo -n "Stopping $DESC: "
        # --exec is needed when no PID/pidfile is given
        /sbin/start-stop-daemon --stop --verbose \
            --pidfile $PID --exec $REALDAEMON || echo -n "<Failed> "
        echo -n "$NAME"
        rm -f $PID
        
        if [ $EMAILUSER = "yes" -a ! -f $PID ]; then
            MESSAGE="$DESC succesfully stopped"
            echo $MESSAGE | $EMAILBIN -s "$DESC stopped" $EMAILADDRESS $USER
        else
            MESSAGE="$DESC stopping failed"
            echo $MESSAGE | $EMAILBIN -s "$DESC error" $EMAILADDRESS $USER

        fi
        # rename directory and create a new empty directory
        $MV $PHOTO $PHOTO-$APPENDTONAME.$$$$ && mkdir $PHOTO

        ;;
    restart)
        echo -n "Restarting $DESC: "
        $0 stop
        sleep 5
        $0 start
        ;;
    status)
        if test -f $PID; then
            ps ax | grep -v grep | grep -i $NAME
        else
            echo "$DESC is not running."

        fi
        ;;

  *)
	echo "Usage: $0 {start|stop|restart}" >&2
	exit 1
	;;
esac

if [ $? == 0 ]; then
	echo .
	exit 0
else
	echo failed
	exit 1
fi
