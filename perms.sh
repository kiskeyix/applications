#!/usr/local/bin/bash
# $Id: perms.sh,v 1.1 2002-10-31 14:40:42 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Oct-31
#
# DESCRIPTION: My Solaris permissions
# USAGE:
# CHANGELOG:
#

# do regular files
find ~/ -type f ! -name "*.sh" -exec chmod 0600 {} \;
find ~/ -type f -name "*.sh" -exec chmod 0750 {} \;
# do directories
find ~/ -type d -exec chmod 0750 {} \;

