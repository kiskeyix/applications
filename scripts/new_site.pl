#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Mar-09
#
# DESCRIPTION: interactively create a new
#               virtual website
# USAGE:    launch and answer questions
# CHANGELOG:

use Term::ReadLine;
use strict;
#use Config;
$|++;

my $term = new Term::ReadLine 'new_site';

my $WELCOME_MSG="";

print $WELCOME_MSG,"\n";

my $SERVER_IP=prompt("Enter server IP:\n");
my $SITE=prompt("Enter site:\n");
my $WEBMASTER=prompt("Enter webmaster username:\n");
my $WEBMASTER_EMAIL="$WEBMASTER\@$SITE";

# virtual hosts go to:
my $APACHE_CONF="/etc/apache/httpd.conf";
# virtual email go to:
my $SMTP_VIRTUAL="/etc/postfix/virtual";

$APACHE_CONF=prompt("Enter apache config file[$APACHE_CONF]:\n");
$SMTP_VIRTUAL=prompt("Enter SMTP virtual config file[$SMTP_VIRTUAL]:\n");

my $APACHE_HOST_TEMPLATE="\n<VirtualHost $SERVER_IP>\nServerAdmin $WEBMASTER_EMAIL\nDocumentRoot /home/$WEBMASTER/$SITE/html\nServerName $SITE\nErrorLog /var/log/apache/$SITE-error.log\nCustomLog /var/log/apache/$SITE-access_log combined\n<Directory />\nAllowOverride FileInfo AuthConfig Limit Options\n</Directory>\n</VirtualHost>\n";

print $SERVER_IP,"\n";
print $SITE,"\n";
print $WEBMASTER,"\n";
print $WEBMASTER_EMAIL,"\n";

print $APACHE_CONF,"\n";
print $SMTP_VIRTUAL,"\n";
print $APACHE_HOST_TEMPLATE,"\n";

sub prompt {
    # promt user and return input 
    # pass string when calling subroutine: $var = prompt("string");
    
    my($string) = $_[0];#shift;
    my($default) = $_[1];
    
    my($input) = "";
    
    $input=$term->readline("* $string");
    # if not readline support, uncomment these:
    # print ("* ".$string."\n");
    # chomp($input = <STDIN>);

    return $input;
}
