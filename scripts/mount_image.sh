#!/bin/sh
# $Revision: 1.5 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Oct-29
#
# DESCRIPTION: Opens a dialog and asks user how to mount an image
# INSTALL: needs zenity (or another graphical dialog replacement) 
#           and gksu (or another su graphical replacement). Remember
#           to update the DIALOG and SU variables below if you want
#           to use other programs than the default "zenity" and
#           "gksu".
#           Make this script executable (chmod 0755 mount_image.sh)
#           Copy this script to "~/.gnome2/nautilus-scripts/Mount Image"
#           i.e.:
#           cp mount_image.sh "~/.gnome2/nautilus-scripts/Mount Image"
#
# USAGE:    $0 file.{iso,img,etc}
# CHANGELOG:
#
# TIP:  setup "sudo" so that this user doesn't need
#       to type a password for the commands "losetup",
#       "umount" and "mount" to avoid unecessary questions
# 
# NOTES: 0 -> flase. 1 -> true.

# super user
SUSER="root"

# encryption support
DCYPHER="serpent"   # default cypher
CYPHERS="TRUE serpent FALSE aes FALSE xor"

# filetype formats
FORMATS="TRUE ext2 FALSE ext3 FALSE iso9660 FALSE ntfs FALSE msdos FALSE fat FALSE efs"

# paths
MOUNTDIR="$HOME/mnt"
LOOPDEV="/dev/loop7"    # block device used for encryption. Or else it 
# will use an automatic device assigned by mount

# programs
LO="losetup"    # setup loop devices
SU="gksu --disable-grab "       # xsu|gnome-sudo. graphical representation of "su"
# TIP: setup "sudo" so that this user doesn't need
# to type a password for the commands "losetup",
# "umount" and "mount" to avoid unecessary questions
DIALOG="zenity" # gdialog|xdialog. dialog replacement for Gnome
MOUNT="mount"   # mount command

# booleans
IS_ENC="no"     # is the filesystem encrypted? will ask later
LOOPSETUP="no"  # don't mind this... 

# utilities
lmount()
{
    # @arg1 ftype
    # @arg2 loopdev
    # @arg3 path
    if [ -b $2 ];then
        $SU -u $SUSER -t "Mount Image" "$MOUNT -t $1 $2 $3"
        if [ "`df | grep \"$3\"`" ]; then
            MOUNTED="yes"
            return 1
        else
            return 0
        fi
    else
        # for convenience. $2 is not a block device, try to mount it
        # letting mount find a block device for us
        $SU -u $SUSER -t "Mount Image" "$MOUNT -o loop -t $1 $2 $3"
        if [ "`df | grep \"$3\"`" ]; then
            MOUNTED="yes"
            return 1
        else
            return 0
        fi
    fi

    # we should never reach this
    return 0
}

unmount()
{
    # @arg1 path
    $SU -u $SUSER -t "Unmount Filesystem" "umount $1"
    if [ $? -eq 0 ]; then
        return 1
    else
        return 0
    fi
}

setup_loop()
{
    # @arg1 loop device
    # @arg2 image
    if [ -b $1 ]; then
        $SU -u $SUSER -t "Setup Loopback $1" "$LO $1 $2"
        if [ $? -eq 0 ]; then
            return 1
        else 
            error "Setting loopback failed"
            return 0
        fi
    else
        error "Wrong block device $1"
        return 0
    fi

    # we should never get here
    return 0
}

setup_enloop()
{
    # @arg1 loop device
    # @arg2 image
    # @arg3 encryption cypher
    if [ -b $1 ]; then
        $SU -u $SUSER -t "Setup Loopback $1" "$LO -e $3 $1 $2"
        if [ $? -eq 0 ]; then
            return 1
        else 
            error "Setting Encrypted loopback failed"
            return 0
        fi
    else
        error "Wrong block encrypted device $1"
        return 0
    fi

    # we should never get here
    return 0
}


unset_loop()
{
    # @arg1 loop device
    if [ -b $1 ]; then
        $SU -u $SUSER -t "Unsetting Loopback $1" "$LO -d $1"
        if [ $? -eq 0 ]; then
            return 1
        else 
            return 0
        fi
    else
        error "Wrong block device $1"
        return 0
    fi

    # we should never get here
    return 0
}

error()
{
    $DIALOG --error \
    --text="$1"
}

for arg in $@
do

    file_type=$(file "${arg}")

    # if already mounted continue
    if [ "`df | grep \"${arg}\"`" ]; then
        continue
    fi

    # this is the filetype we will select
    # if it can be detected
    case "$file_type" in
        *ISO\ 9660\ CD-ROM\ filesystem*)
        mtype="iso9660";
        ;;
        *SGI\ disk\ label*)
        mtype="efs";
        ;;
        *)
        mtype="none";       # user should supply later...
        ;;
    esac;

    # try to mount the file system
    # make directory for this image
    USERMOUNTDIR="$MOUNTDIR/$arg"

    # directory doesn't exist?
    mkdir -p $USERMOUNTDIR

    # try mounting the filesystem with what we know so far
    MOUNTED="no"
    lmount $mtype $arg $USERMOUNTDIR

    if [ $MOUNTED = "yes" ]; then 
        nautilus $USERMOUNTDIR
    else
        # if mount failed, ask about encryption and filetype
        # TODO make utility function...
       
        IS_ENC=`$DIALOG --title="Encryption" --question --text="Is this an encrypted image?"`

        echo "Is it encrypted? [$IS_ENC]"
        
        if [ $IS_ENC ]; then

            echo "Encryption is used"

            # choose encryption type
            echo "Asking about cypher"
            CYPHER=$($DIALOG --list \
            --title="Select Cypher" \
            --radiolist --editable \
            --column="Selected" --column="Cypher" "$CYPHERS")

            if [ -z $CYPHER ]; then
                # what we do when user presses cancel
                CYPHER="$DCYPHER"
            fi

            # choose format type
            echo "Asking about filesystem type"
            mtype=$($DIALOG --list \
            --title="Select filesystem type" \
            --radiolist --editable \
            --column="Selected" --column="Filetype" $FORMATS)

            if [ -z $mtype ]; then
                # what we do when user presses cancel
                mtype="iso9660"
            fi

            # try to setup the encrypted loop
            if [ "`setup_enloop $CYPHER $LOOPDEV ${arg}`" ]; then
                SETUPLOOP="yes"
            else
                SETUPLOOP="no"
            fi

            if [ $SETUPLOOP = "yes" ]; then
                # loop device setup, now mount
                MOUNTED="no"
                lmount $mtype $LOOPDEV $USERMOUNTDIR
                if [ $MOUNTED = "yes" ]; then
                    nautilus $USERMOUNTDIR
                else
                    error "Could not mount $LOOPDEV in $USERMOUNTDIR"
                    unset_loop $LOOPDEV
                    rmdir $USERMOUNTDIR
                    rmdir $MOUNTDIR
                fi
            else
                error "Could not setup encrypted block device $LOOPDEV"
                rmdir $USERMOUNTDIR
                rmdir $MOUNTDIR
            fi
        else
            # image is not encrypted... ask about filesystem format
            # and mount
            echo "Encryption is not used"
            echo "Asking about filesystem type"
            mtype=$($DIALOG --list \
            --title="Select filesystem type" \
            --radiolist --editable \
            --column="Selected" --column="Filetype" $FORMATS)

            if [ -z $mtype ]; then
                # what we do when user presses cancel
                mtype="iso9660"
            fi

            MOUNTED="no"
            lmount $mtype $arg $USERMOUNTDIR

            if [ $MOUNTED = "yes"  ]; then
                nautilus $USERMOUNTDIR
            else
                error "Could not mount $arg in $USERMOUNTDIR"
                rmdir $USERMOUNTDIR
                rmdir $MOUNTDIR
            fi
        fi
    fi
    # reset variables
    IS_ENC="no"
    LOOPSETUP="no"
done

