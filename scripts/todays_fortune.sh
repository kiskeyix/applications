#!/bin/sh
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Oct-25
#
# DESCRIPTION: uses fortunes and Xdialog to display a short fortune
#               to the user
#               
# INSTALLATION: needs fortunes ( :-) ) and recode
#
# USAGE: $0
# CHANGELOG:
#

PATH=/usr/local/bin:/usr/bin:/bin:$PATH

GTKRC="/usr/share/themes/Nuvola/gtk-1.0/gtkrc"

# must add to 100%
PROBABILITY="10% off 80% nietzsche.fortunes 10% all"

MESSAGE="`/usr/games/fortune -s $PROBABILITY | recode -q ISO-8859-1..utf-8`"

echo $MESSAGE

if [ -z "$MESSAGE" ]; then
    # DEFAULT (in case of blank messages)
    MESSAGE="Quien no sabe mentir no sabe lo que es verdad
        Friedrich Nietzsche, 'Así habló Zaratustra'."
fi

if [ -x "/usr/bin/zenity" ]; then
#    zenity --info \
#        --text="`/usr/games/fortune -s`" \
#        --title="Fortune" 

    zenity --calendar \
        --text="$MESSAGE" \
        --title="Fortune" 

else
    Xdialog --rc-file "$GTKRC" \
        --backtitle "Today's Fortune" \
        --title "Fortune" \
        --allow-close \
        --ok-label "Ok" \
        --left \
        --msgbox "$MESSAGE" \
        0 0
fi
