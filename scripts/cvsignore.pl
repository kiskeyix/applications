#!/usr/bin/perl -w
# $Revision: 1.4 $
# Luis Mondesi < lemsx1@gmail.com >
# Last modified: 2005-Jan-23
#
# DESCRIPTION: creates .cvsignore files per directory from a list of file paths (cvs update output: ? path/to/file_to_ignore)
# USAGE: cvs update | cvsignore.pl
# LICENSE: GPL

use strict;
$|++;

my $revision = "1.0"; # version

# standard Perl modules
use File::Basename; # basename() && dirname()
use Getopt::Long;
Getopt::Long::Configure('bundling');

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;
## get options
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

my $basename = "";
my $dirname = "";

while (<STDIN>)
{
    $basename = basename(clean($_));
    $dirname = dirname(clean($_));
    if ( -d "$dirname" )
    {
        open(CVSIGNORE,">> $dirname/.cvsignore");
        print CVSIGNORE "$basename";
        close(CVSIGNORE);
    }
    # reset
    $basename = "";
    $dirname = "";
}

sub clean
{
    my $str=shift;
    # remove bad characters from filenames
    $str =~ s/^\?//gc;
    return $str;
}

__END__

=head1 NAME

cvsignore.pl - adds filenames to .cvsignore per directory by Luis Mondesi <lemsx1@gmail.com>

=head1 SYNOPSIS

B<cvs update | cvsignore.pl>

=head1 DESCRIPTION 

    This script adds filenames to .cvsignore per directory

=head1 OPTIONS

=over 8

=item -v,--version

prints version and exits

=item -D,--debug

enables debug mode

=item -h,--help

prints this help and exits

=cut

