#!/usr/bin/perl -w
# $Revision: 1.8 $
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
use File::Spec::Functions qw/ splitdir catdir catfile / ;  # abs2rel() and other dir/filename specific
#use File::Copy;
use File::Find;     # find();
use File::Basename; # basename() && dirname()
#use FileHandle;     # for progressbar

use MP3::Tag;

my $MUSIC_FILES = '\.(mp3|ogg)$'; # files we will find

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
    print STDOUT "file\t$FILE\n";
    foreach(@tags)
    {
        print STDOUT ($_, "\t", $hashref->{$_}, "\n");
    }
    my ($track,$garbage) = split(/\//,$hashref->{'track'});
    $FILE =~ m/(\.[a-zA-Z0-9]{1,5})$/; # catches the extension in $1
    print STDERR ("DEBUG: EXT $1\n") if ( $DEBUG );
    my $path = lc( catdir($hashref->{'artist'},$hashref->{'album'}) );
    my $file = lc( catfile($path,$track."-".$hashref->{'song'}.$1) );
    print STDOUT ("to file\t$file\n");
    if ( ! -f "$file" )
    {
        print STDERR ("DEBUG: use path $path\n") if ( $DEBUG );
        _mkdir($path) if ( ! -d "$path" );
        if ( ! rename ( "$FILE","$file" ) )
        {
            print STDOUT ("Renaming $FILE to $file failed. Do you have permissions to write in $path?\n");
        }
    } else {
        print STDOUT ("$FILE skipped ... $file already exist.\n");
    }
}

# @desc implements `mkdir -p`
sub _mkdir
{
    my $path = shift;
    my @dirs = splitdir($path);
    my $last = "";
    my $flag=1;
    foreach (@dirs)
    {
        next if ( $_ =~ m/^\s*$/ );
        $last = ( $flag > 1 ) ? catdir($last,$_) : $_ ;
        mkdir ($last) if ( ! -d $last);
        $flag++;
    }
    return $flag; # number of directories created
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

