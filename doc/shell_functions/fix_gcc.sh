#!/bin/sh
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-May-06
#
# DESCRIPTION: fixes gcc symlinks when updating to a new version under debian
# USAGE: ./fix_gcc.sh
# CHANGELOG:
#

PRIORITY=52 # 0 - 100. higher is better

GCC="/usr/bin/gcc-3.4"
GPP="/usr/bin/g++-3.4"

# to remove do:
# sudo update-alternatives --remove-all $GCC
# sudo update-alternatives --remove-all $G++

if [ -x ${GCC} ]; then
    sudo update-alternatives --install /usr/bin/gcc gcc ${GCC} \
    $PRIORITY --slave /usr/bin/cc cc ${GCC}
fi

if [ -x ${GPP} ]; then
    sudo update-alternatives --install /usr/bin/g++ g++ ${GPP} \
    $PRIORITY --slave /usr/bin/c++ c++ ${GPP}
fi

