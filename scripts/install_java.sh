#!/bin/sh
# $Revision: 1.6 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Feb-10
#
# DESCRIPTION: a simple debian script to install java from Sun. This is
#               for java version 1.4.2 and up. You must this as root
# USAGE: sudo $0
# CHANGELOG:
#

MOZILLA="firefox" # name of the .desktop file and command to execute
MOZILLA_DIR="/usr/local/firefox" # path to Mozilla directory
# this string will become /usr/local/bin/$MOZILLA and will be executed
# by users when double click on .desktop
MOZILLA_CMD_STR="#!/bin/sh\n BROWSER=$MOZILLA_DIR/$MOZILLA \n\$BROWSER -remote \"openURL(\$@, new-tab)\" 2>/dev/null || \$BROWSER \$@"

MESSAGE="Please get the java binary from http://www.java.com and pass it to this installation as an argument. i.e. ./install_java j2re-version-linux-i586.bin"

TMP_JAVA="$1"

if [ x$1 == "xgetjava" ]; then
    echo "Trying to get the java binaries from Sun"
    cd /tmp
    wget http://sunsdlc1-13-vhost1.cam-colo.bbnplanet.com/servlet/EComFileServlet/main_products/SDLC//ESD5/JSCDL/j2sdk/1.4.2_01/j2re-1_4_2_01-linux-i586.bin
    if [ $? !=0 ]; then
        echo "Download failed"        
        echo $MESSAGE
        exit 1
    fi
    TMP_JAVA="/tmp/j2re-1_4_2_01-linux-i586.bin"
fi

if [ -f "$TMP_JAVA" ]; then
    WD=`pwd`
    FILE=`basename $TMP_JAVA`
    cd /usr/local
    #tar xzf "$WD/$FILE"
    /bin/sh $TMP_JAVA
    if [ $? != 0 ]; then
        echo "Extracting $TMP_JAVA failed"
        echo $MESSAGE
        cd $WD
        exit 1
    else
        # TODO  
        # the name of the extracted file might not be j2re-1_4_2...
        # is there a way to automatically detect this?
        ln -sf /usr/local/j2re-1_4_2_01 /usr/local/j2re
        if [ $? !=0 ];then
            echo "Linking /usr/local/j2re-1_4_2_01 to /usr/local/j2re failed"
            echo "Please make sure this directory exists so that we can proceed"
            echo "After that, you can just call this script without any arguments"
            exit 1
        fi
    fi
fi 

update-alternatives --install /usr/local/bin/java java /usr/local/j2re/bin/java 50

# put plugin in standard mozilla location 
update-alternatives \
    --install /usr/lib/mozilla/plugins/libjavaplugin_oji.so \
    libjavaplugin_oji.so \
    /usr/local/j2re/plugin/i386/ns610-gcc32/libjavaplugin_oji.so \
    50

if [ -d "$MOZILLA_DIR/plugins" ]; then
#    update-alternatives \
#    --install /usr/local/MozillaFirebird/plugins/libjavaplugin_oji.so \
#    libjavaplugin_oji.so \
#    /usr/local/j2re/plugin/i386/ns610-gcc32/libjavaplugin_oji.so \
#    50
    WD=`pwd`
    cd "$MOZILLA_DIR/plugins" 
    ln -sf /etc/alternatives/libjavaplugin_oji.so \
        libjavaplugin_oji.so

    echo "Putting Mozilla Firebird in Gnome-2 menu"
    echo "[Desktop Entry]" > /usr/share/applications/$MOZILLA.desktop
    echo "Name=$MOZILLA" >> /usr/share/applications/$MOZILLA.desktop
    echo "Comment=Firebird Web Browser"  >> /usr/share/applications/$MOZILLA.desktop
    echo "Exec=$MOZILLA %U"  >> /usr/share/applications/$MOZILLA.desktop
    echo "Terminal=false"  >> /usr/share/applications/$MOZILLA.desktop
    echo "MultipleArgs=false"  >> /usr/share/applications/$MOZILLA.desktop
    echo "Type=Application"  >> /usr/share/applications/$MOZILLA.desktop
    echo "Icon=web-browser"  >> /usr/share/applications/$MOZILLA.desktop
    echo "Categories=Application;Network"  >> /usr/share/applications/$MOZILLA.desktop
fi

if [ -d "/usr/lib/$MOZILLA/plugins" ]; then
#    update-alternatives \
#    --install /usr/lib/$MOZILLA/plugins/libjavaplugin_oji.so \
#    libjavaplugin_oji.so \
#    /usr/local/j2re/plugin/i386/ns610-gcc32/libjavaplugin_oji.so \
#    50
    #cd "/usr/lib/$MOZILLA/plugins" 
    ln -sf /etc/alternatives/libjavaplugin_oji.so \
        /usr/lib/$MOZILLA/plugins/libjavaplugin_oji.so

fi

if [ ! -x "/usr/local/bin/$MOZILLA" ]; then
    echo -e $MOZILLA_CMD_STR > "/usr/local/bin/$MOZILLA"
    chmod 0755 "/usr/local/bin/$MOZILLA"
else
    echo "/usr/local/bin/$MOZILLA already exists"
fi

