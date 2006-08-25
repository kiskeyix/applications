#!/usr/bin/perl -w
# $Revision: 1.3 $
# 
# Adds user to ldap server running on ldap://localhost:389
#
# prints LDIF if --ldif is passed
#
use strict;
$|++; # disable buffer (autoflush)

use Net::LDAP;
use URI;
use Getopt::Long;
Getopt::Long::Configure('bundling');

my $USAGE = 'adduser-ldap.pl [--uid="username"] <--first="First"> <--last="Lastname"> [--password="passwd"] [--email="mail_id"] <--domain="domain.com"> [--organizational-unit|--ou="People"] [--posix] [--nt]';

#my $pass_cmd = "slappasswd";
my $pass_scheme = "\{MD5\}"; # SSHA, SHA1, MD5, CRYPT

#my $search_cmd = "ldapsearch -x -Z localhost ";

my $min_uid = "2000";
my $max_uid = "65000";

my $HELP;
my $DEBUG;
my $POSIX;
my $NT;
my $OU;
my $LDIF;

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
    'debug'             =>\$DEBUG,
    'posix'             =>\$POSIX,
    'nt'                =>\$NT,
    'f|first=s'         =>\$first,
    'l|last=s'          =>\$last,
    'u|uid=s'           =>\$uid,
    'e|m|email=s'       =>\$mid,
    'd|domain=s'        =>\$domain,
    'o|ou|organizational-unit=s'    =>\$OU,
    'p|password=s'      =>\$passwd,
    'ldif'              =>\$LDIF,
    'h|help'            =>\$HELP
);

if ( $HELP ) { print $USAGE; exit 0; }

print STDERR ($USAGE) and exit(1)
    if ($first eq "" || $last eq "" || $domain eq "");

# set some internal vars:
my @domain_parts = split(/\./,$domain);

# TODO emulate slapasswd
#$passwd = qx/$pass_cmd -h $pass_scheme -s $rec{'passwd'}/ if ($passwd eq "");

# create UID and MID using scheme: 
#   (first letter of first name) + (last name)
$uid = ( $uid ne "" ) ? $uid : lc(substr ( $first, 0, 1 ).$last);
$mid = ( $mid ne "" ) ? $mid : lc(substr ( $first, 0, 1 ).$last);

# TODO --home-path
my $home = "/home/$uid"; # --posix only

my $full_name = ucfirst($first)." ".ucfirst($last);
my $initials = substr($first,0,1).substr($last,0,1);

# --posix only 
# TODO calculate uid number from previous LDAP user_list
my $uid_number = sprintf ("%02d",rand(my @ary = ($min_uid .. $max_uid)));
my $gid_number = "100"; # TODO get a good GID number from LDAP

# TODO sanity checks: mid, uid, uidNumber, gidNumber, ...

my $ou = ( $OU ) ? "ou=$OU, " : "";
my $domain_joined = "";
foreach(@domain_parts)
{
    $domain_joined .= "dc=$_, "
}
$domain_joined =~ s/, $//;

my $ldif = "
dn: cn=$full_name, $ou $domain_joined
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson";

$ldif .= "
objectClass: posixAccount
objectClass: shadowAccount" if ($POSIX);

$ldif .= "
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
labeledURI: http://$rec{'webhost'}.$domain/~$uid User Home Page"; 

$ldif .= "
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

" if ($POSIX);

if ($LDIF or $DEBUG)
{
    print STDOUT ($ldif,"\n");
}

# connect to LDAP server and do your thing
