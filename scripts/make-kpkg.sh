#!/bin/sh
# $Revision: 1.7 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jul-14
#
# DESCRIPTION: Use the wonderful "make-kpkg" from Debian
#               to build a custom kernel.
#               
# USAGE:    cd to /usr/src/linux (or the linux source tree)
#           and then call:
#           
#           make-kpkg.sh #1 #2
#           
#               where #1 is the number or string appended to the kernel
#               (01 or 02, or 03..., etc...)
#               and #2 is the revision of this kernel: 1.0, 1.1 ...
#               
# CHANGELOG:
#

FAKEROOT=fakeroot

MODULE_LOC="../modules/" # modules are located in the directory prior to this
NO_UNPATCH_BY_DEFAULT="YES" # please do not unpatch the kernel by default
PATCH_THE_KERNEL="YES" # always patch the kernel
ALL_PATCH_DIR="../kernel-patches/" # patches are located before this dir
IMAGE_TOP="../" # where to save the resulting .deb files

export IMAGE_TOP ALL_PATCH_DIR PATCH_THE_KERNEL 
export MODULE_LOC NO_UNPATCH_BY_DEFAULT

if [ $1 -a $1 != "--help" ]; then
    if [ $2 ]; then
        REVISION="$2"
    else
        REVISION="1.0"
    fi
    echo -e "Building kernel \n"
    make-kpkg   --rootcmd $FAKEROOT \
                --initrd \
                --config oldconfig \
                --append-to-version -custom.$1 \
                --revision $REVISION \
                clean kernel_image 
    makeit=0

    echo "Do you want to make the Kernel Modules? [y/N] \c"
    read yesno
    case $yesno in
        y* | Y*)
            makeit=1
        ;;
        n* | N*)
            makeit=0
        ;;
    esac
    
    if [ $makeit ]; then
        make-kpkg   --rootcmd $FAKEROOT \
        --config oldconfig \
        --append-to-version -custom.$1 \
        --revision $REVISION \
        modules_clean modules_image
    fi
else
    echo -e "Usage: $0 ## \n \t Where ## is an interger or string to append to the kernel name"
fi
