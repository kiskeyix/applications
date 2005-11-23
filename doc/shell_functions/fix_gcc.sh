#!/bin/sh
# $Revision: 1.8 $
# $Date: 2005-11-23 06:29:16 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: fixes gcc symlinks when updating to a new version under debian
# USAGE: ./fix_gcc.sh
#

PRIORITY=54 # 0 - 100. higher is better

GCC="/usr/bin/gcc-4.0"
GPP="/usr/bin/g++-4.0"
GCCBUG="/usr/bin/gccbug-4.0"
GCOV="/usr/bin/gcov-4.0"

# to remove do:
# sudo update-alternatives --remove-all $GCC
# sudo update-alternatives --remove-all $G++

if [ -x ${GCC} ]; then
    if [ -L "/usr/bin/gcc" ]; then
        sudo ln -sf /etc/alternatives/gcc /usr/bin/gcc
        sudo update-alternatives --install /usr/bin/gcc gcc ${GCC} \
        $PRIORITY --slave /usr/bin/cc cc ${GCC}
    else
        echo "Failed to setup gcc symlink in /usr/bin/gcc. Please remove existing symlink first"
    fi
fi

if [ -x ${GPP} ]; then
    if [ -L "/usr/bin/g++" ]; then
        sudo ln -sf /etc/alternatives/g++ /usr/bin/g++
        sudo update-alternatives --install /usr/bin/g++ g++ ${GPP} \
        $PRIORITY --slave /usr/bin/c++ c++ ${GPP}
    else
        echo "Failed to setup g++ symlink in /usr/bin/g++. Please remove existing file"
    fi
fi

if [ -x ${GCOV} ]; then
    sudo ln -sf /etc/alternatives/gcov /usr/bin/gcov
    sudo update-alternatives --install /usr/bin/gcov gcov ${GCOV} $PRIORITY
fi

if [ -x ${GCCBUG} ]; then
    sudo ln -sf /etc/alternatives/gccbug /usr/bin/gccbug
    sudo update-alternatives --install /usr/bin/gccbug gccbug ${GCCBUG} $PRIORITY
fi

