#!/bin/sh
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A script to start Xgl and a gnome session with Compiz+gnome-window-decorator
# USAGE: xgl.sh
# LICENSE: GPL
# NOTES:    http://lems.kiskeyix.org/puntoyaparte/index.php?story_id=58
#           https://wiki.ubuntu.com/XglHowto
#           https://wiki.nurd.se/global:howto:xgl:session
#           

MY_DISPLAY=:1

Xgl $MY_DISPLAY -ac -accel xv -accel glx:pbuffer -fullscreen &
if [ $? == 0 ]; then
    DISPLAY=$MY_DISPLAY
    export DISPLAY
    echo "Now run: xterm -display $DISPLAY"
    echo "Switch to that xterm in tty7 and run: compiz --replace gconf"
    echo "gnome-window-decorator"
    echo "CTRL+Z to background and: bg"
    echo "exec ssh-agent dbus-launch --exit-with-session /usr/bin/gnome-session"
    echo "Trying to execute it for you..."
    xterm -display $DISPLAY &
    xterm -display $DISPLAY -e "compiz --replace gconf" # no need to background this
    sleep 3
    xterm -display $DISPLAY -e "gnome-window-decorator &" &
    #xterm -display $DISPLAY -e "exec ssh-agent dbus-launch --exit-with-session /usr/bin/gnome-session" &
    exec ssh-agent dbus-launch --exit-with-session /usr/bin/gnome-session
else
    echo "Xgl did not launch correctly on $MY_DISPLAY?"
    echo "Try running: xterm -display $MY_DISPLAY"
fi

