#!/bin/sh
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Feb-09
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

FAKEROOT=fakeroot

MODULE_LOC="../modules/" # modules are located in the directory prior to this
PATCH_THE_KERNEL="YES" # always patch the kernel
ALL_PATCH_DIR="../kernel-patches/" # patches are located before this dir
IMAGE_TOP="../" # where to save the resulting .deb files

export IMAGE_TOP ALL_PATCH_DIR PATCH_THE_KERNEL MODULE_LOC
if [ $1 ]; then
    echo -e "Building kernel"
    make-kpkg clean
    make-kpkg --rootcmd $FAKEROOT  --initrd --config oldconfig --append-to-version -custom.$1 --revision $1 clean modules_clean kernel_image modules_image
else
    echo -e "Usage: $0 ## \n \t Where ## is an interger"
fi
