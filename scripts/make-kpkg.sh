#!/bin/bash
# $Revision: 1.25 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Dec-14
#
# DESCRIPTION:  an interactive wrapper to Debian's "make-kpkg"
#               to build a custom kernel package.
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
# NOTES:
#   * your modules should be in /usr/src/modules if your kernel
#     is in /usr/src/linux. In other words, "modules" dir is parallel
#     to your "linux" source directory. Same applies to "kernel-patches"
#
# CHANGELOG:
#   See CVS log
#

# TODO: divise a better routine to find executables
# according to the users $PATH

# if distributed cc is installed, then
#  we will distribute our compilation
#  to the following hosts:
# if we also have ccache installed,
# then we arrange the commands so that
# we can use both ccache and distcc

export MAKEFLAGS="CCACHE_PREFIX=distcc";
export CCACHE_PREFIX="distcc"

if [ -f "$HOME/.distcc/hosts" ];then
    echo "Reading $HOME/.distcc/hosts"
    export DISTCC_HOSTS="`cat \"$HOME/.distcc/hosts\"`"
else
    export DISTCC_HOSTS="localhost www2"
fi 

FAKEROOT="fakeroot"

MODULE_LOC="../modules/"            # modules are located in the 
                                    # directory prior to this

NO_UNPATCH_BY_DEFAULT="YES"         # please do not unpatch the 
                                    # kernel by default

PATCH_THE_KERNEL="NO"               # always patch the kernel

ALL_PATCH_DIR="../kernel-patches/"  # patches are located before 
                                    # this directory
                                     
IMAGE_TOP="../"                     # where to save the resulting 
                                    # .deb files

export IMAGE_TOP ALL_PATCH_DIR PATCH_THE_KERNEL 
export MODULE_LOC NO_UNPATCH_BY_DEFAULT 

if [ $1 -a $1 != "--help" ]; then

    if [ $2 ]; then
        REVISION="$2"
    else
        REVISION="1.0"
    fi

    # ask whether to create a kernel image
    makeit=0
    yesno="No"

    read -p "Do you want to make the Kernel? [y/N] " yesno
    case $yesno in
        y* | Y*)
            makeit=1
        ;;
    esac
    # ask about initrd 
    yesno="No"
    read -p "Do you want to enable initrd support? [y/N] " yesno
    case $yesno in
        y* | Y*)
            echo "Initrd support enabled"
            BUILD_INITRD=" --initrd"
            INITRD="YES"
            INITRD_OK="YES"

            export INITRD
        ;;
        *)
            echo "Initrd support disabled"
            BUILD_INITRD=""
            # reset initrd
            unset INITRD
            INITRD_OK="NO"
        ;;
    esac

    export INITRD_OK 

    # ask about making the kernel headers
    yesno="No"
    KERNEL_HEADERS=""

    read -p "...Headers package for this Kernel? [y/N] " yesno
    case $yesno in
        y* | Y*)
        KERNEL_HEADERS="kernel_headers"
        ;;
    esac

    # ask whether to create all kernel module images
    # from ../modules (or /usr/src/modules)
    
    mmakeit=0
    myesno="No"

    read -p "Do you want to make the Kernel Modules [$MODULE_LOC] ? [y/N] " myesno
    case $myesno in
        y* | Y*)
            mmakeit=1
        ;;
    esac
 

    if [ $makeit -eq 1 ]; then
        echo -e "Building kernel [ initrd opts: $BUILD_INITRD ] \n"
        make-kpkg clean
        make-kpkg   --rootcmd $FAKEROOT \
        --config oldconfig \
        --append-to-version -custom.$1 \
        --revision $REVISION \
        $BUILD_INITRD \
        kernel_image $KERNEL_HEADERS
    fi

    # Sometimes we just want to make the headers indepentently
    
    if [ x$KERNEL_HEADERS != "x" -a $makeit -eq 0  ]; then
        echo -e "Building kernel headers only \n"
        make-kpkg   --rootcmd $FAKEROOT \
        --config oldconfig \
        --append-to-version -custom.$1 \
        --revision $REVISION \
        $BUILD_INITRD \
        $KERNEL_HEADERS
    fi
  
    # make the modules
    if [ $mmakeit -eq 1 ]; then
        make-kpkg clean modules_clean
        make-kpkg   --rootcmd $FAKEROOT \
        --config oldconfig \
        --append-to-version -custom.$1 \
        --revision $REVISION \
        $BUILD_INITRD \
        modules_image
    fi
else
    echo -e "Usage: $0 ## \n \t Where ## \
    is an interger or string to append to the kernel name"
fi

#eof
