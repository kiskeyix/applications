#!/bin/sh
# luis mondesi <lemsx1@hotmail.com>
# 2003-10-09 13:26 EDT 
#
# DESCRIPTION: a simple Gnome 2 script for sysadmins to 
#		set a bunch
#               of gnome defaults. Remember to check whether
#               /etc/X11/Xmodmap has:
#                   clear Mod4
#                   keycode 0x73 = Super_L
#                   keycode 0x74 = Super_R
#                   keycode 0x75 =  Multi_key
#
#               Check key values with xkeycaps or xev
#

GCONFTOOL="/usr/bin/gconftool-2"

# booleans
SHOW_SPLASH=1
DEFAULT_THEME=1 # would you like all users to use your specified 
                # themes only? see below
DEFAULT_BACKGROUND=0 # would you like a background as the only choice?
                     # see below for background path
DEFAULT_FONT=1  # set a given font. see below

DEFAULT_MENU_TEAROFF=1 # don't tearoff menus by default (this is confusing)
DEFAULT_TITLEBAR_FONT=1 # does metacity uses system font? or see below to set one
DEFAULT_BROWSER=1 # use default browser as mandatory? see below to specify which browser

# integers
NUMBER_OF_WORKSPACES=2

# strings
MENU_KEY="Super_L"
RUN_KEY="Super_R"
GTK_THEME="Nuvola"
METACITY_THEME=$GTK_THEME
ICON_THEME="Nuvola"
BACKGROUND="/usr/share/wallpapers/All-Good-People-1.jpg"
SPLASH_IMAGE="/usr/local/share/pixmaps/Splash-Crystal.png" 
#"/usr/share/pixmaps/splash/gnome-splash.png"
MONOSPACE_FONT_NAME="Sans Bold 12"
FONT_NAME="Sans Bold 11"
DESKTOP_FONT="Sans Bold 14" # nautilus
TITLE_BAR_FONT="Sans Bold 10" # only if DEFAULT_TITLEBAR_FONT is 0
BROWSER="mozilla-firebird"

if [ $SHOW_SPLASH != 0 ]; then
    # show splash for all users?
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type bool --set /apps/gnome-session/options/show_splash_screen true
    if [ $? != 0 ]; then
        echo "Setting Show Splash failed"
    fi

    if [ -f $SPLASH_IMAGE ]; then
        $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /apps/gnome-session/options/splash_image "$SPLASH_IMAGE"
        if [ $? != 0 ]; then
            echo "Setting Splash Image failed"
        fi
    else 
        echo "'$SPLASH_IMAGE' not found"
    fi
else 
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type bool --set /apps/gnome-session/options/show_splash_screen false
    if [ $? != 0 ]; then
        echo "Setting Show Splash to false failed"
    fi
fi

$GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type int --set /apps/metacity/general/num_workspaces $NUMBER_OF_WORKSPACES
if [ $? != 0 ]; then
    echo "Setting Number of Workspaces failed"
fi

# run key
$GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /apps/panel/global/run_key "$RUN_KEY"
if [ $? != 0 ]; then
    echo "Setting Run Key failed"
fi

# menu key
$GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /apps/panel/global/menu_key "$MENU_KEY"
if [ $? != 0 ]; then
    echo "Setting Menu Key failed"
fi

# themes
if [ $DEFAULT_THEME != 0 ]; then
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /desktop/gnome/interface/gtk_theme "$GTK_THEME"
    if [ $? != 0 ]; then
        echo "Setting Gtk Theme failed"
    fi
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /desktop/gnome/interface/icon_theme "$ICON_THEME"
    if [ $? != 0 ]; then
        echo "Setting Icon Theme failed"
    fi
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /apps/metacity/general/theme "$METACITY_THEME"
    if [ $? != 0 ]; then
        echo "Setting Metacity Theme failed"
    fi
fi

# background
if [ $DEFAULT_BACKGROUND != 0 ]; then
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /desktop/gnome/background/picture_filename "$BACKGROUND"
    if [ $? != 0 ]; then
        echo "Setting a background failed"
    fi
    # TODO give a choice to update this?
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /desktop/gnome/background/picture_options "wallpaper"
    if [ $? != 0 ]; then
        echo "Setting picture option failed"
    fi
fi

#fonts
if [ $DEFAULT_FONT != 0 ]; then
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /desktop/gnome/interface/font_name "$FONT_NAME"
    if [ $? != 0 ]; then
        echo "Setting Font Name failed"
    fi

    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /desktop/gnome/interface/monospace_font_name "$MONOSPACE_FONT_NAME"
    if [ $? != 0 ]; then
        echo "Setting Monospace Font Name failed"
    fi
    
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /apps/nautilus/preferences/desktop_font "$DESKTOP_FONT"
    if [ $? != 0 ]; then
        echo "Setting Desktop Font failed";
    fi

    if [ $DEFAULT_TITLEBAR_FONT != 0 ]; then
        $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type bool --set /apps/metacity/general/titlebar_uses_system_font true
        if [ $? != 0 ]; then
            echo "Setting Titlebar Font to System Font failed"
        fi
    else
        $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /apps/metacity/general/titlebar_font "$TITLEBAR_FONT"
        if [ $? != 0 ]; then
            echo "Setting Titlebar Font failed"
        fi
    fi
fi

# tearoff
if [ $DEFAULT_MENU_TEAROFF != 0 ]; then
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type bool --set /desktop/gnome/interface/menus_have_tearoff false
    if [ $? != 0 ]; then
        echo "Setting Menu Have Tearoff failed"
    fi
    
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type bool --set /desktop/gnome/interface/menubar_detachable false
    if [ $? != 0 ]; then
        echo "Setting Menubar detachable failed"
    fi

    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type bool --set /desktop/gnome/interface/toolbar_detachable false
    if [ $? != 0 ]; then
        echo "Setting Toolbar detachable failed"
    fi
fi

if [ $DEFAULT_BROWSER != 0 ]; then
    $GCONFTOOL --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type string --set /desktop/gnome/applications/browser/exec "$BROWSER"
    if [ $? != 0 ]; then
        echo "Setting Browser failed"
    fi
fi

#eof
