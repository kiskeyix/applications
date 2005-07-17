#!/bin/sh
#
# Title="Mount Image"
# Title[es]="Montar Imagen"
#
# $Revision: 1.12 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Jun-09
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
CYPHERS="TRUE serpent FALSE aes FALSE twofish FALSE blowfish FALSE des FALSE xor"

# filetype formats
FORMATS="TRUE ext2 FALSE ext3 FALSE iso9660 FALSE udf FALSE reiserfs FALSE jfs FALSE xfs FALSE minix FALSE ntfs FALSE msdos FALSE vfat FALSE efs"
DBITS="256" # default keybits for cyphers
BITS="TRUE 256 FALSE 512 FALSE 1024"

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
UMOUNT="umount" # umount command
NAUTILUS="nautilus" # nautilus command

# language settings

# Messages
TIT_ENCRYPTED="Encryption"
MSG_ENCRYPTED="Is this an encrypted image?"

TIT_MOUNT="Mount Image"
MSG_MOUNTED="Image already mounted"
MSG_EMOUNT="Could not mount image"

TIT_UMOUNT="Eject Image"
MSG_UMOUNTED="Ejected successfully"
MSG_NOTUMOUNTED="Could not eject image"

TIT_FORMAT="Select filesystem type"
TIT_CYPHER="Select Cypher"

MSG_PASSWORD="Please enter filesystem password"

MSG_SETLO="Setup Loopback"
MSG_UNSETLO="Unset Loopback"
MSG_ESETLO="Setting loopback failed"
MSG_EBLOCK="Wrong device"

set_spanish()
{
    # spanish
    TIT_ENCRYPTED="Cifrado"
    MSG_ENCRYPTED="¿Este es un archivo cifrado?"

    TIT_MOUNT="Montar imagen"
    MSG_MOUNTED="ya está montado"
    MSG_EMOUNT="No pude montar"

    MSG_UMOUNTED="desmontado exitósamente"    
    MSG_NOTUMOUNTED="No pude desmontar"
    TIT_UMOUNT="Desmontar la imagen"

    TIT_FORMAT="Selecciona el tipo de formato"
    TIT_CYPHER="Selecciona módulo cifrado"

    MSG_PASSWORD="Por favor provee la contraseña"

    MSG_SETLO="Activar el archivo especial"
    MSG_UNSETLO="Desactivar el archivo especial"
    MSG_ESETLO="No pude activar el archivo especial"
    MSG_EBLOCK="Archivo especial erroneo"
}

# determine language to use:
if [ -n $LANG ]; then
    if [ "`echo $LANG | grep \"^es\"`" ]; then
        echo "Using Spanish"
        set_spanish
    else
        echo "Using default language"
    fi
fi

# utilities
ask_passwd()
{
    # @arg1 text to display
    # asks the password to use when 
    # mounting encrypted filesystems
    TMP=""
    TMP="`$DIALOG --entry --hide-text --text=\"$1\"`"
    echo $TMP
}

ask_cypher()
{
    TMP=""

    TMP=`$DIALOG --list \
    --title="${TIT_CYPHER}" \
    --radiolist --editable \
    --column="Selected" --column="Cypher" $CYPHERS`

    if [ -z $TMP ]; then
        # what we do when user presses cancel
        TMP="$DCYPHER"
    fi

    echo "$TMP"
}

ask_bits()
{
    TMP=""

    TMP=`$DIALOG --list \
    --title="${TIT_CYPHER} bits" \
    --radiolist --editable \
    --column="Selected" --column="Cypher Bits" $BITS`

    if [ -z $TMP ]; then
        # what we do when user presses cancel
        TMP="$DBITS"
    fi
    
    echo "$TMP"
}

ask_filesystem()
{

    TMP=""

    TMP=`$DIALOG --list \
    --title="${TIT_FORMAT}" \
    --radiolist --editable \
    --column="Selected" --column="Filetype" $FORMATS`

    if [ -z $TMP ]; then
        # what we do when user presses cancel
        TMP="iso9660"
    fi
    
    echo "$TMP"
}

is_encrypted()
{
    $DIALOG --title="${TIT_ENCRYPTED}" --question --text="${MSG_ENCRYPTED}"
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
        $SU -u $SUSER -t "${TIT_MOUNT}" "$MOUNT -t $1 $2 $3"
        if [ "`mount | grep \"$3\"`" ]; then
            echo "yes"
        else
            echo "no"
        fi
    else
        # for convenience. $2 is not a block device, try to mount it
        # letting mount find a block device for us
        $SU -u $SUSER -t "${TIT_MOUNT}" "$MOUNT -o loop -t $1 $2 $3"
        if [ "`mount | grep \"$3\"`" ]; then
            echo "yes"
        else
            echo "no"
        fi
    fi
}

unmount()
{
    # @arg1 message
    # @arg2 path
    $SU -u $SUSER -t "${TIT_UMOUNT}: $1" "$UMOUNT $2"
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
        $SU -u $SUSER -t "$MSG_SETLO $1" "$LO $1 $2"
        if [ $? -eq 0 ]; then
            echo "yes"
        else 
            error "$MSG_ESETLO $1"
            echo "no"
        fi
    else
        error "$MSG_EBLOCK $1"
        echo "no"
    fi
}

setup_enloop()
{
    # @arg1 loop device
    # @arg2 image
    # @arg3 encryption cypher
    # @arg4 bits
    if [ -b $1 ]; then
        # ask user password for encryption
        PASSWORD=""
        PASSWORD="`ask_passwd \"$MSG_PASSWORD\"`"

        $SU -u $SUSER -t "$SETLO $1" "echo $PASSWORD | $LO -k $4 -p0 -e $3 $1 $2"
        if [ $? -eq 0 ]; then
            echo "yes"
        else 
            error "$MSG_ESETLO $1"
            echo "no"
        fi
    else
        error "$MSG_EBLOCK $1"
        echo "no"
    fi
}


unset_loop()
{
    # @arg1 loop device
    if [ -b $1 ]; then
        $SU -u $SUSER -t "$UNSETLO $1" "$LO -d $1"
        if [ $? -eq 0 ]; then
            echo "yes"
        else 
            echo "no"
        fi
    else
        error "$MSG_EBLOCK $1"
        echo "no"
    fi
}

error()
{
    $DIALOG --error \
    --text="$1"
}

info()
{
    $DIALOG --info \
    --text="$1"
}


for arg in $@
do

    file_type="`file \"${arg}\"`"

    # if already mounted continue
    if [ "`mount | grep \"${arg}\"`" ]; then
        if [ "`unmount "$arg ${MSG_MOUNTED}" "$arg"`" = "yes" ]; then
            info "$arg $MSG_UMOUNTED"
            rmdir $USERMOUNTDIR
            rmdir $MOUNTDIR
        else
            error "$MSG_NOTUMOUNTED $arg"
            # TODO find where is mounted and open with nautilus
            # $NAUTILUS 
        fi
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
        $NAUTILUS $USERMOUNTDIR
        info "$arg $MSG_MOUNTED"
    else
        # if mount failed, ask about encryption and filetype
        
        if [ "`is_encrypted`" = "yes" ]; then
            echo "Encryption is used"
            
            # choose encryption type
            echo "Asking about cypher"
            CYPHER="`ask_cypher`"

            if [ -z $CYPHER ]; then
                # what we do when user presses cancel
                CYPHER="$DCYPHER"
            fi

            # choose encryption bits
            echo "Asking about cypher bits"
            CYPHERBITS="`ask_bits`"

            if [ -z $CYPHERBITS ]; then
                # what we do when user presses cancel
                CYPHERBITS="$DBITS"
            fi

            # choose format type
            echo "Asking about filesystem type"
            mtype="`ask_filesystem`"

            if [ "`setup_enloop $LOOPDEV $arg $CYPHER`" = "yes" ]; then
                if [ "`lmount $mtype $LOOPDEV $USERMOUNTDIR $CYPHERBITS`" = "yes" ]; then
                    $NAUTILUS $USERMOUNTDIR
                    info "$arg $MSG_MOUNTED"
                else
                    error "$MSG_EMOUNT $LOOPDEV --> $USERMOUNTDIR"
                    
                    if [ "`unset_loop $LOOPDEV`" = "yes" ]; then
                        info "$LOOPDEV successfully freed"
                    else
                        error "$LOOPDEV could not be released"
                    fi
                    
                    rmdir $USERMOUNTDIR
                    rmdir $MOUNTDIR
                fi
            else
                error "$MSG_ESETLO. $MSG_EBLOCK $LOOPDEV"
                rmdir $USERMOUNTDIR
                rmdir $MOUNTDIR
            fi
        else
            # image is not encrypted... ask about filesystem format
            # and mount
            echo "Encryption is not used"

            echo "Asking about filesystem type"
            mtype="`ask_filesystem`"

            if [ -z $mtype ]; then
                # what we do when user presses cancel
                mtype="iso9660"
            fi

            if [ "`lmount $mtype $arg $USERMOUNTDIR`" = "yes" ]; then
                $NAUTILUS $USERMOUNTDIR
                info "$arg $MSG_MOUNTED"
            else
                error "$MSG_EMOUNT $arg --> $USERMOUNTDIR"
                rmdir $USERMOUNTDIR
                rmdir $MOUNTDIR
            fi
        fi
    fi
done

