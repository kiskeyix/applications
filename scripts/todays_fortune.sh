#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Oct-14
#
# DESCRIPTION: uses fortunes and Xdialog to display a short fortune
#               to the user
# USAGE: $0
# CHANGELOG:
#

GTKRC="/usr/share/themes/Nuvola/gtk-1.0/gtkrc"
Xdialog --rc-file "$GTKRC" \
        --backtitle "Today's Fortune" \
        --title "Fortune" \
        --allow-close \
        --ok-label "Ok" \
        --left \
        --msgbox "`/usr/games/fortune -s`" \
        0 0

