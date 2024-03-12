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
  - git clone https://github.com/kiskeyix/applications.git Applications
  - ./Applications/scripts/update-host --local

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
    touch ~/.vimrc-`hostname`
    touch ~/.muttrc-`hostname`
    touch ~/.profile-`hostname`

You can also create files for aliases and path with these names:

    touch ~/.alias.setup
    tocuh ~/.path.setup

And add your changes to this new .bashrc-`hostname` file.

The same applies to vimrc, muttrc and other main configuration files.

## Git ##

You might want to clone the public git repository from **github.com**:

    git clone https://github.com/kiskeyix/applications.git

# Pushing your changes to local servers #

That means that you can now use update-host to push your changes 
to local computers with:

    update-host --send-key # uses hosts from ~/.remote-hosts computers
    update-host --local system1.example.com system{2..N}.example.com

NOTE: --send-key is optional and it should be used only once.
It sends your public key to the ~/.ssh/authorized\_keys file on 
the remote host.

And you will see as the script attempts to send the local files to 
each system via SSH (using ssh-agent to keep the session open so you 
are not prompted for passwords/passphrases).

If you make changes to Applications and you want these to be sent to 
remote systems:

    update-host --local server1 server2 ... serverN

# Testing

    bundle exec rake test

# Contributing #

- Fork the repository on Github
- Create a named feature branch (like `add_component_x`)
- Write you change
- Submit a Pull Request using Github

Created: 2007-06-07 11:59 EDT
Updated: 2018-05-18 15:41 EDT
