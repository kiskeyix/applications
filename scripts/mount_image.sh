#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Oct-26
#
# DESCRIPTION: Opens a dialog and asks user how to mount an image
# USAGE: $0 file.{iso,img,etc}
# CHANGELOG:
#

# encryption support
DCYPHER="serpent"
CYPHERS="serpent aes xor"
# filetypes
FORMATS="ext2 ext3 iso9660 ntfs msdos fat efs"

# programs
LO="losetup"    #
SU="gksu"       # xsu|gnome-sudo
DIALOG="zenity" # gdialog|xdialog
MOUNT="mount"

for arg in $@
do

    file_type=$(file "${arg}")

    if [ "`df | grep \"${arg}\"`" ]; then
        $SU -u root -t "Unmount Loopback Filesystem" -d -e -- umount \"${arg}\";
        continue;
    fi;

    # this is the filetype we will select
    # if it can be detected
    case "$ftype" in
        *ISO\ 9660\ CD-ROM\ filesystem*)
        mtype="iso9660";
        ;;
        *SGI\ disk\ label*)
        mtype="efs";
        ;;
        *data*)
        mtype="data";   # user should supply filetype
        *)
        mtype="";       # user should supply later...
        ;;
    esac;
  
    if [ $DIALOG == "zenity" ]; then
        $DIALOG --question
    fi
done
