#!/bin/sh
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A script to start a gnome session under gdm with Compiz+gnome-window-decorator
#EOF
# USAGE: compiz.sh
# LICENSE: GPL
# NOTES:
# * http://lems.kiskeyix.org/puntoyaparte/index.php?story_id=58
# * https://wiki.ubuntu.com/XglHowto
# * https://wiki.nurd.se/global:howto:xgl:session
# * Assumes that you are creating a file named:
##> cat > /usr/share/xsessions/compiz.desktop <<EOF
#[Desktop Entry]
#Encoding=UTF-8
#Name=Compiz
#Comment=This session logs you into GNONE with Compiz enabled
#Exec=/usr/local/bin/compiz.sh
## no icon yet, only the top three are currently used
#Icon=
#Type=Application
#X-Ubuntu-Gettext-Domain=gnome-session-2.0
#EOF
# 
# Now, in gdm.conf-custom you need:
##> cat /etc/gdm/gdm.conf-custom
# [server-Standard]
# name=Xgl server
# command=/usr/bin/Xgl -fullscreen -ac -accel xv -accel glx:pbuffer
# flexible=true
# 
# NOTE thatt :1 is not needed here as gdm will do that for you in the following
# line.
#
# And finally, in /etc/gdm/gdm.conf you need to change:
# 0=Standard to 1=Standard:
##0=Standard
#1=Standard
#
# Now when gdm start, make sure you select your new "compiz" session
#

MY_DISPLAY=:1

# assumes Xgl was launched as:
#Xgl $MY_DISPLAY -ac -accel xv -accel glx:pbuffer -fullscreen &

# and since that takes a little while to load, we sleep for 5 seconds...
sleep 5

# ATI's drivers couldn't start Xgl on :0.0 because the driver wrongly attempts 
# to open :0.0 even if the display is set to :93.0 (as Xgl does by default)
# so, we force the whole thing to go to :1.0 as defined in MY_DISPLAY
if [ -z "$DISPLAY" -o "x$DISPLAY" = "x:0" -o "x$DISPLAY" = "x:0.0" ]; then
    DISPLAY=$MY_DISPLAY
    export DISPLAY
fi

gnome-window-decorator &
sleep 1
compiz --replace gconf # no need to background this. it will do it alone
sleep 1

# this is the proper way to start gnome-session. We need ssh-agent and dbus-launch first
exec ssh-agent dbus-launch --exit-with-session /usr/bin/gnome-session

