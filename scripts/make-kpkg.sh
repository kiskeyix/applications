#!/bin/bash
# vim: ft=sh:columns=80 :
# $Revision: 1.35 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Dec-12
#
# LICENSE: GPL (http://www.gnu.org/licenses/gpl.txt)
#
# DESCRIPTION:  an interactive wrapper to Debian's "make-kpkg"
#               to build a custom kernel package using 
#               Distributed CC (distcc) and ccache if available.
#               
# USAGE:    cd to /usr/src/linux (or the linux source tree)
#           and then call:
#           
#           make-kpkg.sh N1 N2
#           
#               where N1 is the number or string appended to the kernel
#               (01 or 02, or 03..., etc...)
#               and N2 is the revision of this kernel: 1.0, 1.1 ...
# TIPS:
#   * setup a $HOME/.make-kpkg.rc with the variables found in this 
#     script (see below) to override them
#
# NOTES:
#   * If your modules are in /usr/src/modules, then your kernel
#     is in /usr/src/linux. In other words, "modules" dir is parallel
#     to your "linux" source directory. Same applies to "kernel-patches"
#   * For distcc/ccache to work, the script assumes that 
#     a symlink /usr/local/bin/gcc -> /usr/bin/ccache exists
#   * If distributed cc (distcc) is installed, then we will distribute 
#     our compilation to the hosts found in: ~/.distcc/hosts
#   * If we also have ccache installed, then we arrange the commands 
#     so that we can use both ccache and distcc. 
#     Make sure that $CCACHE_DIR is setup correctly (man ccache)

CCACHE="`command -v ccache 2> /dev/null`"
DISTCC="`command -v distcc 2> /dev/null`"

if [[ -x "$CCACHE" && -x "$DISTCC" ]]; then
    echo "Setting up distcc with ccache"
    MAKEFLAGS="CCACHE_PREFIX=distcc" # this can't be full path
    CCACHE_PREFIX="distcc" # this can't be full path
    if [[ -L "/usr/local/bin/gcc" ]]; then
        readlink "/usr/local/bin/gcc" | grep ccache && \
            echo "ccache is correctly setup" &&
            export CC="/usr/local/bin/gcc" \
            || echo "No symlink from gcc to ccache found in /usr/local/bin"
    fi
fi

if [[ -f "$HOME/.distcc/hosts" ]];then
    # the format of this file is: 
    #   host1 host2 ... hostN-1 hostN
    echo "Reading $HOME/.distcc/hosts"
    DISTCC_HOSTS=`cat "$HOME/.distcc/hosts"`
else
    DISTCC_HOSTS="localhost"
fi 

CONCURRENCY_LEVEL=5                 # use more than one thread for make
                                    # should detect from the number of
                                    # hosts above 

FAKEROOT="fakeroot"

MODULE_LOC="../modules/"            # modules are located in the 
                                    # directory prior to this

NO_UNPATCH_BY_DEFAULT="YES"         # please do not unpatch the 
                                    # kernel by default

PATCH_THE_KERNEL="YES"              # always patch the kernel

ALL_PATCH_DIR="../kernel-patches/"  # patches are located before 
                                    # this directory
                                     
IMAGE_TOP="../"                     # where to save the resulting 
                                    # .deb files

KPKG_ARCH="i386"                    # kernel architecture we default too. Allows users to pass arguments from .make-kpkg.rc for cross-compilation

# read local variables and override defaults:
if [[ -f "$HOME/.make-kpkg.rc" ]]; then
    # read user settings for the variables given above
    source  "$HOME/.make-kpkg.rc"
fi

# sets all variables:
export IMAGE_TOP ALL_PATCH_DIR PATCH_THE_KERNEL 
export MODULE_LOC NO_UNPATCH_BY_DEFAULT 
export KPKG_ARCH
export CCACHE_PREFIX DISTCC_HOSTS
export MAKEFLAGS CONCURRENCY_LEVEL

## get arguments. if --help, print USAGE
if [[ ! -z "$1" && "$1" != "--help" ]]; then
    if [[ ! -z $2 ]]; then
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
        # no need to continue otherwise
        # Sometimes we just want to make the headers indepentently
        # and/or the debianized sources... thus, continue
#        *)
#            #exit 0
#        ;;
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

    # ask about making kernel_source target
    yesno="No"
    read -p "...Source package for this Kernel? [y/N] " yesno
    case $yesno in
        y* | Y*)
        KERNEL_HEADERS="$KERNEL_HEADERS kernel_source"
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
 

    if [[ $makeit -eq 1 ]]; then
        echo -e "Building kernel [ initrd opts: $BUILD_INITRD ] \n"
        make-kpkg clean
        make-kpkg   --rootcmd $FAKEROOT \
        --config oldconfig \
        --append-to-version "$1" \
        --revision $REVISION \
        $BUILD_INITRD \
        kernel_image $KERNEL_HEADERS
    fi

    # Sometimes we just want to make the headers indepentently
    # or kernel_source 
    
    if [[ x$KERNEL_HEADERS != "x" && $makeit -eq 0  ]]; then
        echo -e "Building kernel [$KERNEL_HEADERS] only \n"
        make-kpkg   --rootcmd $FAKEROOT \
        --config oldconfig \
        --append-to-version "$1" \
        --revision $REVISION \
        $BUILD_INITRD \
        $KERNEL_HEADERS
    fi
  
    # make the modules
    if [[ $mmakeit -eq 1 ]]; then
        make-kpkg clean
        make-kpkg modules_clean
        make-kpkg   --rootcmd $FAKEROOT \
        --config oldconfig \
        --append-to-version "$1" \
        --revision $REVISION \
        $BUILD_INITRD \
        modules_image
    fi
else
    echo -e "Usage: $0 N1 [N2]\n \t Where N1 \
    is an interger or string to append to the kernel name. \
    And optional N2 is a revision for this kernel"
fi

#eof
