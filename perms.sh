#!bash
# $Id: perms.sh,v 1.5 2002-11-01 16:23:26 luigi Exp $
# $v: $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Nov-01
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

