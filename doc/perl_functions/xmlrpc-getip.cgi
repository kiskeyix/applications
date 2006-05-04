#!/usr/bin/perl -w
# Luis Mondesi <luis.mondesi@americanhm.com> 
# 2006-05-04 12:50 EDT 
#
# See files: xmlrpc-sendip, newip-dhclient-script
use strict;
$|++;

use lib '/usr/local/lib/site_perl';

use XMLRPC::Transport::HTTP;

my $daemon = XMLRPC::Transport::HTTP::CGI
                ->dispatch_to('Host')
                ->handle();

package Host;

my $DEBUG=0;

use File::Basename qw/ basename /;

# returns the same string that was sent to itself
sub echoString
{
    my $self = shift;
    my $string = shift;
    return $string;
}

# writes local log file
sub writeLog
{
    my $self = shift;
    my $str = shift;

    return undef if ( not defined $str or not $str );
}

# creates tmp host file with all values in hashref 
#"/tmp/newip-dhclient-script-".basename($hostref->{'hostname'});
sub newIP
{
    my $self = shift;
    my $hostref = shift;

    return undef if ( not defined $hostref or not $hostref );

    my $file = "/tmp/newip-dhclient-script-".basename($hostref->{'hostname'});
    open(FILE,">$file") 
        or die("Could not create file $file. $!");
    foreach my $var (keys %$hostref)
    {
        print FILE ("#VAR#",$var,"=",$hostref->{$var},"\n");
    }
    print FILE ($hostref->{'new_ip_address'}," ",$hostref->{'hostname'},"\n");
    close(FILE);
    return 0;
}

