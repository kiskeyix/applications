#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Apr-30
#
# DESCRIPTION: updates polidori website's internationalization stats file
# USAGE: ~/bin/update-polidori-web.sh
# CHANGELOG:
#

CWD=`pwd`
cd  ~/Develop/polidori/
echo "updating polidori CVS repository"
cvs update -Pd > /dev/null 2>&1 && \
cd po && ./stats.pl > index.html
if [ -f "polidori.pot" ]; then
    scp polidori.pot lems1@shell.sf.net:/home/groups/p/po/polidori/htdocs/intl/
else
    echo "polidori.pot not found!"
fi
if [ -f "index.html" ]; then
    scp index.html lems1@shell.sf.net:/home/groups/p/po/polidori/htdocs/intl/
else
    echo "index.html not found!"
fi
cd $CWD
