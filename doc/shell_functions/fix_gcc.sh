#!/bin/sh
# $Revision: 1.5 $
# $Date: 2005-07-18 04:36:07 $
# Luis Mondesi < lemsx1@hotmail.com >
#
# DESCRIPTION: fixes gcc symlinks when updating to a new version under debian
# USAGE: ./fix_gcc.sh
#

PRIORITY=52 # 0 - 100. higher is better

GCC="/usr/bin/gcc-3.4"
GPP="/usr/bin/g++-3.4"
GCCBUG="/usr/bin/gccbug-3.4"
GCOV="/usr/bin/gcov-3.4"

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

if [ -x ${GCOV} ]; then
    sudo update-alternatives --install /usr/bin/gcov gcov ${GCOV} $PRIORITY
fi

if [ -x ${GCCBUG} ]; then
    sudo update-alternatives --install /usr/bin/gccbug gccbug ${GCCBUG} $PRIORITY
fi

