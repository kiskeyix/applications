#!/usr/bin/perl -w
# $Revision: 1.4 $
# $Date: 2003-03-12 05:16:45 $
#
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Mar-12
#
# DESCRIPTION: interactively create a new
#               virtual website
# USAGE:    launch and answer questions
# CHANGELOG:

use Term::ReadLine;
use Getopt::Long;
Getopt::Long::Configure('bundling');
use strict;
$|++;

my $term = new Term::ReadLine 'new_site';

my $USE_CPU = 0; # cpu is the LDAP useradd/usermod program
my $USE_USERADD = 0; # create new user using useradd
my $HELP=0;

my $USAGE = "new_site.pl [-h|--help] [-u|--useradd] [-c|--cpu]\n";

# get options
GetOptions(
    'u|useradd'=>\$USE_USERADD,
    'c|cpu' => \$USE_CPU,
    'h|help' => \$HELP,
);

if ( $HELP ) { 
    print STDERR $USAGE;
    exit(1);
}

if ( $USE_CPU ) {
    print STDERR "Using 'cpu' to create user\n";
}

if ( $USE_USERADD ) {
    print STDERR "Using 'useradd' to create user\n";
}

# start script
my $WELCOME_MSG="Welcome to the new_site creator. Please follow prompts:\n";

print $WELCOME_MSG,"\n";

my $SERVER_IP=prompt("Enter server IP: ");
my $SITE=prompt("Enter site: ");
my $WEBMASTER=prompt("Enter webmaster username: ");
my $WEBMASTER_EMAIL="$WEBMASTER\@$SITE";

# default Volume policy for mod_throttle
my $VOLUME="375m"; # 3Gbits = 375MBytes
my $PERIOD="4w";   # montly = 4w

$VOLUME=prompt("Please Enter mod_throttle volume[$VOLUME]: ",$VOLUME);
$PERIOD=prompt("Please Enter mod_throttle period[$PERIOD]: ",$PERIOD);

# virtual hosts go to:
my $APACHE_CONF="/etc/apache/httpd.conf";
# virtual email go to:
my $SMTP_VIRTUAL="/etc/postfix/virtual";

$APACHE_CONF=prompt("Enter apache config file[$APACHE_CONF]: ",$APACHE_CONF);
$SMTP_VIRTUAL=prompt("Enter SMTP virtual config file[$SMTP_VIRTUAL]: ",$SMTP_VIRTUAL);

my $APACHE_HOST_TEMPLATE="\n<VirtualHost $SERVER_IP>\n\tThrottlePolicy Volume $VOLUME $PERIOD\n\tServerAdmin $WEBMASTER_EMAIL\n\tDocumentRoot /home/$WEBMASTER/$SITE/html\n\tServerName $SITE\n\tErrorLog /var/log/apache/$SITE-error.log\n\tCustomLog /var/log/apache/$SITE-access_log combined\n\t<Directory />\n\t\tAllowOverride FileInfo AuthConfig Limit Options\n\t</Directory>\n</VirtualHost>\n";

# print output to files:
# summary to STDOUT
print STDOUT "Summary:\n";
print STDOUT "\tServer IP: $SERVER_IP\n";
print STDOUT "\tSite: $SITE\n";
print STDOUT "\tWebmaster: $WEBMASTER\n";
print STDOUT "\tE-Mail: $WEBMASTER_EMAIL\n";
print STDOUT "\tApache.conf append: $APACHE_HOST_TEMPLATE\n";

# prompt user whether he/she wants to go ahead with changes
my $CONFIRM="n";
$CONFIRM=prompt("Go ahead and commit these values[N]: ",$CONFIRM);

if ( $CONFIRM !~ m/^ *y/i){
    print STDERR "Changes discarded\n";
    exit(0);
}

# user was created using the following:
#
# useradd -m -d /home/$WEBMASTER -s /bin/false -g popusers $WEBMASTER
# passwd $WEBMASTER
# mkdir -p /home/$WEBMASTER/$SITE/html
# 
# if LDAP user, just put "cpu" in front of "useradd" above and change
# -g popusers to -g GID (500). Also, note that cpu asks for a password

if ( $USE_CPU ) {
    system("useradd -m -d /home/$WEBMASTER -s /bin/false -g 500 $WEBMASTER ");
} elsif ( $USE_USERADD ) {
    system("useradd -m -d /home/$WEBMASTER -s /bin/false -g popusers $WEBMASTER ");
    system("passwd $WEBMASTER");
}

# append to apache conf file
open (APACHE,">>$APACHE_CONF") or warn "File $APACHE_CONF could not be open for writing\n";
print APACHE $APACHE_HOST_TEMPLATE,"\n";
close(APACHE);

# SMTP virtual file
open (SMTP,">>$SMTP_VIRTUAL") or warn "File $SMTP_VIRTUAL could not be open for writing\n";
print SMTP "\@$SITE $WEBMASTER\n";

my $MAKE_MAP="makemap";

if ( $SMTP_VIRTUAL =~ m/postfix/i) {
    $MAKE_MAP = "postmap";    
} elsif ( $SMTP_VIRTUAL =~ m/(sendmail|mail)/i ) {
    $MAKE_MAP = "makemap hash"; 
}

print STDOUT "Run '$MAKE_MAP' or favorite hash map creator on '$SMTP_VIRTUAL' to activate alias name\n";

# functions

sub prompt {
    # promt user and return input 
    # pass string when calling subroutine: $var = prompt("string");
    
    my($string) = $_[0];
    my($default) = $_[1];
    
    my($input) = "";
    
    $input=$term->readline("* $string");
    if ($input eq "") {
        $input = $default;
    }
    # if not readline support, uncomment these:
    # print ("* ".$string."\n");
    # chomp($input = <STDIN>);

    return $input;
}
