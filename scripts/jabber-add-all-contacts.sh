#!/bin/bash
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Jun-02
#
# Csaba Wiesz
# This script uses a temp file to store the name of the contacts, who were already sent all
# other contacts. The users not in the list will receive a full contact list.
# I have to mention that ther can be problems with larger number of users, as the data sent
# can be too much for the karma settings. Therefore I put some sleep lines to make the
# scripts slower.

### Setting some initial parameters ###

adminmail="lmondesi@rbsd.com"
server="intranet.rbsd.local"
sentfile="/var/lib/jabber/contacts-already-sent.log"
cd /var/lib/jabber/$server
users=`ls -1 *.xml`
touch $sentfile

### send_to function sends message to 1 single user with all contact info  of $users

send_to () {

  recipient=$1
  users=`ls -1 *.xml`
  numusers=`ls -1 *.xml|wc -l`

### Start a stream to server and log in with a presence ###
echo -e   "<stream:stream to=\"$server\" xmlns=\"jabber:client\" xmlns:stream=\"http://etherx.jabber.org/streams\">\x"
echo -e   "<iq id='auth2' type='set'><query xmlns='jabber:iq:auth'><username>luigi</username><password>rbsdJabber</password><resource>telnet</resource></query></iq>\n"
echo -e   "<presence/>\n"


### Generate message with dynamic list of all contacts ###
echo -e "<message id=\"new-contacts\" to=\"$recipient\"><x xmlns=\"jabber:x:roster\">"
for i in $users ;do 
  i=`basename $i .xml`
  echo "<item name=\"$i\" jid=\"$i@intranet.rbsd.local\"></item>  " ;
  sleep 1
  done
echo -e "</x><body>Congratulations!   You are registered as user  #$numusers.\nThis message contains contact information of all Company users who are registered at intranet.rbsd.local Jabber server.\nPlease add them all to your contact list, this way they also get notified about your new Jabber address!\n\n[Jabber Admin Account]</body></message>\n"

### Close the stream nicely ###
#echo -e "</stream:stream>\n"
}



### Main starts here

for j in $users ; do
### If user $j is not in $sentfile then needs sending of addresses ###	
	j="`basename $j .xml`@$server"
	test=`grep -c $j $sentfile`
	if [ $test =  "0" ]
	then
### Activate sending through telnet, then do dome logging and reporting ###
	  send_to  $j|telnet intranet.rbsd.local 5222
	  echo -e "[`date`]\t$j ">>$sentfile
	  subject="[`date`]   New Jabber user: $j"
	  cat $sentfile|mail -s "$subject" $adminmail
	fi
done	

