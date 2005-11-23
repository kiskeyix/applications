#!/usr/bin/perl -w
# $Revision: 1.2 $
# $Date: 2005-11-23 19:31:29 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION:
# USAGE:
# LICENSE: ___

=pod

=head1 NAME

skeleton.pl - skeleton script for Perl

=head1 DESCRIPTION 

    This script ...

=cut

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

#eval "use My::Module";
#if ($@) 
#{
#    print STDERR "\nERROR: Could not load the Image::Magick module.\n" .
#    "       To install this module use:\n".
#    "       Use: perl -e shell -MCPAN to install it.\n".
#    "       On Debian just: apt-get install perlmagic \n\n".
#    "       FALLING BACK to 'convert'\n\n";
#    print STDERR "$@\n";
#    exit 1;
#}

# Args:
my $PVERSION=0;
my $HELP=0;
my $USAGE=0;
my $DEBUG=0;

=pod

=head1 SYNOPSIS

B<skeleton.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                [-U,--usage]

=head1 OPTIONS

=over 8

=item -v,--version

Prints version and exits

=item -D,--debug

Enables debug mode

=item -h,--help

Prints this help and exits

=item -U,--usage

Prints usage information and exits

=back

=cut

# get options
GetOptions(
    # flags
    'v|version'         =>  \$PVERSION,
    'h|help'            =>  \$HELP,
    'D|debug'           =>  \$DEBUG,
    'U|usage'           =>  \$USAGE,
    # strings
    #'o|option=s'       =>  \$NEW_OPTION,
    # numbers
    #'a|another-option=i'      =>  \$NEW_ANOTHER_OPTION,
);

if ( $HELP ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file($0,\*STDOUT);
    exit 0;
}

if ( $USAGE ) { 
    use Pod::Usage;
    pod2usage(1);
    exit 0; # never reaches here
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }

print "sample";

=pod

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut
