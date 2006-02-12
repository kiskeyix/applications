#!/usr/bin/perl -w
# $Revision: 1.27 $
# $Date: 2006-02-12 05:10:11 $
#
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A simple script to rename Music files in a consistent manner
# USAGE: cd ~/Music; normalize_music.pl or simply: $0 --help
# LICENSE: GPL

use strict;
$|++;

my $revision='$Revision: 1.27 $'; # version
$revision =~ s/(\\|Revision:|\s|\$)//g;

# standard Perl modules
use utf8;
use Getopt::Long;
Getopt::Long::Configure('bundling');
use File::Spec::Functions qw/ splitdir catdir catfile / ;  # abs2rel() and other dir/filename specific
use File::Find;     # find();
use File::Basename; # basename() && dirname()
#use FileHandle;     # for progressbar

my $got_ogg = 0;
my $got_mp3 = 0;

eval "use MP3::Tag";
if ( not $@ )
{
    $got_mp3 = 1;
}

eval "use Ogg::Vorbis::Header::PurePerl";
if ( not $@ )
{
    $got_ogg = 1;
}

die("We need Ogg::Vorbis::Header::PurePerl or MP3::Tag installed\n") 
    if (not $got_ogg and not $got_mp3);

# Globals (no need to change any variables @see $0 --help)
my $MUSIC_FILES = '\.(mp3|ogg)$'; # files we will find
my @TAGS = ('song','track','artist','album');

my @ls=();

# allows for removing dirs
my @ls_dirs=();
my $longest_path = 0;

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;
my $VERBOSE=0;
my $SHOW_DUPS=0;
my $REMOVE_EMPTY_DIRS=0; 
my $REMOVE_DUPS=0; 
my $FILE=undef;

# get options
GetOptions(
    # flags
    'v|version'             =>  \$PVERSION,
    'h|help'                =>  \$HELP,
    'D|debug'               =>  sub { $DEBUG++; $VERBOSE++; $SHOW_DUPS++; },
    'V|verbose'             =>  sub { $VERBOSE++; $SHOW_DUPS++; },
    'S|show-duplicates'     =>  \$SHOW_DUPS,
    'R|remove-empty-dirs'   =>  \$REMOVE_EMPTY_DIRS,
    'r|remove-duplicates'   =>  sub { $REMOVE_DUPS++; $SHOW_DUPS++; },
    # strings
    #'o|option=s'           =>  \$NEW_OPTION,
    # numbers
    #'a|another-option=i'   =>  \$NEW_ANOTHER_OPTION,
) and $FILE = shift;

if ( $HELP ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file($0,\*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision,"\n"); exit 0; }

# main
umask(0022); # fix anal permissions

if ( defined ($FILE) and $FILE !~ /^\s*$/ )
{
    die ("No such file $FILE\n") if ( not -f $FILE );
    my $err = _rename($FILE);
    print STDERR ("$err\n") if ( $VERBOSE );
    # if we were passed more files from the command line, do those as well:
    foreach ( @ARGV )
    {
        next if ( ! -f $_ );
        my $err = _rename($_);
        print STDERR ("$err\n") if ( $VERBOSE );
    }
} else {
    # if we were passed a directory name, use it, else defaults to current directory
    my $_root = ( $FILE !~ /^\s*$/ and -d $FILE ) ? $FILE : ".";
    # are we running from Nautilus?
    # Get Nautilus current working directory, if under Natilus:
    if ( exists $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} 
        and $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} =~ m#^file:///# ) 
    {
        $_root = $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'};
        $_root =~ s#%([0-9A-Fa-f]{2})#chr(hex($1))#ge; # fixes %20 and other URL thingies
        $_root =~ s#^file://##g;
    }
    chdir($_root) or die ("Could not change to directory $_root. $!\n"); 
    my $aryref = do_file_ary(".");
    foreach(@$aryref)
    {
        my $err = _rename($_);
        print STDOUT ($err,"\n") if ( $DEBUG or $VERBOSE );
    }
    _remove_empty_dirs() if ($REMOVE_EMPTY_DIRS > 0);
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
    # remove empty dirs before we rename files (in case there is no files in this)
    if ($REMOVE_EMPTY_DIRS > 0 and -d $_)
    {
        my @_dirs = splitdir($_);
        $longest_path = ($#_dirs > $longest_path) ? ($#_dirs+1) : $longest_path;
        push(@ls_dirs,$_);
        return;
    }
    push (@ls,$_) if ( $_ =~ m($MUSIC_FILES)i and -f $_ );
}

sub _remove_empty_dirs
{
    # removes all empty directories from our list of dirs
    # you have to do $longest_path number of passes using rmdir() 
    # to get them all
    for (my $i=0;$i<$longest_path;$i++)
    {
        for (my $j=0;$j<$#ls_dirs;$j++)
        {
            warn("removing dir $ls_dirs[$j]\n") if ($DEBUG);
            rmdir($ls_dirs[$j]) and
            splice(@ls_dirs,$j,1); # remove this item from our array
        }
    }
}

sub _mkdir
{
    # @desc implements `mkdir -p`
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
    my ($_name,$_path,$_suffix) = fileparse($orig_filename,('\.mp3','\.ogg'));
    my $hashref = undef;
    # deal with ogg files
    if ( $_suffix eq ".ogg" )
    {
        my $ogg = Ogg::Vorbis::Header::PurePerl->new($orig_filename);
        foreach my $k ($ogg->comment_tags) {
            foreach my $v ( $ogg->comment($k) )
            {
                $hashref->{lc($k)} = $v;
                $hashref->{'song'} = $v if ( lc($k) eq 'title' );
            }
        } 
    } elsif ( $_suffix eq ".mp3" ) {
        # deal with mp3 files
        no warnings;
        my $mp3 = MP3::Tag->new($orig_filename);
        $hashref = $mp3->autoinfo();
    } else {
        print STDERR ("Unknown fileformat for $orig_filename\n");
        return "";
    }
    print STDOUT ("_"x69,"\n") if ( $VERBOSE );
    print STDOUT ("file\t$orig_filename\n") if ( $VERBOSE );
    if ( $DEBUG )
    {
        use Data::Dumper;
        print Dumper($hashref);
    }
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
    my $path = lc( catdir($hashref->{'artist'},$hashref->{'album'}) );
    my $new_filename = lc( catfile($path,$track."-".$hashref->{'song'}.$_suffix) );
    print STDOUT ("to file\t$new_filename\n") if ( $VERBOSE );
    # silently bail out if we have done this file before
    $orig_filename =~ s,^(\./|\.),,;
    if ( $new_filename eq $orig_filename )
    {
        print STDERR ("Skipping filename: same file ...\n") if ($DEBUG);
        return "";
    }
    if ( -f $new_filename )
    {
        print STDERR ("New filename already exist ...\n") if ($DEBUG);
        print STDOUT ("DUP:\t$orig_filename\t$new_filename\n") if ( $SHOW_DUPS );
        unlink($orig_filename) if ( $REMOVE_DUPS );
        return "";
    }
    # make the path where we will be putting our new_filename
    _mkdir($path) if ( ! -d $path );
    if ( ! rename ( $orig_filename,$new_filename ) )
    {
        print STDOUT ("Renaming $orig_filename to $new_filename failed. Do you have permissions to write in $path?\n");
        return "";
    }
}

__END__

=head1 NAME

normalize_music.pl - a simple mp3/ogg file renaming script

=head1 SYNOPSIS

B<normalize_music.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                [-V,--verbose]
                [-S,--show-duplicates]
                [-R,--remove-empty-dirs]
                [-r,--remove-duplicates]
                [[directory] | [file1 [file2] [...]]]

=head1 DESCRIPTION 

This script finds all music files in a given directory and renames them according to the tags found in them. Renaming is consistent with iTunes naming convention with minor additions:
    Artist/Album/track-song_name-artist.$ext

If a directory name is given as argument, then it will rename music files found in that path, otherwise the current directory is used.

If a file name is given as argument, or more a series of files, only those files will be processed.

=head1 EXAMPLES

cd /path/to/dir && normalize_music.pl

normalize_music.pl /path/to/dir

normalize_music.pl file.ogg file.mp3 ...

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

print files which have the same id3 tags but on different locations. The lines will be prefix with "DUP:"

=item -R,--remove-empty-dirs

removes empty directories found in given path

=item -r,--remove-duplicates

removes duplicate files. This option implies --show-duplicates. Backup your files first. Be extra careful with this option! Use --show-duplicates to know what will be deleted.

=back

=head1 AUTHORS

Luis Mondesi <L<lemsx1@gmail.com>>

=cut

