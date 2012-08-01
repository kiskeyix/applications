#!/bin/bash
# $Revision: 1.0 $
# $Date: 2011-09-23 13:06 EDT $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: simple script to fix the origin URL for some git repositories
# It uses Bash 4 hashes variables (declare -A)
# USAGE: cd ~/Projects; $0
# LICENSE: GPL
_VERSION_CHECK=4
if [[ $BASH_VERSINFO -lt $_VERSION_CHECK ]]; then
    echo Sorry but this only works on Bash $_VERSION_CHECK and up > /dev/stderr
    exit 1
fi

declare -A URLS=(
    [polkit]=http://anongit.freedesktop.org/git/PolicyKit.git
    [NetworkManager]=http://anongit.freedesktop.org/git/NetworkManager/NetworkManager.git
)

for dir in ${!URLS[@]}; do
    echo $dir
    cd $dir || continue
    git remote set-url origin ${URLS[$dir]}
    git fetch --all
    cd ..
    echo # new-line
done
