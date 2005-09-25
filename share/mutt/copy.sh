#!/bin/sh
# $Revision: 1.1 $
# $Date: 2005-09-25 22:22:03 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: takes files passed by mutt and
#               copies from default location to
#               the users' own tmp directory.
#               Clever uh?
# USAGE:        create a mailcap entry in your default
#               mailcap file like this:
#
#               image/*; ~/.mutt/copy.sh %s; copiousoutput
# LICENSE: GPL
#

cp $1 ~/tmp/
