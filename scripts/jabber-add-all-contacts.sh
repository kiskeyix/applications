#!/bin/bash
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Oct-27
#
# Csaba Wiesz
# This script uses a temp file to store the name of the contacts, who were already sent all
# other contacts. The users not in the list will receive a full contact list.
# I have to mention that ther can be problems with larger number of users, as the data sent
# can be too much for the karma settings. Therefore I put some sleep lines to make the
# scripts slower.

PATH=/bin:/usr/bin

### Setting some initial parameters ###
ADMIN="jabberadmin" # jabber admin as define in jabberd xml file
ADMINPW="jabberpasswd"
COMPANY="domain"
adminmail="admin@domain.local"
server="intranet.domain.local"
sentfile="/var/lib/jabber/contacts-already-sent.log"
cd "/var/lib/jabber/$server"
users=`/bin/ls -1 *.xml`
touch "$sentfile"

### send_to function sends message to 1 single user with all contact info  of $users

send_to () {

    recipient=$1
    users=`/bin/ls -1 *.xml`
    numusers=`/bin/ls -1 *.xml|wc -l`

    ### Start a stream to server and log in with a presence ###
    echo -e   "<stream:stream to=\"$server\" xmlns=\"jabber:client\" xmlns:stream=\"http://etherx.jabber.org/streams\">\x"
    echo -e   "<iq id='auth2' type='set'><query xmlns='jabber:iq:auth'><username>$ADMIN</username><password>$ADMINPW</password><resource>telnet</resource></query></iq>\n"
    echo -e   "<presence/>\n"


    ### Generate message with dynamic list of all contacts ###
    echo -e "<message id=\"new-contacts\" to=\"$recipient\"><x xmlns=\"jabber:x:roster\">"
    for i in $users ;do 
        i=`basename $i .xml`
        echo "<item name=\"$i\" jid=\"$i@$server\"></item>  " ;
        sleep 1
    done
    echo -e "</x><body>This message contains contact information of all $COMPANY users who are registered at $server Jabber server.\nPlease add them all to your contact list! (Just click Add Contacts below)\n\n[Jabber Admin Account]</body></message>\n"

    ### Close the stream nicely ###
    echo -e "</stream:stream>\n"
}

### Main starts here

for j in $users ; do
    ### If user $j is not in $sentfile then needs sending of addresses ###	
    j="`basename $j .xml`@$server"
    test=`grep -c $j $sentfile`
    if [ $test =  "0" ]
    then
        ### Activate sending through telnet 
        ### then do dome logging and reporting
        send_to  $j | telnet $server 5222
        echo -e "[`date`]\t$j ">>$sentfile
    fi
done	
### Mail sent file to admin
subject="[`date`] New Jabber users received contactlist"
cat $sentfile | mail -s "$subject" $adminmail

