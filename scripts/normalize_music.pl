#!/usr/bin/perl -w
# $Revision: 1.14 $
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

my $FILE=undef;

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

#main
if ( defined ($FILE) and -f $FILE )
{
   print STDERR _rename($FILE),"\n";  # print error if any
} else {
    my $aryref = do_file_ary(".");
    foreach(@$aryref)
    {
        print STDERR _rename($_),"\n";
    }
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

sub _rename
{
    my $this_file=shift;
    my $mp3 = MP3::Tag->new($this_file);
    my $hashref = $mp3->autoinfo();
    no warnings;
    print STDOUT ("_"x69,"\n");
    print STDOUT "file\t$this_file\n";
    # tracks,artist,album are not that essential:
    #'song','track','artist','album'
    if ( $hashref->{'track'} =~ m/^\s*$/ )
    {
        $hashref->{'track'}="00/00";
    }
    if ( $hashref->{'artist'} =~ m/^\s*$/ )
    {
        $hashref->{'artist'} = "noartist";
    }
    if ( $hashref->{'album'} =~ m/^\s*$/ )
    {
        $hashref->{'album'} = "noalbum";
    }
    foreach(@TAGS)
    {
        return "$_ missing. Bailing out" if ( $hashref->{$_} =~ m/^\s*$/ );
        # clean chars that might not be good for filenames
        $hashref->{$_} =~ s/[^ραινσϊ\w\d\!\@\*\#\%\(\)\[\]\_\-\:\,\.\'\"\{\}\=\+\ ]//gi;
        print STDOUT ($_, "\t", $hashref->{$_}, "\n");
    }
    my ($track,$garbage) = split(/\//,$hashref->{'track'});
    $track =~ s/^(\d{1,2}).*$/$1/g;
    $this_file =~ m/(\.[a-zA-Z0-9]{1,5})$/; # catches the extension in $1
    print STDERR ("DEBUG: EXT $1\n") if ( $DEBUG );
    my $path = lc( catdir($hashref->{'artist'},$hashref->{'album'}) );
    my $file = lc( catfile($path,$track."-".$hashref->{'song'}.$1) );
    print STDOUT ("to file\t$file\n");
    # silently bail out if we have done this file before
    return "" if ( $file eq $this_file );
    if ( ! -f "$file" )
    {
        print STDERR ("DEBUG: use path $path\n") if ( $DEBUG );
        _mkdir($path) if ( ! -d "$path" );
        if ( ! rename ( "$this_file","$file" ) )
        {
            print STDOUT ("Renaming $this_file to $file failed. Do you have permissions to write in $path?\n");
        }
    } else {
        print STDOUT ("$file skipped\n"); # we'll never reach here
    }
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

