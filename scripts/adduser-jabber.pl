#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Jun-02
#
# DESCRIPTION: rbsd adduser script for jabber
# USAGE:
# CHANGELOG:
#
use strict;
$|++;

# +------------------------------------
# | By Js Op de Beeck on 12 Mar 2003 
# | This script create new users accounts
# | for Jabber, and send Mail via SMTP
# +------------------------------------

# +------------------------------------
# | Perl needs
# +------------------------------------
#use Mail::Sender;

# +------------------------------------
# | Variables
# +------------------------------------

# Your main jabber hostname.
my $myhost = "intranet.rbsd.local";

# the directory where the user.xml files are kept.
my $jabberuserdir = "/var/lib/jabber/$myhost";

# For SMTP
my $smtp_server = "localhost";
my $smtp_sender = "lmondesi\@rbsd.com"; # the is needed

# More var
my $tel_number = "";
my $mail_support = "$smtp_sender"; # the is needed
my $company_name = "RBSD";

# Set to blank some values - don't change.
my $username = "";
my $usermail = "";
my $pass = "";


# +------------------------------------
# | Script
# +------------------------------------

while ($username eq "") {
    print "Enter a user name ? : ";
    $username = <STDIN>;
    chop($username);
    if ($username eq ""){
        print "Cannot leave username blank ! \n";
    }
    if ( -e "$jabberuserdir/$username.xml" ) {
        print "$0: Error: Username exists in user directory.\n";
        $username = "";
    }
}

while ($pass eq "") {
    print "What's the user password ? : ";
    $pass = <STDIN>;
    chop($pass);
    if ($pass eq ""){
        print "Password cannot be blank !\n";
    }
}

# redundant check..
if ( -e "$jabberuserdir/$username.xml" ) {
    print "$0: Error: Username exists in user directory.\n";
    exit(1);
}

# write the file (should use XML properly and remove plaintext passwd)

my $theline = "<xdb><password xmlns='jabber:iq:auth' xdbns='jabber:iq:auth'>$pass</password><query xmlns='jabber:iq:register' xdbns='jabber:iq:register'><username>$username</username><password xmlns='jabber:iq:auth'>$pass</password></ query><query xmlns='jabber:iq:last' last='0' xdbns='jabber:iq:last'>Disconnected</query>XXXVCARDXXX XXXUSERSXXX</xdb>\n";

# Build a list of all current usernames:
my $user_list = " ";
my @current_users = glob("$jabberuserdir/*.xml");
foreach my $username ( @current_users )
{
    $username =~ s,.*/([a-zA-Z0-9-]+)\.xml,$1,g;
    $user_list = "$user_list <item jid='$username\@intranet.rbsd.local' name='$username' subscription='both'><group>Co-Workers</group></item>"; 
}

$theline =~ s/XXXUSERSXXX/$user_list/g;

# register a vcard with some useful information
my $vcard = "<vCard prodid='-//HandGen//NONSGML vGen v1.0//EN' version='2.0' xmlns='vcard-temp' xdbns='vcard-temp'><FN>$username</FN><N><FAMILY></FAMILY></N><NICKNAME>$username</NICKNAME><URL>http://www.rbsd.com</URL><ORG><ORGNAME>$company_name</ORGNAME></ORG><TITLE>my title</TITLE><BDAY>1/1/2004</BDAY><DESC>Some desc</DESC></vCard>";

$theline =~ s/XXXVCARDXXX/$vcard/g;

# write user file
open ( USRFILE, "> $jabberuserdir/$username.xml" )
|| die "Cannot open user XML file: $!\n";

print USRFILE $theline;
close USRFILE;

chown(109,4,"$jabberuserdir/$username.xml"); # jabber,adm
chmod(0600,"$jabberuserdir/$username.xml");  # rw-------

# +------------------------------------

print "--------------------------------------\n";
print "In $jabberuserdir ,\n";
print "User $username created with password $pass !\n";
print "--------------------------------------\n";
print " \n";

# +------------------------------------

#while ($usermail eq "") {
#    print "What's the user mail address ? : ";
#    $usermail = <STDIN>;
#    chop($usermail);
#    if ($usermail eq ""){
#        print "User mail address must exist ! n";
#    }
#}

#my $message_to_send = "Thanks to register on $company_name Jabber Server.\n Your login : $username\n Your password : $pass\n Your server : $myhostn\n \n Regards.\n\n For support : $mail_support - Tel $tel_number";
#
#ref ($sender = new Mail::Sender({from => "$smtp_sender",smtp
#            => "$smtp_server"})) or die "$Mail::Sender::Errorn";
#
#
#(ref ($sender->MailMsg({to =>$usermail, subject => 'Jabber Registration',
#                msg => $message_to_send}))
#)
#    or die "$Mail::Sender::Errorn";

