#!/bin/bash
rdate -s tock.usno.navy.mil 2> /dev/null;
/bin/mount | grep smbfs | grep -qa iso ||  /bin/mount -t smbfs -o ro,username=smb,password=smbxx2 //www/iso /home/anonymous/iso 2> /dev/null;
/bin/mount | grep smbfs | grep -qa exe ||  /bin/mount -t smbfs -o ro,username=smb,password=smbxx2 //www/exe /home/gratis/exe 2> /dev/null;
/bin/mount | grep smbfs | grep -qa cygwin ||  /bin/mount -t smbfs -o ro,username=smb,password=smbxx2 //www/cygwin /home/anonymous/cygwin 2> /dev/null;
/bin/mount | grep smbfs | grep -qa linux ||  /bin/mount -t smbfs -o ro,username=smb,password=smbxx2 //www/linux /home/anonymous/linux 2> /dev/null;
chmod 0660 /usr/local/bin/jabber/spool/latinomixed.com/* 2>&1> /dev/null;
