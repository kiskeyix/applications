#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: prints character that represents hex number
# USAGE: $0 [--url-encode|--url-decode] string
# LICENSE: GPL

use strict;
$|++;

my $revision = "1.0"; # version

# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;
my $URL_ENCODE=0;
my $URL_DECODE=0;

# get options
GetOptions(
    # flags
    'v|version'         =>  \$PVERSION,
    'h|help'            =>  \$HELP,
    'D|debug'           =>  \$DEBUG,
    'e|url-encode'      =>  \$URL_ENCODE,
    'd|url-decode'      =>  \$URL_DECODE
    # strings
    #'o|option=s'       =>  \$NEW_OPTION,
    # numbers
    #'a|another-option=i'      =>  \$NEW_ANOTHER_OPTION,
) and $STR = shift;

if ( $HELP or ! defined ($STR) ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file($0,\*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }

unless ( $URL_DECODE || $URL_ENCODE )
{
    # single hex char
    print pack("c",hex($STR)),"\n";
    exit 0;
}

print urldecode($STR),"\n" if ( $URL_DECODE );
print urlencode($STR),"\n" if ( $URL_ENCODE );

# FUNCTIONS #

sub urlencode
{
    my $str = shift;
    return "" if ( !defined($str) );
    $str =~ s/(\W)/"%".unpack("H2", $1)/ge;
    return $str;
}

sub urldecode
{
    my $str = shift;
    return "" if ( !defined($str) );
    $str =~ tr/+/ /;
    $str =~ s/%([a-f0-9][a-f0-9])/pack("c",$1)/egi;
    return $str;
}

__END__

=head1 NAME

print_hex.pl - print_hex script for Perl by Luis Mondesi <lemsx1@gmail.com>

=head1 SYNOPSIS

B<print_hex.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                [-e,--url-encode]
                [-d,--url-decode]
                string

=head1 DESCRIPTION 

    This script prints the char value of a given hex code (ASCII). Usefull as a urldecode or for simply printing a string out of hex numbers.

=head1 OPTIONS

=over 8

=item -v,--version

prints version and exits

=item -D,--debug

enables debug mode

=item -h,--help

prints this help and exits

=item -e,--url-encode

encodes string strange characters to HTML friendly %00-%FF

=item -d,--url-decode

decodes string of HTML friendly %00-%FF characters to regular strings

=back

=cut

