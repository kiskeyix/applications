#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Apr-04
#
# DESCRIPTION: fixes gcc symlinks when updating to a new version under debian
# USAGE: ./fix_gcc.sh
# CHANGELOG:
#

PRIORITY=51 # 0 - 100. higher is better

GCC=/usr/bin/gcc-3.3
G++=/usr/bin/g++-3.3

# to remove do:
# sudo update-alternatives --remove-all $GCC
# sudo update-alternatives --remove-all $G++

if [ -x ${GCC} ]; then
    sudo update-alternatives --install /usr/bin/gcc gcc ${GCC} \
    $PRIORITY --slave /usr/bin/cc cc ${GCC}
fi

if [ -x ${G++} ]; then
    sudo update-alternatives --install /usr/bin/g++ g++ ${G++} \
    $PRIORITY --slave /usr/bin/c++ c++ ${G++}
fi

