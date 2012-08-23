# Generic Applications (Home) Folder #

## Introduction ##

This is a generic set of tools and configuration files
for all accounts on all UNIX systems.

It was written from the ground up to work well with all 
shells on all UNIX OSes known, including but not limited to:

  * Linux
  * MacOS X
  * FreeBSD/BSD
  * CygWin

## How to use ##

To use this scripts, just copy this folder to ~/Applications 
and make some simple setup steps.

  - cd ~/
  - wget http://kiskeyix.org/Applications.tar.bz2
  - tar xjf Applications.tar.bz2
  - ./Applications/scripts/update-host --master --local

`update-host` will then execute the following actions for you:
  - ln -s Applications/share/shell/bashrc .bashrc
  - ln -s Applications/share/shell/bash\_profile .bash\_profile
  - ln -s Applications/share/shell/dir\_colors .dir\_colors
  - ln -s Applications/share/shell/inputrc .inputrc

  * original files are saved with .bak extensions.

## How to turn off features ##

If you do not want a functionality, simply remove the symlink like:

    cd ~/
    rm .vim # do not use .vim dir from ~/Applications/share/vim
    rm .mutt # do not use .mutt from ~/Applications/share/mutt

# Local modifications #

All changes needed to modify your environment should be done 
on local files. For instance, to modify your bashrc settings:

    touch ~/.bashrc-`hostname`

And add your changes to this new .bashrc-`hostname` file.

The same applies to vimrc, muttrc and other main configuration files.

# Keeping up-to-date #

There is a command called "update-host" that pulls changes 
from the main repository on my own website: http://lems.kiskeyix.org

    update-host --master

**--master** means "get changes from master server" which is **kiskeyix.org**

## Git ##

You might want to clone the public git repository from **github.com**:

    git clone https://github.com/kiskeyix/applications.git

## Where are my files saved? ##

The actual files are saved to:

    ~/Shared/Software/settings/Applications.tar.bz2

# Pushing your changes to local servers #

That means that you can now use update-host to push your changes 
to local computers with:

    update-host --send-key
    update-host system1.example.com system{2..N}.example.com

NOTE: --send-key is optional and it should be used only once.
It sends your public key to the ~/.ssh/authorized\_keys file on 
the remote host.

And you will see as the script attempts to send the local files to 
each system via SSH (using ssh-agent to keep the session open so you 
are not prompted for passwords/passphrases).

If you make changes to Applications and you want these to be sent to 
remote systems instead of the tarball from --master, you can do:

    update-host --local server1 server2 ... serverN

# Contributing #

Ideas patches and the like, should be submitted to myself at:

Luis Mondesi < lemsx1 !! gmail !! c0m >

(Sorry for the mangled email address, but you as a human will be 
able to type the address correctly)

Created: 2007-06-07 11:59 EDT
Updated: 2012-08-23 00:24 EDT
