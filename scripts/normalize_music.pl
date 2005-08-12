#!/usr/bin/perl -w
# $Revision: 1.22 $
# $Date: 2005-08-12 13:28:05 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A simple script to rename Music files in a consistent manner
# USAGE: cd ~/Music; normalize_music.pl
# LICENSE: GPL

use strict;
$|++;

my $revision = "1.0"; # version

# standard Perl modules
use utf8;
use Getopt::Long;
Getopt::Long::Configure('bundling');
use POSIX;                  # cwd() ... man POSIX
use File::Spec::Functions qw/ splitdir catdir catfile / ;  # abs2rel() and other dir/filename specific
#use File::Copy;
use File::Find;     # find();
use File::Basename; # basename() && dirname()
#use FileHandle;     # for progressbar

use MP3::Tag;

# Globals (no need to change any variables @see $0 --help)
my $MUSIC_FILES = '\.(mp3|ogg)$'; # files we will find
my @TAGS = ('song','track','artist','album');

my @ls=();

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;
my $VERBOSE=0;
my $SHOW_DUPS=0;

my $FILE=undef;

# get options
GetOptions(
    # flags
    'v|version'             =>  \$PVERSION,
    'h|help'                =>  \$HELP,
    'D|debug'               =>  sub { $DEBUG++; $VERBOSE++; $SHOW_DUPS++; },
    'V|verbose'             =>  sub { $VERBOSE++; $SHOW_DUPS++; },
    'S|show-duplicatets'    =>  \$SHOW_DUPS,

    # strings
    #'o|option=s'       =>  \$NEW_OPTION,
    # numbers
    #'a|another-option=i'      =>  \$NEW_ANOTHER_OPTION,
) and $FILE = shift;

if ( $HELP ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file($0,\*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }

# main
umask(0022); # fix anal permissions

if ( defined ($FILE) and -f $FILE )
{
   my $err =  _rename($FILE);
   print STDOUT ($err,"\n") if ( $DEBUG or $VERBOSE );
   # if we were passed more files from the command line, do those as well:
   foreach ( @ARGV )
   {
       next if ( ! -f $_ );
       $err = "";
       $err = _rename($_);
       print STDOUT ($err,"\n") if ( $DEBUG or $VERBOSE );
   }
} else {
    my $_root = ( -d $FILE ) ? $FILE : "."; # defaults to current directory
    # are we running from Nautilus?
    # Get Nautilus current working directory, if under Natilus:
    if ( exists $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} and $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} =~ m#^file:///# ) 
    {
        $_root = $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'};
        $_root =~ s#%([0-9A-Fa-f]{2})#chr(hex($1))#ge; # fixes %20 and other URL thingies
        $_root =~ s#^file://##g;
    }
    cwd($_root) || die ("Could not change to directory $_root. $!\n"); 
    my $aryref = do_file_ary(".");
    foreach(@$aryref)
    {
        my $err = _rename($_);
        print STDOUT ($err,"\n") if ( $DEBUG or $VERBOSE );
    }
# TODO remove empty directories if --remove-empty-dirs
# HINT: you will have to find the longest path and recursively call something like:
# find . -type d -exec rmdir {} 2> /dev/null \;
# for e/a directory in the longest path... This should be done quickly.
# rmdir pays extra care in NOT unlinking directories that have files in them.
# You could also implement your own version of rmdir ;-)
}

# support functions
sub do_file_ary {
    # uses find() to recur thru directories
    # returns an array of files
    # i.e. in directory "a" with the files:
    # /a/file.txt
    # /a/b/file-b.txt
    # /a/b/c/file-c.txt
    # /a/b2/c2/file-c2.txt
    # 
    # my $aryref = do_file_ary(".");
    # 
    # will yield:
    # a/file.txt
    # a/b/file-b.txt
    # a/b/c/file-c.txt
    # a/b2/c2/file-c2.txt
    # 
    my $ROOT = shift;
    my %opt = (wanted => \&process_file, no_chdir=>1);
    
    find(\%opt,$ROOT);
    return \@ls;
}

sub process_file {
    my $base_name = basename($_);
    if ( 
        $_ =~ m($MUSIC_FILES)i &&
        -f $_
    ) {
        s/^\.\/*//g;
        push @ls,$_;
    }
}

# @desc implements `mkdir -p`
sub _mkdir
{
    my $path = shift;
    my $root = ( $path =~ m,^([/|\\|:]), ) ? $1 : ""; # relative or full path?
    my @dirs = splitdir($path);
    my $last = "";
    my $flag=1;
    foreach (@dirs)
    {
        next if ( $_ =~ m/^\s*$/ );
        $last = ( $flag > 1 ) ? catdir($last,$_) : "$root"."$_" ;
        mkdir ($last) if ( ! -d $last);
        $flag++;
    }
    return $flag; # number of directories created
}

sub _rename
{
    my $orig_filename=shift;
    my $mp3 = MP3::Tag->new($orig_filename);
    my $hashref = $mp3->autoinfo();
    print STDOUT ("_"x69,"\n") if ( $VERBOSE );
    print STDOUT ("file\t$orig_filename\n") if ( $VERBOSE );
    # tracks,artist,album are not that essential:
    #'song','track','artist','album'
    if ( ! defined($hashref->{'track'}) or $hashref->{'track'} =~ m/^\s*$/ )
    {
        $hashref->{'track'}="00/00";
    }
    if ( ! defined($hashref->{'artist'}) or $hashref->{'artist'} =~ m/^\s*$/ )
    {
        $hashref->{'artist'} = "noartist";
    }
    if ( ! defined($hashref->{'album'}) or $hashref->{'album'} =~ m/^\s*$/ )
    {
        $hashref->{'album'} = "noalbum";
    }
    foreach(@TAGS)
    {
        return "\n*** $_ tag missing for file '$orig_filename'\nBailing out\n" 
            if ( ! defined($hashref->{$_}) or $hashref->{$_} =~ m/^\s*$/ );
        # clean chars that might not be good for filenames
        #ñ|á|é|í|ó|ú|
        $hashref->{$_} =~ s/([^[:alnum:]\!\@\*\#\%\(\)\[\]\_\-\:\,\.\'\"\{\}\=\+ ])//gi;
        print STDOUT ($_, "\t", $hashref->{$_}, "\n") if ( $VERBOSE );
    }
    my ($track,$garbage) = split(/\//,$hashref->{'track'});
    $track =~ s/^(\d{1,2}).*$/$1/g;
    $orig_filename =~ m/(\.[a-zA-Z0-9]{1,5})$/; # catches the extension in $1
    print STDERR ("DEBUG: EXT $1\n") if ( $DEBUG );
    my $path = lc( catdir($hashref->{'artist'},$hashref->{'album'}) );
    my $new_filename = lc( catfile($path,$track."-".$hashref->{'song'}.$1) );
    print STDOUT ("to file\t$new_filename\n") if ( $VERBOSE );
    # silently bail out if we have done this file before
    if ( $new_filename eq $orig_filename )
    {
        return;
    }
    if ( ! -f $new_filename )
    {
        print STDERR ("DEBUG: use path $path\n") if ( $DEBUG );
        _mkdir($path) if ( ! -d "$path" );
        if ( ! rename ( $orig_filename,$new_filename ) )
        {
            print STDOUT ("Renaming $orig_filename to $new_filename failed. Do you have permissions to write in $path?\n");
            return;
        }
    } else {
        print STDOUT ("$orig_filename is a duplicate of $new_filename\n")
            if ( $SHOW_DUPS );
    }
}

__END__

=head1 NAME

normalize_music.pl - normalize_music script for Perl by Luis Mondesi <lemsx1@gmail.com>

=head1 SYNOPSIS

B<normalize_music.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                [-V,--verbose]
                [-S,--show-duplicates]

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

=item -V,--verbose

print all tags about each file

=item -S,--show-duplicates

print files which have the same id3 tags but on different locations

=cut

