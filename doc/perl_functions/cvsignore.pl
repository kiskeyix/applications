#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@gmail.com >
# Last modified: 2005-Jan-23
#
# DESCRIPTION:
# USAGE:
# CHANGELOG:
# LICENSE: ___

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
my $DEBUG=0;
# get options
GetOptions(
    # flags
    'v|version'         =>  \$PVERSION,
    'h|help'            =>  \$HELP,
    'D|debug'           =>  \$DEBUG,
    # strings
    #'o|option=s'       =>  \$NEW_OPTION,
    # numbers
    #'a|another-option=i'      =>  \$NEW_ANOTHER_OPTION,
);

if ( $HELP ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file(File::Spec->catfile("$0"),
			   \*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }

open(IGNORE,"< cvsignore");
my $basename = "";
my $dirname = "";
#my $file = "";

while (<IGNORE>)
{
    $basename = basename($_);
    $dirname = dirname($_);
    open(CVSIGNORE,">> $dirname/.cvsignore");
    print CVSIGNORE "$basename";
    close(CVSIGNORE);
}

close(IGNORE);

__END__

=head1 NAME

skeleton.pl - skeleton script for Perl by Luis Mondesi <lemsx1@gmail.com>

=head1 SYNOPSIS

B<skeleton.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]

=head1 DESCRIPTION 

    This script ...

=head1 OPTIONS

=over 8

=item -v,--version

prints version and exits

=item -D,--debug

enables debug mode

=item -h,--help

prints this help and exits

=cut
