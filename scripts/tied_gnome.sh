#!/bin/sh
# luis mondesi <lemsx1@hotmail.com>
# Last modified: 2003-Oct-21
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
#        Read comments
#

GCONFTOOL="/usr/bin/gconftool-2"

# booleans
SHOW_SPLASH=1   # 1 -> true, 0 -> false
DEFAULT_THEME=1 # would you like all users to use your specified 
                # themes only? see below. 1 -> true, 0 -> false
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

# integers
NUMBER_OF_WORKSPACES=2

# strings
MENU_KEY="Super_L"
RUN_KEY="Super_R"
GTK_THEME="Nuvola"
METACITY_THEME=$GTK_THEME
ICON_THEME="Nuvola"
BACKGROUND="/usr/share/wallpapers/All-Good-People-1.jpg"
SPLASH_IMAGE="/usr/share/pixmaps/splash/Splash-Crystal.png" 
#"/usr/share/pixmaps/splash/gnome-splash.png" <-- default gnome 
BACKGROUND_ORIENTATION="wallpaper" # wallpaper,centered,scaled,strecthed
MONOSPACE_FONT_NAME="Sans Bold 12"
FONT_NAME="Sans Bold 11"
DESKTOP_FONT="Sans Bold 14" # nautilus
TITLE_BAR_FONT="Sans Bold 10" # only if DEFAULT_TITLEBAR_FONT is 0
BROWSER="mozilla-firebird"

# functions
set_defaults()
{
    # @arg $1 path
    # @arg $2 string
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --type string --set $1 "$2"
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
set_mandatory "/apps/metacity/global_keybindings/panel_main_menu" "$RUN_KEY"

# menu key
set_mandatory "/apps/panel/global/menu_key" "$MENU_KEY"

# gnome 2.4
set_mandatory "/apps/metacity/global_keybindings/panel_main_menu" "$MENU_KEY"

# themes
if [ $DEFAULT_THEME != 0 ]; then
    set_mandatory "/desktop/gnome/interface/gtk_theme" "$GTK_THEME"
    set_mandatory "/desktop/gnome/interface/icon_theme" "$ICON_THEME"
    set_mandatory "/apps/metacity/general/theme" "$METACITY_THEME"
fi

# background
if [ $DEFAULT_BACKGROUND != 0 ]; then
    set_mandatory "/desktop/gnome/background/picture_filename" "$BACKGROUND"
    set_mandatory "/desktop/gnome/background/picture_options" "$BACKGROUND_ORIENTATION"
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

#eof
