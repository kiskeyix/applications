#!/bin/sh
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Oct-25
#
# DESCRIPTION: uses fortunes and Xdialog to display a short fortune
#               to the user
# USAGE: $0
# CHANGELOG:
#

PATH=/usr/local/bin:/usr/bin:/bin:$PATH

GTKRC="/usr/share/themes/Nuvola/gtk-1.0/gtkrc"

if [ -x "/usr/bin/zenity" ]; then
    zenity --info \
        --text="`/usr/games/fortune -s`" \
        --title="Fortune" 
        
        #--calendar
else
    
    Xdialog --rc-file "$GTKRC" \
        --backtitle "Today's Fortune" \
        --title "Fortune" \
        --allow-close \
        --ok-label "Ok" \
        --left \
        --msgbox "`/usr/games/fortune -s`" \
        0 0
fi
