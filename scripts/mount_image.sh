#!/bin/sh
# $Revision: 1.6 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Oct-30
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

# Messages
TIT_ENCRYPTED[en]="Encryption"
MSG_ENCRYPTED[en]="Is this an encrypted image?"

TIT_MOUNT[en]="Mount Image"
MSG_MOUNTED[en]="already mounted"

TIT_FORMAT[en]="Select filesystem type"
TIT_CYPHER[en]="Select Cypher"

# spanish
TIT_ENCRYPTED[es]="Cifrado"
MSG_ENCRYPTED[es]="¿Este es un archivo cifrado?"

TIT_MOUNT[es]="Montar Imagen"
MSG_MOUNTED[es]="ya está montado"

TIT_FORMAT[es]="Selecciona el tipo de formato"
TIT_CYPHER[es]="Selecciona Cifrado"

# determine language to use:
if [ -n $LANG ]; then
    if [ "`echo $LANG | grep \"^en\"`" ]; then
        echo "Using English"
        LANG="en"
    elif [ "`echo $LANG | grep \"^es\"`" ]; then
        echo "Using Spanish"
        LANG="es"
    else
        echo "Using default language"
        LANG="en"
    fi
else
    echo "Using default language"
    LANG="en"
fi

# utilities
ask_cypher()
{
    TMP=""

    TMP=$($DIALOG --list \
            --title="${TIT_CYPHER[$LANG]}" \
            --radiolist --editable \
            --column="Selected" --column="Cypher" $CYPHERS)
    if [ -z $TMP ]; then
        # what we do when user presses cancel
        TMP="$DCYPHER"
    fi

    echo "$TMP"
}

ask_filesystem()
{

    TMP=""

    TMP=$($DIALOG --list \
    --title="${TIT_FORMAT[$LANG]}" \
    --radiolist --editable \
    --column="Selected" --column="Filetype" $FORMATS)

    if [ -z $TMP ]; then
        # what we do when user presses cancel
        TMP="iso9660"
    fi
    
    echo "$TMP"
}

is_encrypted()
{
    $DIALOG --title="${TIT_ENCRYPTED[$LANG]}" --question --text="${MSG_ENCRYPTED[$LANG]}"
    RET=$?
    if [ $RET -eq 0 ];then
        echo "yes"
    else
        echo "no"
    fi
}

lmount()
{
    # @arg1 ftype
    # @arg2 loopdev
    # @arg3 path
    if [ -b $2 ];then
        $SU -u $SUSER -t "${TIT_MOUNT[$LANG]}" "$MOUNT -t $1 $2 $3"
        if [ "`mount | grep \"$3\"`" ]; then
            echo "yes"
        else
            echo "no"
        fi
    else
        # for convenience. $2 is not a block device, try to mount it
        # letting mount find a block device for us
        $SU -u $SUSER -t "${TIT_MOUNT[$LANG]}" "$MOUNT -o loop -t $1 $2 $3"
        if [ "`mount | grep \"$3\"`" ]; then
            echo "yes"
        else
            echo "no"
        fi
    fi

    # we should never reach this
    echo "no"
}

unmount()
{
    # @arg1 path
    $SU -u $SUSER -t "Unmount Filesystem" "umount $1"
    if [ $? -eq 0 ]; then
        echo "yes"
    else
        echo "no"
    fi
}

setup_loop()
{
    # @arg1 loop device
    # @arg2 image
    if [ -b $1 ]; then
        $SU -u $SUSER -t "Setup Loopback $1" "$LO $1 $2"
        if [ $? -eq 0 ]; then
            echo "yes"
        else 
            error "Setting loopback failed"
            echo "no"
        fi
    else
        error "Wrong block device $1"
        echo "no"
    fi

    # we should never get here
    echo "no"
}

setup_enloop()
{
    # @arg1 loop device
    # @arg2 image
    # @arg3 encryption cypher
    if [ -b $1 ]; then
        $SU -u $SUSER -t "Setup Loopback $1" "$LO -e $3 $1 $2"
        if [ $? -eq 0 ]; then
            echo "yes"
        else 
            error "Setting Encrypted loopback failed"
            echo "no"
        fi
    else
        error "Wrong block encrypted device $1"
        echo "no"
    fi

    # we should never get here
    echo "no"
}


unset_loop()
{
    # @arg1 loop device
    if [ -b $1 ]; then
        $SU -u $SUSER -t "Unsetting Loopback $1" "$LO -d $1"
        if [ $? -eq 0 ]; then
            echo "yes"
        else 
            echo "no"
        fi
    else
        error "Wrong block device $1"
        echo "no"
    fi

    # we should never get here
    echo "no"
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
    if [ "`mount | grep \"${arg}\"`" ]; then
        echo "$arg ${MSG_MOUNTED[$LANG]}"
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

    if [ "`lmount $mtype $arg $USERMOUNTDIR`" = "yes" ]; then 
        nautilus $USERMOUNTDIR
    else
        # if mount failed, ask about encryption and filetype
        
        if [ "`is_encrypted`" = "yes" ]; then
            echo "Encryption is used"
            
            # choose encryption type
            echo "Asking about cypher"
            CYPHER=$(ask_cypher)

            if [ -z $CYPHER ]; then
                # what we do when user presses cancel
                CYPHER="$DCYPHER"
            fi

            # choose format type
            echo "Asking about filesystem type"
            mtype=$(ask_filesystem)

            if [ "`setup_enloop $CYPHER $LOOPDEV ${arg}`" = "yes" ]; then
                if [ "`lmount $mtype $LOOPDEV $USERMOUNTDIR`" = "yes" ]; then
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
            mtype=$(ask_filesystem)

            if [ -z $mtype ]; then
                # what we do when user presses cancel
                mtype="iso9660"
            fi

            if [ "`lmount $mtype $arg $USERMOUNTDIR`" = "yes" ]; then
                nautilus $USERMOUNTDIR
            else
                error "Could not mount $arg in $USERMOUNTDIR"
                rmdir $USERMOUNTDIR
                rmdir $MOUNTDIR
            fi
        fi
    fi
done

