#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Feb-07
#
# DESCRIPTION: Use the wonderful "make-kpkg" from Debian
#               to build a custom kernel.
#               
# USAGE:    cd to /usr/src/linux (or the linux source tree)
#           and then call:
#           
#           make-kpkg.sh ##
#           
#               where ## is 01 (or 02, or 03..., etc...)
# CHANGELOG:
#

if [ $1 ]; then
    echo -e "Building kernel"
    make-kpkg clean
    make-kpkg --initrd --config oldconfig --append-to-version -custom.$1 --revision $1 clean modules_clean kernel_image modules_image
else
    echo -e "Usage: $0 ## \n \t Where ## is an interger"
fi
