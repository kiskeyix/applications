#!/usr/bin/perl -w
# $Revision: 1.1 $
# $Date: 2007-01-16 17:50:06 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A simple wget clone in Perl. It's used mostly to download files possibly by passing a username and password to a form
# USAGE: $0 --help
# LICENSE: GPL

use strict;
$|++;

my $revision = "1.0"; # version

# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');
use POSIX;                  # cwd() ... man POSIX
use File::Spec::Functions;  # abs2rel() and other dir/filename specific
use File::Copy;
use File::Find;     # find();
use File::Basename; # basename() && dirname()
use FileHandle;     # for progressbar
# setup a simple "browser/wget"
use LWP::UserAgent;

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;
my $ACTION_URL=undef;
my $UNAME=undef;
my $PASSWD=undef;
# get options
GetOptions(
    # flags
    'v|version'         =>  \$PVERSION,
    'h|help'            =>  \$HELP,
    'D|debug'           =>  \$DEBUG,
    # strings
    'u|username'        =>  \$UNAME,
    'p|password'        =>  \$PASSWD,
    #'g|get=s'           =>  \$GET_FILE
) and $ACTION_URL=shift;

if ( $HELP or !defined($ACTION_URL) ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file($0,\*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }

# main
my $_get = undef;
my $ua = LWP::UserAgent->new;
$ua->agent("AHMWGET/0.1 ");
$ua->timeout(28800); # 8 hours -> 28800
$ua->protocols_allowed( [ 'http', 'https', 'ftp' ] ); # all other yield 500 errors

# check if we are connecting to a form using BASIC AUTH (i.e. realm)
#if ( defined($REALM) )
#{
#    my $netloc = ""; # FIXME
#    $ua->credentials( $netloc, $REALM, $UNAME, $PASSWD )
#}

# create a request for LWP
my $req = HTTP::Request->new('GET' => $ACTION_URL);
my $res = $ua->request($req);

# if our ACTION_URL retrieval fails, die!
if ( !$res->is_success  ) {
    print STDERR ($res->status_line, "\n");
    die ( "Failed to GET $ACTION_URL\n" );
}

# get GET_FILE URL in the output of our ACTION_URL
if ( $res->is_success )
{
    print STDOUT $res->content;
}


__END__

=head1 NAME

wget.pl - wget script for Perl by Luis Mondesi <lemsx1@gmail.com>

=head1 SYNOPSIS

B<wget.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                ACTION_URL

=head1 DESCRIPTION 

    This script attempts to connect to a given ACTION_URL and retrieve a specific file

=head1 OPTIONS

=over 8

=item -v,--version

prints version and exits

=item -D,--debug

enables debug mode

=item -h,--help

prints this help and exits

=item -g,--get

URL to the specific file we want to get. This could be a partial URL name and the script will parse through the ACTION_URL output to find the given URL to be retrieved.

=item ACTION_URL

attempts to connect to an ACTION_URL and retrieve a given file

=back

=cut

