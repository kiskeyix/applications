# $1 = args (-co, -ci, -m "message"); $2 module
cvs -z3 -d:ext:lems1@phpweblogger.sourceforge.net:/cvsroot/phpweblogger "$1" $2;
