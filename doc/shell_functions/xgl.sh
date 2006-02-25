#!/bin/sh
# $Revision: 1.3 $
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
    sleep 6
    
    DISPLAY=$MY_DISPLAY
    export DISPLAY

    echo "Now run: xterm -display $DISPLAY"
    echo "Switch to that xterm in tty7 and run:"
    echo "gnome-window-decorator"
    echo "compiz --replace gconf"
    echo "CTRL+Z to background and: bg"
    echo "exec ssh-agent dbus-launch --exit-with-session /usr/bin/gnome-session"
    echo "Trying to execute it for you..."
    
    gnome-window-decorator &
    sleep 1
    compiz --replace gconf # no need to background this. it will do it alone
    sleep 1
    xterm -display $DISPLAY &
    sleep 1
    #xterm -display $DISPLAY -e "exec ssh-agent dbus-launch --exit-with-session /usr/bin/gnome-session" &
    exec ssh-agent dbus-launch --exit-with-session /usr/bin/gnome-session
else
    echo "Xgl did not launch correctly on $MY_DISPLAY?"
    echo "Try running: xterm -display $MY_DISPLAY"
fi

