#!/usr/bin/perl -w
# $Revision: 1.2 $
#
# Adds user to ldap server running on ldap://localhost:389
#
use strict;
$|++; # disable buffer (autoflush)
use Getopt::Long;
Getopt::Long::Configure('bundling');

my $USAGE = 'adduser-ldap.pl --uid="username" --first="First" --last="Lastname" [--mailid="mail_id"] [--domain="domain.com"]';

my $pass_cmd = "slappasswd";
my $pass_scheme = "\{MD5\}"; # SSHA, SHA1, MD5, CRYPT

my $search_cmd = "ldapsearch -x -Z localhost ";

my $min_uid = "2000";
my $max_uid = "65000";

my $HELP;

my %rec = ();

my $first = ""; # first name
my $last = ""; # last name (surname)
my $uid = ""; # User ID for login
my $mid = ""; # User ID for our emails: $first_letter$lastname scheme
my $domain = ""; # yields dc=domain,dc=com
my $passwd = ""; # can pass given encrypted string from command line

# visible domain from the outside word
# TODO set this interactively:
$rec{'webhost'} = "www"; # name of web server, without the domain
$rec{'office_number'} = "";
$rec{'fax_number'} = "";
$rec{'mobile_number'} = "";
$rec{'title'} = "";
$rec{'passwd'} = "personal";

GetOptions(
    'f|first=s'         =>\$first,
    'l|last=s'          =>\$last,
    'u|uid=s'           =>\$uid,
    'm|mailid=s'        =>\$mid,
    'd|domain=s'        =>\$domain,
    'p|passwd=s'        =>\$passwd,
    'h|help'            =>\$HELP
);

if ( $HELP ) { print $USAGE; exit 0; }

die ($USAGE) if ($first eq "" || $last eq "" || $domain eq "");

# TODO if interactive, prompt for missing $rec:

# set some internal vars:
my ($fq,$dn) = split(/\./,$domain);
$passwd = qx/$pass_cmd -h $pass_scheme -s $rec{'passwd'}/ if ($passwd eq "");

# create UID and MID using scheme: 
#   (first letter of first name) + (last name)
$uid = ( $uid ne "" ) ? $uid : substr ( $first, 0, 1 ).$last;
$mid = ( $mid ne "" ) ? $mid : substr ( $first, 0, 1 ).$last;

my $home = "/home/$uid";

my $full_name = ucfirst($first)." ".ucfirst($last);
my $initials = substr($first,0,1).substr($last,0,1);

# TODO calculate uid number from previous LDAP user_list
my $uid_number = sprintf ("%02d",rand(my @ary = ($min_uid .. $max_uid)));
my $gid_number = "100"; # TODO get a good GID number from LDAP

# TODO sanity checks: mid, uid, uidNumber, gidNumber, ...

my $ldif = "
dn: cn=$full_name, dc=$fq, dc=$dn
objectClass: top
objectClass: person
objectClass: posixAccount
objectClass: shadowAccount
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: $full_name
sn: $last
givenName: $first
initials: $initials
title: $rec{'title'}
uid: $uid
mail: $mid\@$domain
telephoneNumber: $rec{'office_number'}
facsimileTelephoneNumber: $rec{'fax_number'}
mobile: $rec{'mobile_number'}
roomNumber: 
carLicense: 
departmentNumber: 
employeeNumber:
employeeType: full time
preferredLanguage: en
labeledURI: http://$rec{'webhost'}.$domain/~$uid User Home Page
homeDirectory: $home
gecos: $full_name
shadowMin: -1
shadowMax: 99999
shadowWarning: 7
shadowInactive: -1
shadowExpire: 1
uidNumber: $uid_number
gidNumber: $gid_number
userpassword: $passwd

";

print STDOUT $ldif;
