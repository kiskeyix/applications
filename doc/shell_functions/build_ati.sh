#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@gmail.com >
# Last modified: 2004-Dec-19
#
# DESCRIPTION: Simple script to build and install ATI's modules. Needs fglrx_VERSION_i386.deb debian package (hint: get RPM from ati.com and use alien)
# USAGE: $0
# CHANGELOG:
# LICENSE: GPL

echo "This script builds and install the ATI module (fglrx)"
echo "Module will be installed in:"
KVERS=`uname -r`
echo "/lib/modules/${KVERS:?}/kernel/drivers/char/drm/fglrx.ko"
echo "Waiting 5 seconds... (CTRL+C to quit)"
sleep 5

if [ `id -u` != 0 ];then
    echo "You must run this as root (uid=0)";
    exit 1;
fi
cd /lib/modules/fglrx/build_mod/
./make.sh
cd ..
./make_install.sh
