#!/usr/bin/perl -w
use strict;
$|++; # disable buffer (autoflush)
use Getopt::Long;
Getopt::Long::Configure('bundling');

my $USAGE = 'adduser-ldap.pl -u "First Lastname"';

my $min_uid = "2000";
my $max_uid = "65000";

my $HELP;
my $first_name = "";
my $last_name = "";
my $uid = ""; # User ID for login
my $mid = ""; # User ID for our emails
# visible domain from the outside word
my $webhost = "www"; # name of web server, without the domain
my $public_domain = "rbsd.com"; # get from dc=rbsd,dc=local ?
my $office_number = "";
my $fax_number = "";
my $mobile_number = "";

GetOptions(
    'u|user=s'            =>\$uid,
    'm|mail=s'            =>\$mid,
    'h|help'            =>\$HELP
);

if ( $HELP ) { print $USAGE; exit 0; }

# create UID and MID using scheme: 
#   (first letter of first name) + (last name)
$uid = ( $uid ne "" ) ? $uid : substr ( $first_name, 0, 1 ).$last_name;
$mid = ( $mid ne "" ) ? $mid : substr ( $first_name, 0, 1 ).$last_name;

my $home = "/home/$uid";

my $full_name = ucfirst($first_name)." ".ucfirst($last_name);
my $initials = substr($first_name,0,1).substr($last_name,0,1);

# TODO calculate uid number from previous LDAP user_list
my $uid_number = sprintf ("%02d",rand(my @ary = ($min_uid .. $max_uid)));
my $gid_number = "100"; # get a good GID number from LDAP

my $ldif = "
dn: cn=$full_name, dc=rbsd, dc=local
objectClass: top
objectClass: person
objectClass: posixAccount
objectClass: shadowAccount
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: $full_name
sn: $last_name
givenName: $first_name
initials: $initials
title: 
uid: $uid
mail: $uid\@$public_domain
telephoneNumber: $office_number
facsimileTelephoneNumber: $fax_number
mobile: $mobile_number
roomNumber: 
carLicense: 
departmentNumber: 
employeeNumber:
employeeType: full time
preferredLanguage: en
labeledURI: http://$webhost.$public_domain/~$uid User Home Page
homeDirectory: $home
gecos: $full_name
shadowMin: -1
shadowMax: 99999
shadowWarning: 7
shadowInactive: -1
shadowExpire: 1
uidNumber: $uid_number
gidNumber: $gid_number

";

print STDOUT $ldif;
