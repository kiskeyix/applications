#!/bin/sh
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Feb-20
#
# DESCRIPTION: Use the wonderful "make-kpkg" from Debian
#               to build a custom kernel.
#               
# USAGE:    cd to /usr/src/linux (or the linux source tree)
#           and then call:
#           
#           make-kpkg.sh #1 #2
#           
#               where #1 is the number appended to the kernel
#               (01 or 02, or 03..., etc...)
#               and #2 is the revision of this kernel: 1.0, 1.1 ...
#               
# CHANGELOG:
#

FAKEROOT=fakeroot

MODULE_LOC="../modules/" # modules are located in the directory prior to this
PATCH_THE_KERNEL="YES" # always patch the kernel
ALL_PATCH_DIR="../kernel-patches/" # patches are located before this dir
IMAGE_TOP="../" # where to save the resulting .deb files

export IMAGE_TOP ALL_PATCH_DIR PATCH_THE_KERNEL MODULE_LOC
if [ $1 ]; then
    if [ $2 ]; then
        REVISION="$2"
    else
        REVISION="1.0"
    fi
    echo -e "Building kernel"
    make-kpkg clean
    make-kpkg --rootcmd $FAKEROOT  --initrd \
        --config oldconfig --append-to-version -custom.$1 \
        --revision $REVISION clean modules_clean \
            kernel_image modules_image
else
    echo -e "Usage: $0 ## \n \t Where ## is an interger"
fi