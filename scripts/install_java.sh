#!/bin/sh
# $Revision: 1.4 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Oct-15
#
# DESCRIPTION: a simple debian script to install java from Sun. This is
#               for java version 1.4.2 and up. You must this as root
# USAGE: sudo $0
# CHANGELOG:
#

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
    FILE=`basename $1`
    cd /usr/local
    tar xzf "$WD/$FILE"
    if [ $? != 0 ]; then
        echo "Extracting $1 failed"
        echo $MESSAGE
        cd $WD
        exit 1
    else
        # TODO  
        # the name of the extracted file might not be j2re-1_4_2...
        # is there a way to automatically detect this?
        mv j2re-1_4_2_01 j2re
        if [ $? !=0 ];then
            echo "Renaming /usr/local/j2re-1_4_2_01 to /usr/local/j2re failed"
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

if [ -d "/usr/local/MozillaFirebird/plugins" ]; then
#    update-alternatives \
#    --install /usr/local/MozillaFirebird/plugins/libjavaplugin_oji.so \
#    libjavaplugin_oji.so \
#    /usr/local/j2re/plugin/i386/ns610-gcc32/libjavaplugin_oji.so \
#    50
    
    ln -sf /etc/alternatives/libjavaplugin_oji.so \
        /usr/local/MozillaFirebird/plugins/libjavaplugin_oji.so

    echo "Putting Mozilla Firebird in Gnome-2 menu"
    echo "[Desktop Entry]" > /usr/share/applications/mozilla-firebird.desktop
    echo "Name=Mozilla Firebird" >> /usr/share/applications/mozilla-firebird.desktop
    echo "Comment=Firebird Web Browser"  >> /usr/share/applications/mozilla-firebird.desktop
    echo "Exec=mozilla-firebird %U"  >> /usr/share/applications/mozilla-firebird.desktop
    echo "Terminal=false"  >> /usr/share/applications/mozilla-firebird.desktop
    echo "MultipleArgs=false"  >> /usr/share/applications/mozilla-firebird.desktop
    echo "Type=Application"  >> /usr/share/applications/mozilla-firebird.desktop
    echo "Icon=web-browser"  >> /usr/share/applications/mozilla-firebird.desktop
    echo "Categories=Application;Network"  >> /usr/share/applications/mozilla-firebird.desktop
fi

if [ -d "/usr/lib/mozilla-firebird/plugins" ]; then
#    update-alternatives \
#    --install /usr/lib/mozilla-firebird/plugins/libjavaplugin_oji.so \
#    libjavaplugin_oji.so \
#    /usr/local/j2re/plugin/i386/ns610-gcc32/libjavaplugin_oji.so \
#    50
 
    ln -sf /etc/alternatives/libjavaplugin_oji.so \
        /usr/lib/mozilla-firebird/plugins/libjavaplugin_oji.so

fi

