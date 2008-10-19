#!/usr/bin/perl -w
# $Revision: 1.3 $
#
# Adds user to ldap server running on ldap://localhost:389
#
# prints LDIF if --ldif is passed
#
use strict;
$|++;    # disable buffer (autoflush)

use Net::LDAP;
use URI;
use Getopt::Long;
Getopt::Long::Configure('bundling');

my $USAGE =
  'adduser-ldap.pl [--uid="username"] <--first="First"> <--last="Lastname"> [--password="passwd"] [--email="mail_id"] <--domain="domain.com"> [--organizational-unit|--ou="People"] [--posix] [--nt] [--uid-number] [--gid=number] [--home-path|--home] [-D|--bind] [| ldapadd -x -D "cn=admin..." -W]';

#my $pass_cmd = "slappasswd";
my $pass_scheme = "\{CRYPT\}";    # SSHA, SHA1, MD5, CRYPT

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

my $first     = "";    # first name
my $last      = "";    # last name (surname)
my $uid       = "";    # User ID for login
my $mid       = "";    # User ID for our emails: $first_letter$lastname scheme
my $domain    = "";    # yields dc=domain,dc=com
my $passwd    = "";    # can pass given encrypted string from command line
my $posix_uid = "";    # --uid-number
my $posix_gid = "";    # --gid-number
my $home      = "";    # --home-path --home
my $bind      = "";    # -D or --bind

# visible domain from the outside word
# TODO set this interactively:
$rec{'webhost'}       = "www";        # name of web server, without the domain
$rec{'office_number'} = "212.123.4567";
$rec{'fax_number'}    = "212.123.4567";
$rec{'mobile_number'} = "212.123.4567";
$rec{'title'}         = "my title";

GetOptions(
           'debug'                      => \$DEBUG,
           'posix'                      => \$POSIX,
           'nt'                         => \$NT,
           'f|first=s'                  => \$first,
           'l|last=s'                   => \$last,
           'u|uid=s'                    => \$uid,
           'e|m|email=s'                => \$mid,
           'd|domain=s'                 => \$domain,
           'o|ou|organizational-unit=s' => \$OU,
           'p|password=s'               => \$passwd,
           'H|home|home-path=s'         => \$home,
           'U|uid-number=i'             => \$posix_uid,
           'G|gid-number=i'             => \$posix_gid,
           'D|bind=s'                   => \$bind,
           'ldif'                       => \$LDIF,
           'h|help'                     => \$HELP
          );

if ($HELP) { print $USAGE; exit 0; }

print STDERR ($USAGE) and exit(1)
  if ($first eq "" || $last eq "" || $domain eq "");

# helpers
sub random_password
{
    my $num = shift;
    if ($num !~ /^[[:digit:]]+$/ or $num < 8)
    {
        $num = 8;
    }
    my $count          = $num;
    my @password_chars = ('.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z');
    my $_password      = undef;
    for (1 .. $count)
    {
        $_password .= (@password_chars)[rand(@password_chars)];
    }
    return $_password;
}

sub hash_password
{
    my $str     = shift;
    my $_scheme = shift;
    my $hash    = "x";
    if ($_scheme =~ /crypt/i)
    {

        # generates an MD5 sum salted password with 8 random chars
        $hash = crypt($str, "\$1\$" . random_password(8) . "\$");
    }
    return $hash;
}

sub _create_entry
{
    my ($ldap, $dn, $whatToCreate) = @_;
    if ($DEBUG)
    {
        print "DEBUG: _create_entry <pre>";
        print("dn: ", $dn, "\n");
        foreach (@$whatToCreate)
        {
            print($_, "\n");
        }
        print "</pre>";
    }
    my $result = $ldap->add($dn, 'attr' => [@$whatToCreate]);
    return $result;
}
# end helpers

# set some internal vars:
my @domain_parts = split(/\./, $domain);

# create UID and MID using scheme:
#   (first letter of first name) + (last name)
$uid = ($uid ne "") ? $uid : lc(substr($first, 0, 1) . $last);
$mid = ($mid ne "") ? $mid : lc(substr($first, 0, 1) . $last) . "\@" . $domain;

$home = ($home ne "") ? $home : "/home/$uid";    # --posix only

my $full_name = ucfirst($first) . " " . ucfirst($last);
my $initials = substr($first, 0, 1) . substr($last, 0, 1);

# --posix only
# TODO calculate uid number from previous LDAP user_list
my $uid_number =
  ($posix_uid ne "")
  ? $posix_uid
  : sprintf("%02d", rand(my @ary = ($min_uid .. $max_uid)));
my $gid_number =
  ($posix_gid ne "")
  ? $posix_gid
  : "100";    # TODO get a good GID number from LDAP

$passwd =
  ($passwd ne "")
  ? hash_password($passwd,            $pass_scheme)
  : hash_password(random_password(8), $pass_scheme);

# TODO sanity checks: mid, uid, uidNumber, gidNumber, ...

my $ou = ($OU) ? "ou=$OU, " : "";
my $domain_joined = "";
foreach (@domain_parts)
{
    $domain_joined .= "dc=$_, ";
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

# TODO fix the stuff with 1234
$ldif .= "
cn: $full_name
sn: $last
givenName: $first
initials: $initials
title: $rec{'title'}
uid: $uid
mail: $mid
telephoneNumber: $rec{'office_number'}
facsimileTelephoneNumber: $rec{'fax_number'}
mobile: $rec{'mobile_number'}
roomNumber: 0
carLicense: 1234
departmentNumber: 1234
employeeNumber: 1234
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
userpassword: ${pass_scheme}${passwd}

" if ($POSIX);

# TODO remove "1 or" when $ldap is done
if (1 or $LDIF or $DEBUG)
{
    print STDOUT ($ldif, "\n");

    exit 0; # FIXME
}

# FIXME:
# connect to LDAP server and do your thing
$bind = ($bind ne "") ? $bind : "cn=admin, $domain_joined";

print "Binding as: " . $bind . "\n" if ($DEBUG);

my $ldap = Net::LDAP->new("localhost");          # TODO LDAPSERVER
my $_dn  = "uid=${uid},${ou}${domain_joined}";

my $CODE = 0; # assume we won't have errors

my $create_ary = [ 'foo'=>'bar' ];
my $entry_result = _create_entry($ldap, $_dn, $create_ary);
if ($entry_result->code())
{
    print STDERR " Error while creating entry for uid $uid on \$LDAPSERVER\n";

    print STDERR (  ". Server message => code: "
                  . $entry_result->code()
                  . ". name: "
                  . $entry_result->error_name()
                  . ". text: "
                  . $entry_result->error_text());
    $CODE = 1;
    goto EXIT;
}

EXIT:

$ldap->unbind();    # take down session
$ldap->disconnect();

exit $CODE;
