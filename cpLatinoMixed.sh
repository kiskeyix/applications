#!/bin/bash

#pass extra arg to rsync, eg: v 
ARG='-az --exclude=*.pid'
#remote user
RUSER='luigi'
#local dir where stuff will be saved
LOCALPATH=/home/luigi
#local mysql
MYSQLPATH=/var/lib/mysql
#php
PHPSHARE=/usr/share/php
#jabber could be in /usr/local/bin/jabber
JABBERPATH=/usr/local/bin/jabber

rsync -e ssh $ARG $RUSER@66.9.192.29:/var/lib/mysql/latinomixeddb/ $MYSQLPATH/latinomixeddb;
rsync -e ssh $ARG $RUSER@66.9.192.29:/var/lib/mysql/luiswebloggerdb/ $MYSQLPATH/luiswebloggerdb ;
rsync -e ssh $ARG --delete $RUSER@66.9.192.29:/usr/var/www/html/latinomixed.com/ $LOCALPATH/latinomixed.com/ ;
rsync -e ssh $ARG --delete $RUSER@66.9.192.29:/usr/local/bin/jabber/ $JABBERPATH ;
rsync -e ssh $ARG --delete $RUSER@66.9.192.29:/home/luigi/html/ $LOCALPATH/html ;
rsync -e ssh $ARG --delete $RUSER@66.9.192.29:/home/luigi/php_include/ $LOCALPATH/php_include ;
rsync -e ssh $ARG --delete $RUSER@66.9.192.29:/usr/share/php/ $PHPSHARE ;
rsync -e ssh $ARG $RUSER@66.9.192.29:/usr/local/lib/webstats/ /usr/local/lib/webstats ;
rsync -e ssh $ARG $RUSER@66.9.192.29:/usr/local/bin/webstats.pl /usr/local/bin ;
rsync -e ssh $ARG $RUSER@66.9.192.29:/var/log/jabberd/ /var/log/jabberd ;
#rsync -e ssh $ARG --exclude=.* $RUSER@66.9.192.29:/home/luigi/mypicts/ $LOCALPATH/mypicts ;
#syncback picts
#rsync -e ssh $ARG --exclude=.* $LOCALPATH/mypicts/ $RUSER@66.9.192.29:/home/luigi/mypicts ;


# must be last
# If local is newer, then do not do anything, 
# just upload the rest, and then copy back the newer version ...
# never create new files in the LOCAL directory without it being 
# in the server first!
rsync -e ssh $ARG --update --delete $RUSER@66.9.192.29:myscripts_conf/ $LOCALPATH/myscripts_conf ;
rsync -e ssh $ARG --update $LOCALPATH/myscripts_conf/ $RUSER@66.9.192.29:myscripts_conf ;

