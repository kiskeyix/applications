#!/bin/sh
# $Revision: 1.14 $
# luis mondesi <lemsx1@hotmail.com>
# Last modified: 2004-Apr-12
#
# DESCRIPTION:  a simple Gnome 2 script for sysadmins to 
#		set a bunch of gnome defaults. Remember 
#		to check whether /etc/X11/Xmodmap has:
#		
#		--- cut here ---
#               
#                   clear Mod4
#                   keycode 0x73 = Super_L
#                   keycode 0x74 = Super_R
#                   keycode 0x75 =  Multi_key
#               
#               --- end cut ---
#               
#               Check key values with xkeycaps or xev
#
# NOTES: all values are "mandatory" unless specified below. 
#        Read comments. Mandatory cannot be modified by users.
#        Defaults can be modified later by the user (not mandatory)
#

### defauls ###
#
# TIP:
# There is no need to change this settings here, 
# better just copy these settings to
# /etc/default/tied_gnome
# and then make modifications in that file instead

DEBUG=0

# tool used to set all settings here
GCONFTOOL="/usr/bin/gconftool-2"

## booleans
SHOW_SPLASH=1   # 1 -> true, 0 -> false
DEFAULT_THEME=1 # would you like all users to use your specified 
                # themes only? see below. 1 -> true, 0 -> false
                # 2003-12-19 18:25 EST updated to "defaults" not
                # "mandatory" as before
DEFAULT_BACKGROUND=0 # would you like a background as the only choice?
                     # see below for background path. 1 -> true, 0 -> false
DEFAULT_FONT=1  # set a given font. see below. 1 -> true, 0 -> false 
                # (not mandatory. Users will be able to modify this)

DEFAULT_MENU_TEAROFF=1  # don't tearoff menus by default 
                        # (this is confusing). 
                        # 1 -> don't tearoff, 0 -> tearoff

DEFAULT_TITLEBAR_FONT=1 # does metacity uses system font? 
                        # or see below to set one. 
                        # 1 -> true, 0 -> false

DEFAULT_BROWSER=1       # use default browser as mandatory? 
                        # see below to specify which browser. 
                        # Non mandatory (false) will set as "default"
                        # 1 -> true, 0 -> false

DISABLE_SOUND_SERVER=1  # enable_esd is dangerous if you setup your 
                        # /etc/esound/esd.conf to:
                        # [esd]
                        # auto_spawn=1
                        # spawn_options=-terminate -nobeeps -as 3
                        # spawn_wait_ms=100
                        # So, we are disabeling this setting. Set to:
                        # 1->to disable the sound server mandatory
                        # to all users, and to anything other than 1
                        # to allow users to set this setting themselves

ENABLE_EVENTS_SOUNDS=1  # A good thing to have... users will need to 
                        # enable Sound Server at Startup
                        # or enable_esd with gconf-editor
                        # (not mandantory) 

## integers
NUMBER_OF_WORKSPACES=2

## strings
MENU_KEY="Super_L"
RUN_KEY="Super_R"
GTK_THEME="Nuvola"
METACITY_THEME="$GTK_THEME"
ICON_THEME="$GTK_THEME"
BACKGROUND="/usr/share/wallpapers/All-Good-People-1.jpg"
SPLASH_IMAGE="/usr/share/pixmaps/splash/gnome-splash.png"
BACKGROUND_ORIENTATION="wallpaper" # wallpaper,centered,scaled,strecthed
MONOSPACE_FONT_NAME="Sans Bold 12"
FONT_NAME="Sans Bold 11"
DESKTOP_FONT="Sans Bold 14" # nautilus
TITLE_BAR_FONT="Sans Bold 10" # only if DEFAULT_TITLEBAR_FONT is 0
BROWSER="firefox"

### end defaults ###

# now read defaults settings for this box if there is any
# the user could copy any of the settings from above into
# /etc/defaults/tied_gnome
if [ -f /etc/default/tied_gnome ];then
    echo "Reading /etc/default/tied_gnome"
    . /etc/default/tied_gnome
fi

# functions
set_defaults()
{
    # @arg $1 path
    # @arg $2 string
    $GCONFTOOL --direct \
    --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults \
    --type string --set $1 "$2"
    if [ $? != 0 ]; then
        echo "Setting $1 failed"
    fi
}

set_bool_defaults()
{
    # @arg $1 path
    # @arg $2 bool (true|false)
    $GCONFTOOL --direct \
    --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults \
    --type bool --set $1 "$2"
    if [ $? != 0 ]; then
        echo "Setting $1 failed"
    fi
}

set_int_defaults()
{
    # @arg $1 path
    # @arg $2 integer
    $GCONFTOOL --direct \
    --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults \
    --type int --set $1 "$2"
    if [ $? != 0 ]; then
        echo "Setting $1 failed"
    fi
}

unset_defaults()
{
    # @arg $1 path
    $GCONFTOOL --direct \
    --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults \
    --unset $1 
    if [ $? != 0 ]; then
        echo "Unsetting $1 failed"
    fi
}


set_mandatory()
{
    # @arg $1 path
    # @arg $2 string
    if [ $DEBUG = 1 ]; then
        echo "Mandatory: '$1'='$2'"
    fi
    $GCONFTOOL --direct \
    --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
    --type string --set $1 "$2"
    if [ $? != 0 ]; then
        echo "Setting $1 failed"
    fi
}

set_bool_mandatory()
{
    # @arg $1 path
    # @arg $2 bool (true|false)
    $GCONFTOOL --direct \
    --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
    --type bool --set $1 "$2"
    if [ $? != 0 ]; then
        echo "Setting $1 failed"
    fi
}

set_int_mandatory()
{
    # @arg $1 path
    # @arg $2 integer
    $GCONFTOOL --direct \
    --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
    --type int --set $1 "$2"
    if [ $? != 0 ]; then
        echo "Setting $1 failed"
    fi
}

unset_mandatory()
{
    # @arg $1 path
    $GCONFTOOL --direct \
    --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
    --unset $1 
    if [ $? != 0 ]; then
        echo "Unsetting $1 failed"
    fi
}

# decisions
if [ $SHOW_SPLASH != 0 ]; then
    # show splash for all users?
    set_bool_mandatory "/apps/gnome-session/options/show_splash_screen" "true"

    if [ -f $SPLASH_IMAGE ]; then
        set_mandatory "/apps/gnome-session/options/splash_image" "$SPLASH_IMAGE"
    else 
        echo "'$SPLASH_IMAGE' not found"
    fi
else 
    set_bool_mandatory "/apps/gnome-session/options/show_splash_screen" "false"
fi

set_int_mandatory "/apps/metacity/general/num_workspaces" "$NUMBER_OF_WORKSPACES"

# run key
set_mandatory "/apps/panel/global/run_key" "$RUN_KEY"

# gnome 2.4
set_mandatory "/apps/metacity/global_keybindings/panel_run_dialog" "$RUN_KEY"

# menu key
set_mandatory "/apps/panel/global/menu_key" "$MENU_KEY"

# gnome 2.4
set_mandatory "/apps/metacity/global_keybindings/panel_main_menu" "$MENU_KEY"

# themes
if [ $DEFAULT_THEME = 1 ]; then
    set_mandatory "/desktop/gnome/interface/gtk_theme" "$GTK_THEME"
    set_mandatory "/desktop/gnome/interface/icon_theme" "$ICON_THEME"
    set_mandatory "/apps/metacity/general/theme" "$METACITY_THEME"
else
    # unset mandatory
    unset_mandatory "/desktop/gnome/interface/gtk_theme"
    unset_mandatory "/desktop/gnome/interface/icon_theme"
    unset_mandatory "/apps/metacity/general/theme"
    # set defaults
    set_defaults "/desktop/gnome/interface/gtk_theme" "$GTK_THEME"
    set_defaults "/desktop/gnome/interface/icon_theme" "$ICON_THEME"
    set_defaults "/apps/metacity/general/theme" "$METACITY_THEME"
fi

# background
if [ $DEFAULT_BACKGROUND = 1 ]; then
    set_mandatory "/desktop/gnome/background/picture_filename" "$BACKGROUND"
    set_mandatory "/desktop/gnome/background/picture_options" "$BACKGROUND_ORIENTATION"
else
    # remofe old mandatory
    unset_mandatory "/desktop/gnome/background/picture_filename"
    unset_mandatory "/desktop/gnome/background/picture_options"
    # set defaults
    set_defaults "/desktop/gnome/background/picture_filename" "$BACKGROUND"
    set_defaults "/desktop/gnome/background/picture_options" "$BACKGROUND_ORIENTATION"
fi

#fonts
if [ $DEFAULT_FONT != 0 ]; then
    unset_mandatory "/desktop/gnome/interface/font_name"
    set_defaults "/desktop/gnome/interface/font_name" "$FONT_NAME"

    unset_mandatory "/desktop/gnome/interface/monospace_font_name"
    set_defaults "/desktop/gnome/interface/monospace_font_name" "$MONOSPACE_FONT_NAME"
   
    unset_mandatory "/apps/nautilus/preferences/desktop_font"
    set_defaults "/apps/nautilus/preferences/desktop_font" "$DESKTOP_FONT"
    if [ $DEFAULT_TITLEBAR_FONT != 0 ]; then
        unset_mandatory "/apps/metacity/general/titlebar_uses_system_font"
        set_bool_defaults "/apps/metacity/general/titlebar_uses_system_font" "true"
    else
        unset_mandatory "/apps/metacity/general/titlebar_font"
        set_defaults "/apps/metacity/general/titlebar_font" "$TITLEBAR_FONT"
    fi
fi

# tearoff
if [ $DEFAULT_MENU_TEAROFF != 0 ]; then
    set_bool_mandatory "/desktop/gnome/interface/menus_have_tearoff" "false"
    set_bool_mandatory "/desktop/gnome/interface/menubar_detachable" "false"
    set_bool_mandatory "/desktop/gnome/interface/toolbar_detachable" "false"
fi

if [ $DEFAULT_BROWSER != 0 ]; then
    set_mandatory "/desktop/gnome/applications/browser/exec" "$BROWSER"
else
    unset_mandatory  "/desktop/gnome/applications/browser/exec"
    set_defaults "/desktop/gnome/applications/browser/exec" "$BROWSER"
fi

if [ $DISABLE_SOUND_SERVER == 1 ]; then
    set_bool_mandatory "/desktop/gnome/sound/enable_esd" "false"
else
    unset_mandatory "/desktop/gnome/sound/enable_esd"
fi

if [ $ENABLE_EVENTS_SOUNDS != 0 ]; then
    unset_mandatory "/desktop/gnome/sound/event_sounds"
    # we are not unsetting the mandatory for enable_esd
    # that will be done by setting DISABLE_SOUND_SERVER to anything
    # other than one
    set_bool_mandatory "/desktop/gnome/sound/enable_esd" "true"
    set_bool_defaults "/desktop/gnome/sound/event_sounds" "true"
fi

#eof
