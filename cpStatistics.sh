#!/bin/bash
DIR="communications02";
ARG="-Puavz";

rsync -e ssh $ARG webmaster@66.9.192.40:/usr/var/www/httpd/php4/html/events/jpmhq/$DIR/admin/ $HOME/mydocuments/events/jpmhq/$DIR/admin
rsync -e ssh $ARG webmaster@66.9.192.40:/usr/var/www/httpd/php4/html/events/jpmhq/$DIR/d.html $HOME/mydocuments/events/jpmhq/$DIR
rsync -e ssh $ARG webmaster@66.9.192.40:/usr/var/www/httpd/php4/html/events/jpmhq/$DIR/entrance.html $HOME/mydocuments/events/jpmhq/$DIR
rsync -e ssh $ARG webmaster@66.9.192.40:/usr/var/www/httpd/php4/html/events/jpmhq/$DIR/new_user.html $HOME/mydocuments/events/jpmhq/$DIR
rsync -e ssh $ARG webmaster@66.9.192.40:/usr/var/www/httpd/php4/html/events/jpmhq/$DIR/logout.html $HOME/mydocuments/events/jpmhq/$DIR
rsync -e ssh $ARG webmaster@66.9.192.40:/usr/var/www/httpd/php4/php_includes/phplib/ $HOME/mydocuments/events/jpmhq/$DIR/phplib

