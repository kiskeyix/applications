#!/bin/sh
#luis mondesi
#checks whether a connection has been established and sends emails 
#to alert me of such action
#check against an exception list:
# regex (man grep for more)
# IPs to ignore or ports, like jabber! ':5222 | :5269 '
EXCEPTIONS="66.9.192.40.* | .*\:5269 | .*\:5222 | 66.9.192.63.*"

# Ignore DNS servers:
DNS="66.9.192.20.* | 66.9.192.28.*"

MYEMAIL=lemsx1@hotmail.com
RETVAL=0

LOAD=$(uptime|sed -e "s/.*: \([^,]*\).*/\1/" -e "s/ //g")
TIME=$(date +%H:%M)
DATE=$(date +%Y-%m-%d)

if [ $TMP ] 
then
	TMP=$TMP
else
	if [ -d ~/tmp ]
	then
		TMP=~/tmp
	else
		mkdir ~/tmp 
		TMP=~/tmp
	fi
	
	export TMP
fi

TEMPFILE=$TMP/lastestablished$DATE.log

#let's rock
# clear up the file (today's)
echo -e "$DATE $TIME \|/ Load: $LOAD \n\n" > $TEMPFILE
# after stamping the file, then put this data:
netstat -na | grep -vE "$DNS" | grep -vE "$EXCEPTIONS" | grep ESTABLISHED >> $TEMPFILE
RETVAL=$?
if [ $RETVAL = 0 ]; then
	cat $TEMPFILE \
	| mail -s "Established found in $HOSTNAME" $MYEMAIL
fi
#echo $RETVAL

