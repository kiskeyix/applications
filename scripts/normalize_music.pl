#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@gmail.com >
# Last modified: 2004-Dec-07
#
# DESCRIPTION: A simple script to rename Music files in a consistent manner
# USAGE: cd ~/Music; normalize_music.pl
# LICENSE: GPL

use strict;
$|++;

my $revision = "1.0"; # version

# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');
use POSIX;                  # cwd() ... man POSIX
use File::Spec::Functions;  # abs2rel() and other dir/filename specific
#use File::Copy;
use File::Find;     # find();
use File::Basename; # basename() && dirname()
#use FileHandle;     # for progressbar

use MP3::Tag;

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;

my $FILE;

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
) and $FILE = shift;

if ( $HELP ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file(File::Spec->catfile("$0"),
			   \*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }

my @tags = ('song','track','artist','album');

if ( -f $FILE )
{
    my $mp3 = MP3::Tag->new($FILE);
    my $hashref = $mp3->autoinfo();
    foreach(@tags)
    {
        print STDOUT ($_, "\t", $hashref->{$_}, "\n");
    }

#    $mp3->get_tags();
#    my $id3v2 = $mp3->{ID3v2} if exists $mp3->{ID3v2};
#    if ( defined ( $id3v2 ) )
#    {
#        my $frameIDs_hash = $id3v2->get_frame_ids;
#        foreach my $frame (keys %$frameIDs_hash) {
#            my ($info, $name) = $id3v2->get_frame($frame);
#            if (ref $info) {
#                print "$name ($frame):\n";
#                while(my ($key,$val)=each %$info) {
#                    print " * $key => $val\n";
#                }
#            } else {
#                print "$name: $info\n";
#            }
#        }
#    } else {
#        print STDERR "$FILE does not have id3v2 tags\n";
#    }
}

sub _mp3_info
{
    my $handle = shift;
    my %record = ();

    $record{"song"} = $handle->song();
    $record{"track"} = $handle->track();
    $record{"artist"} = $handle->artist();
    $record{"album"} = $handle->album();

    return \%record;
}

__END__

=head1 NAME

normalize_music.pl - normalize_music script for Perl by Luis Mondesi <lemsx1@gmail.com>

=head1 SYNOPSIS

B<normalize_music.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]

=head1 DESCRIPTION 

This script finds all music files in a given directory and renames them according to the tags found in them. Renaming is consistent with iTunes naming convention with minor additions:
    Artist/Album/track-song_name-artist.$ext

=head1 OPTIONS

=over 8

=item -v,--version

prints version and exits

=item -D,--debug

enables debug mode

=item -h,--help

prints this help and exits

=cut

