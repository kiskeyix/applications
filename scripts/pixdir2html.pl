#!/usr/bin/perl 
# $Revision: 1.41 $
# Luis Mondesi  <lemsx1@hotmail.com> 2002-01-17
# 
# USAGE: 
#       SEE HELP:
#           pixdir2html.pl --help
#
#       For the Impatient:
#           pixdir2html.pl . # passes current directory to script as root
#                            # this is assumed by default
#                            
#           pixdir2html.pl -f # force copies the root/.pixdir2htmlrc
#                             # to all other directories within this tree
#           pixdir2html.pl --menuonly # generates a menu.$EXT file only
#                                     # see "menuheader_footer" var
#                                     # in case you don't want headers/
#                                     # footers in that file (as if
#                                     # that file is a .php and will
#                                     # be included in other files...
#                                     # or if you don't want menus in the
#                                     # html files created
#                                     # set to 0: no menus whatsoever
#
# DESCRIPTION:
# 
# Use this non-interactive script in Nautilus to create HTML files
# with their proper thumbnails for pictures (.jpeg, .gif or .png)
# 
# Make this file executable and put it in:
# ~/.gnome/nautilus-scripts
# or 
# ~/.gnome2/nautilus-scripts
# 
# Then run it from from the File::Scripts::script_name menu in Nautilus
# 
# You could customize each directory differently by having a
# file named .pixdir2htmlrc in the directory containing the
# pictues. This file has the form:
# 
# uri=http://absolute.path.com/images # must be absolute. no trailing /
# header=
# percent=30% #size of the thumbnails for this folder
# title=
# meta=
# stylesheet=
# html_msg=<h1>Free form using HTML tags</h1> 
# body=<body bgcolor='#000000'>
# p=<p>
# table=<table border='0'>
# td=<td valign='left'>
# tr=<tr>
# new=http://absolute.path.com/images/new.png # for dirs with .new files
# footer=<a href='#'>A footer here</a>
# # set this to 1 to avoid printing a header
# # or footer in the menu file menu.$EXT
# menuheader_footer=0
# ext=php
# 
# These are the only tags that you can customize for now :-)
#
# If you don't create a file, a sample will be done for you
# at the root level of the directory from which you execute
# this script.
#
# REQUIRED: ImageMagick's Perl module and it's dependancies
#
# TODO:
#   * read TODO scatter thru the script...
#   * clean() function to cleanup all files created by this script
#     HINT: 
#     find . -name "[$LOGFILE*|*.$EXT|$html_dir|$thumbnails_dir]" -exec rm -fr {} \;
#   * internationalization of strings
#   * test in windows or other non-unix that run Perl
#
# BUGS:
#   * config file should not contain double quotes (") without
#     escaping them first (\")
# 
# TIPS:
# 
# Put a .nopixdir2htmlrc file in directories for which you do not want
# thumbnails and/or index.$EXT to be written
#

# standard modules
use strict;
use vars qw( $VERSION @INC );
use Config;

use Getopt::Long;
Getopt::Long::Configure('bundling');

use File::Copy;
use File::Find;     # find();
use File::Basename; # basename();

# for progressbar
use FileHandle;

# non-standard modules:
eval "use Image::Magick";
if ($@) 
{
    print STDERR "\nERROR: Could not load the Image::Magick module.\n" .
    "       Please install this module before continuing\n".
    "       Use: perl -e shell -MCPAN to install it.\n".
    "       On Debian just: apt-get install perlmagic \n\n";
    exit 1;
}
# TODO else use "convert" if found

# borrowed ideas from UDPM.pm for the progressbar.
# didn't use it because it's too bloated for what
# I needed, and it created an extra module that
# users would have to install... nice work though
#
#eval "use UDPM";

# end of loading needed modules

my $VERSION="1.4";

$|++; # disable buffer (autoflush)

my $USAGE = "pixdir2html.pl [-n|--nomenu] 
[-N|--noindex]
[-f|--force] 
[-M|--menuonly]
[-E|--extension] (php)
[-t|--thumbsonly]
[-D|--directory] (.)
[-l|--menulinks]
[-h|--help]

force    - creates a .pixdir2htmlrc in every subdir overriding
any file with that name
nomenu   - do not create menu file after finishing creating thumbnails
noindex  - do not create the index.EXT files after creating thumbnails
menuonly - only create a menu file and exit
menulinks- number of links to put in the Menu per row. Default is 10
extension- use this extension instead of default (php)
directory- use this directory instead of default (current)
menu_td  - How many cells in menu?
td       - How many cells in e/a file
str_limit- What's the size of the longest string allowed in menus?
help     - prints this help and exit\n

e.g.
cd /path/to/picture_directory
pixdir2html --extension='html'

is the same as:
pixdir2html -E html

";

# Get Nautilus current working directory, if under Natilus:

my $nautilus_root = "";

if ( exists $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} 
    && $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} =~ m#^file:///# 
) 
{
    ($nautilus_root = $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} ) =~ s#%([0-9A-Fa-f]{2})#chr(hex($1))#ge;
    ($nautilus_root = $nautilus_root ) =~ s#^file://##g;
}

my $ROOT_DIRECTORY= ( -d $nautilus_root ) ? $nautilus_root : ".";
my $LOG="$ROOT_DIRECTORY/pixdir2html.log";
my $CONFIG_FILE=".pixdir2htmlrc";
my $THUMBNAIL="t";  # individual thumnails files will be placed here
my $HTMLDIR="h";    # individual HTML files
my $EXT="php";     # default extension for generated HTML files
my $THUMB_PREFIX = "t"; # no need to ever change this... this starts
# the name for all thumbnail images

# list directories that should be skipped here
# separated by |
my $EXCEPTION_LIST = "CVS|RCS";
# regex of files we want to include
my $EXT_INCL_EXPR = "\.(jpg|png|jpeg|gif)";
# How big are the thumbnails?
# This is the default, in case the config file
# doesn't exist or do not have this item in it
my $PERCENT="20%";
# How many TDs per table in e/a index.EXT?
my $TD=4;
# How many TDs per menu table?
my $menu_td=10;
# How big are strings in menus?
my $STR_LIMIT = 32;

# dont worry if you don't have a log rotation facility...
# just leave it as is
my $SAVELOG = "/usr/bin/savelog";

###Nothing below this line should need to be configured.###
#**************************************************************#

my @pixdir = (); # for menu
my @pixfile = (); # for thumbfiles/pictures
my %myconfig = (); # init config hash
my $total_directories=0;
my $total_links=0;
my $FORCE=0; 
my $NOMENU=0; 
my $MENUONLY=0;
my $THUMBSONLY=0;
my $NOINDEX=0;
my $HELP=0;
# progressbar stuff here:
# initialization:
my $GAUGE = new FileHandle;

#my $tty = qx/tty/; # this returns text from system("tty")
my $MODE = "text";
my $DIA = "";

# xdialog is a better implementation than gdialog
# thus, if we find that, we use that first
# else, we try an alternate name
# TODO make sure this works in different systems/shells
# Go thru the PATH variable and finding the binaries:
# (this might not work on some systems...)
my @xbinaries = ("Xdialog","xdialog","gdialog","kdialog");
my @binaries = ("dialog","whiptail","cdialog"); 
my $FOUND = 0; # flag
foreach my $path ( split(/:/,$ENV{"PATH"}) )
{
    next if ( $FOUND == 1 );
    if ( exists $ENV{"NAUTILUS_SCRIPT_CURRENT_URI"} )
    {
        $MODE = "x";
        foreach my $binary ( @xbinaries ) {
            next if ( $FOUND == 1 );
            if ( -x "$path/$binary" ) {
                $DIA = "$path/$binary";
                # gets out of these loops
                $FOUND = 1; 
            }
        } # end foreach @xbinaries
    } else {
        $MODE = "text";
        foreach my $binary ( @binaries ) {
            next if ( $FOUND == 1 );
            if ( -x "$path/$binary" ) {
                $DIA = "$path/$binary";
                $FOUND = 1; 
            }
        } # end foreach @binaries
    } # end if NAUTILUS_SCRIPT_CURRENT_URI
} # end foreach $PATH

# make sure DIA is set or exit abnormally
if ( $MODE eq "x" ) {
    if ( $DIA eq "" ) { 
        # error
        print STDERR ("Graphical Dialog was not found.\n");
        print STDERR ("Please install any of these programs:\n");
        print STDERR join(" ",@xbinaries)."\n";
        exit 1;
    }
} elsif ( $MODE eq "text" ) 
{
    if ( $DIA eq "" ) {
        # error
        print STDERR ("Console Dialog was not found.\n");
        print STDERR ("Please install any of these programs:\n");
        print STDERR join(" ",@binaries)."\n";
        exit 1;
    }
}

# get options
GetOptions(
    # flags
    'n|nomenu'      =>  \$NOMENU,
    'f|force'       =>  \$FORCE,
    'h|help'        =>  \$HELP,
    'M|menuonly'    =>  \$MENUONLY,
    't|thumbsonly'  =>  \$THUMBSONLY,
    'N|noindex'     =>  \$NOINDEX,
    'l|menulinks=i' =>  \$menu_td,
    # strings
    'E|extension=s' =>  \$EXT,
    'D|directory=s' =>  \$ROOT_DIRECTORY,
    # numbers
    'menu_td=i'     =>  \$menu_td,
    'td=i'          =>  \$TD,
    'str_limit=i'   =>  \$STR_LIMIT 
);

die $USAGE if $HELP;

my $FILE_NAME="index";
my $MENU_NAME="menu";
my $menu_str="";

my $LOGFILE = new FileHandle;

my $THUMBNAILSDIR="$ROOT_DIRECTORY/$THUMBNAIL";
my $HTMLSDIR="$ROOT_DIRECTORY/$HTMLDIR";

warn << "__EOF__";
Perl pixdir2html v$VERSION 
(Luis Mondesi <lemsx1\@hotmail.com> / LatinoMixed.com) 
(running with Perl $] on $Config{'archname'}) \n \n
__EOF__


main();

#-------------------------------------------------#
#                     FUNCTIONS                   #
#-------------------------------------------------#
sub main {
    
    $LOGFILE->open("> $LOG");
    $LOGFILE->autoflush(1);
   
    # for now --clear is the same for all dialogs:
    # ( $MODE eq "x" ) ? " --clear ": 
    my $ARGS = " --clear ";

    $GAUGE->open("| $DIA $ARGS --backtitle 'Picture Directory to HTML' --title 'Picture Progress' --gauge 'Thumbnails Creation' 8 70 0 2>&1");
    $GAUGE->autoflush(1);

    # which progressbar are we using?
    print $LOGFILE ("Mode $MODE\n");

    # are we creating a menu file only?
    if ( $MENUONLY > 0 ) {
        print $LOGFILE ("= Creating menu file\n");
        menu_file();
        return 0;
    }

    print $LOGFILE "= Start directory $ROOT_DIRECTORY \n";

    if ( ! -f "$ROOT_DIRECTORY/$CONFIG_FILE" )
    {
        print $LOGFILE ( "Missing main $CONFIG_FILE. Creating one for you \n");
        init_config($ROOT_DIRECTORY,"true");
    }	

    # get menu string
    # TODO
    # this will generate a list of all 
    # directories that don't have a .nopixdir2htmlrc
    # file in them and assume that a index.$EXT file
    # will be created later during this script 
    # execution. I don't like this assumption
    # and will fix this later...
    # For now it just works. This way we get a uniform
    # Menu string for all index files.
    unless ( $NOMENU == 1 ) {
        print $LOGFILE ("= Creating menu string\n");
        $menu_str = menu_file();
    }

    # make all thumbnails and indices
    mkthumb($ROOT_DIRECTORY,$menu_str);

    if ( $THUMBSONLY > 0 ) {
        # this is a quick "dirty" way of getting only
        # thumbnails and their respetive index.html files
        return 0;
    }

    # make all supporting HTML files
    thumb_html_files($ROOT_DIRECTORY);

    # close GAUGE
    #print $GAUGE "\x04";
    #$GAUGE->close();
    eof($GAUGE);
    undef($GAUGE); # this also closes the gauge... but...

    # close log
    print $LOGFILE ("$total_directories directories.\n\n");
    $LOGFILE->close();

    if ( -x $SAVELOG ) {
        system("$SAVELOG $LOG > /dev/null 2>&1");
    }

    return 0;
} # endmain

sub init_config {
    # Takes one argument:
    # ROOT = directory from which we will take the config file   
    my %config_tmp = ();
    my $ROOT = shift;
    my $create_config = shift;
    my $line="";

    # some defaults:
    #
    # it's very important to set this to a 
    # full URI:
    # file:///path/to/root/directory
    # http://www.server.tld/path/to/root/directory
    # where "root directory" is the main dir
    # where all other directories reside (and not
    # the / root filesystem of UNIX/Linux/...).
    # For now, ".." do the trick for a simple
    # tree of directories:
    # ROOT/
    # ROOT/dir_a
    # ROOT/dir_b
    # ROOT/dir_c
    #
    # and not
    # ROOT/
    # ROOT/dir_a/dir_a1/dir_a2
    # ROOT/dir_b ...
    # for which case you will need a full path
    $config_tmp{"uri"}="..";
    $config_tmp{"percent"}=$PERCENT;
    $config_tmp{"title"}="Images";
    $config_tmp{"meta"}="<meta http-equiv='content-type' content='text/html;charset=iso-8859-1'>";
    $config_tmp{"stylesheet"}="<link rel='stylesheet' href='../styles.css' type='text/css'>";
    $config_tmp{"html_msg"}="<h1>Free form HTML</h1>";
    $config_tmp{"body"}="<body bgcolor='#000000' text='#ffffff'>";
    $config_tmp{"p"}="<p>";
    $config_tmp{"table"}="<table border='0'>";
    $config_tmp{"td"}="<td valign='top' align='left'>";
    $config_tmp{"tr"}="<tr>";
    # when header is set, title, meta, stylesheet, etc...
    # are discarded. So do a complete set
    # such as <HTML><head><title>...
    # and close with "footer"
    $config_tmp{"header"}="";
    $config_tmp{"footer"}="";
    $config_tmp{"menuheader_footer"}=0;
    $config_tmp{"ext"}=$EXT;

    if ( -f "$ROOT/$CONFIG_FILE" )
    {
        open(CONFIG, "<$ROOT/$CONFIG_FILE");
        # suppress warnings for now... 
        no warnings; 
        while ( defined($line = <CONFIG>) ) {
            next if /^\s*#/;
            chomp $line;
            # attempts to be forgiven about backslashes
            # to break lines that continues over
            # multiple lines
            if ($line =~ s/\\$//) {
                $line .= <CONFIG>;
                redo unless eof(CONFIG);
            }
            $config_tmp{"$1"} = $2 if ( $line =~ m,^\s*([^=]+)=(.+), );
        }
        close(CONFIG);
    } else {
        warn << "__EOF__";
   Could not find $ROOT/$CONFIG_FILE 
__EOF__
        if ( $create_config =~ /true/ ) 
        {
            if (open(CONFIG, ">$ROOT/$CONFIG_FILE")) {
                foreach my $key ( keys %config_tmp ) {
                    print CONFIG "$key=" . $config_tmp{"$key"}."\n";
                }
            } else {
                print STDERR "Could not write $ROOT/$CONFIG_FILE. Check permissions?";
            }
        }
    }

    #construct a header if it doesn't yet exist:
    if ( exists $config_tmp{"header"} 
        && $config_tmp{"header"} eq "" 
    ) 
    {
        print $LOGFILE (": Blank header. Generating my own [$ROOT] ... \n");
        $config_tmp{"header"}="<html>
        <head>
        ".$config_tmp{"meta"}."
        <title>".$config_tmp{"title"}."</title>
        ".$config_tmp{"stylesheet"}."
        </head>\n".
        $config_tmp{"body"}."
        \n<center>\n".
        $config_tmp{"html_msg"}."
        \n
        ";
    }

    # now ext can be passed in a .pixdir2htmlrc file
    if ( 
        ! exists $config_tmp{"ext"} ||
        $config_tmp{"ext"} eq "" 
    ) {
        $config_tmp{"ext"}=$EXT;
    }
    return %config_tmp;
} # end init_config

sub mkindex {
    # mkindex is a private function called by
    # mkthumb()

    # takes a two-dimensional array in the form:
    # $name{base}->[0] = 'path/file'
    # and does a index file for e/a 'base' of
    # all files referenced 
    my $hashref = $_[0]; # saves the name of the var passed
    # e/a key holds a full array of files
    my $MENU_STR = $_[1]; # a str to be included in e/a file
    my $i = 0;
    my (
        $this_file,
        $this_base
    ) = "";     # holds keys for hash
    my (@files,%myconfig) = ();

    # TODO see why this doesn't work as expected
    foreach $this_base ( sort keys %$hashref ) {
        my ($my_bgcolor,$file_name) = ""; 
        $i = 0;
        # read specific config file for this directory
        if ( -f "$this_base/$CONFIG_FILE" && ! -f "$this_base/.nopixdir2htmlrc" ) {
            %myconfig = init_config($this_base);
        } elsif ( ! -f "$this_base/.nopixdir2htmlrc" ) {
            # oops, missing config... getting base file
            if ( 
                copy("$ROOT_DIRECTORY/$CONFIG_FILE", 
                    "$this_base/$CONFIG_FILE") 
            ) {
                print $LOGFILE (": Copied ".
                    " $ROOT_DIRECTORY/$CONFIG_FILE ".
                    "==> $this_base/$CONFIG_FILE \n");
            }
            # now read the config file
            %myconfig = init_config($this_base);
        }
        
        my @files = @{$$hashref{$this_base}};
        # FILE_NAME is a global
        open(FILE, "> ".$this_base."/".$FILE_NAME.".".$myconfig{"ext"}) || 
        die "Couldn't write file $FILE_NAME.".$myconfig{"ext"}." to $this_base";

        # start HTML
        print FILE ($myconfig{"header"}."\n");
        # print menu (if any)
        print FILE ("$MENU_STR");
        # start table
        print FILE ($myconfig{"table"}."\n");
        #print all picts now
        foreach(@files){
            $this_file = basename($_);
            if ($i == 0) {
                # open a new row
                # this row doesn't need bgcolor
                if ( $myconfig{"tr"} =~ m/\%+bgcolor\%+/i ) {
                    ($myconfig{"tr"} = $myconfig{"tr"}) =~ s/\%+bgcolor\%+//i;
                }
                print FILE ($myconfig{"tr"}."\n");
            } 
            print FILE ("\t".$myconfig{"td"}."\n");
            ($file_name = $this_file) =~ s/$EXT_INCL_EXPR//gi;
            ($file_name = $file_name) =~ s/^$THUMB_PREFIX//; # removes prefix
            # EXT is a global and so is THUMBNAIL
            print FILE ("<a href='$HTMLDIR/$file_name.".$myconfig{"ext"}."'>".
                "<img src='$THUMBNAIL/"."$this_file'></a>\n");
            print FILE ("\t</td>\n");
            if ($i<($TD-1)) {
                $i++;
            } else {
                # wrap and reset counter
                print FILE ("</tr>\n");
                $i = 0;
            }
        } # end for e/a @files
        # complete missing TD
        if ($i != 0) {
            for (;$i<$TD;$i++) {
                print FILE ("\t".$myconfig{"td"}."\n");
                print FILE ("&nbsp;");
                print FILE ("\t</td>\n");
            }
        }
        print FILE ("</tr>\n");
        print FILE ("</table>\n");
        # close the footer if one doesn't exist:
        if ( $myconfig{"footer"} eq "" ) {
            print FILE ("\n</center></body>\n");
            print FILE ("</HTML>\n");
        } else {
            print FILE ($myconfig{"footer"}."\n");
        }
        print FILE ("\n");
        close(FILE);
    } # end for e/a this_base
} # end mkindex

sub mkthumb {
    my $ROOT = $_[0];
    my $MENU_STR = $_[1];
    # locals
    my (@ls,%myconfig,%pixfiles) = ();
    my ($thisFile,
        $pix_name,
        $file_name,
        $next_pix_name,
        $next_file_name,
        $last_pix_name,
        $last_html_file,
        $current_html_file,
        $last_file_name,
        $current_link,
        $last_link,
        $LAST_BASE,
        $NEXT_BASE,
        $HTMLSDIR) = "";
    # these two are special...
    # init to some strange string...
    my $BASE = ",/\trash";
    my $tmp_BASE = ",\/more_trash";
    print $LOGFILE ("= Making thumbnails in $ROOT \n");
    #construct array of all image files
    my @ary = do_file_ary("$ROOT");
    # parse array of images
    foreach (@ary){
        $thisFile = basename($_);
        next if ($thisFile =~ m/$EXCEPTION_LIST/);
        next if ($_ =~ m/\b$THUMBNAIL\b/i);
        next if ($thisFile !~ m/$EXT_INCL_EXPR/i);
        push @ls,$_;
        #$TOTAL++;
    } #end images array creation

    # progressbar stuff
    # gauge message
    my $MESSAGE = "Thumbnails Creation";
    # initial values for gauge
    # TOTAL -> number of elements in ls array
    my ($PROGRESS,$TOTAL) = (0,$#ls);
    progressbar_msg($MESSAGE);

    print $LOGFILE ("= $TOTAL pictures \n");
    foreach(@ls) 
    {
        $pix_name = basename($_);
        # strip extension from file name
        ($file_name = $pix_name) =~ s/$EXT_INCL_EXPR//gi;
        # get base directory
        ( $BASE = $_ ) =~ s/(.*)\/$pix_name$/$1/g;
        # BASE is blank if we are already inside the directory
        # for which to do thumbnails, thus:
        if ( $BASE eq "" 
            || ! -d $BASE ) 
        { 
            $BASE = "."; 
        }
        next if ($BASE eq $THUMBNAIL);
        #print STDOUT $BASE."\n";

        # this is just to clear up all 
        # warnings from Perl.. 
        if ( $BASE gt "" 
            && $tmp_BASE gt ""
            && $BASE !~ m/$tmp_BASE/ ) 
        {
            if ( 
                $FORCE > 0  && 
                ! -f "$BASE/.nopixdir2htmlrc" 
            ) 
            {
                if ( 
                    copy("$ROOT_DIRECTORY/$CONFIG_FILE", 
                        "$BASE/$CONFIG_FILE") 
                ) 
                {
                    print $LOGFILE (": Force copy ".
                        " $ROOT_DIRECTORY/$CONFIG_FILE ".
                        "==> $BASE/$CONFIG_FILE \n");
                } # end if copy
            } # end if FORCE

            if ( ! -f  "$BASE/$CONFIG_FILE" && ! -f "$BASE/.nopixdir2htmlrc" ) 
            {
                if ( 
                    copy("$ROOT_DIRECTORY/$CONFIG_FILE", 
                        "$BASE/$CONFIG_FILE") 
                ) 
                {
                    print $LOGFILE (": Copied ".
                        " $ROOT_DIRECTORY/$CONFIG_FILE ".
                        "==> $BASE/$CONFIG_FILE \n");
                } # end if copy
            } # end if missing $CONFIG_FILE

            # read specific config file for this directory
            if (! -f "$BASE/.nopixdir2htmlrc" ) 
            {
                # change of base, reset two-dimensional array counter
                print $LOGFILE "+ Reading config for $BASE\n";
                %myconfig = init_config($BASE);
            } # end if not nopixdir2htmlrc
            $total_directories++;
        }  # end if base not equal tmp_base
        
        # update flag
        $tmp_BASE = $BASE;
        next if ( -f "$BASE/.nopixdir2htmlrc" );

        # construct PATH for thumbnail directory
        $THUMBNAILSDIR="$BASE/$THUMBNAIL";

        #print STDOUT $HTMLSDIR."\n";
        if (!-d "$THUMBNAILSDIR") { 
            print $LOGFILE ("= Making thumbnail directory in $BASE\n");
            mkdir("$THUMBNAILSDIR",0755);
        }

        if ( !-f "$THUMBNAILSDIR/".$THUMB_PREFIX.$pix_name ){
            print $LOGFILE ("\n= Converting file $BASE/$pix_name into $THUMBNAILSDIR/$THUMB_PREFIX"."$pix_name \n");
            my $image = Image::Magick->new;
            $image->Read("$BASE/$pix_name");
            $image->Resize("$PERCENT");
            $image->Write("$THUMBNAILSDIR/$THUMB_PREFIX"."$pix_name");
            undef $image;
            # TODO if we could not load Image::Magick, see if "convert" is installed and use
            # this instead:
            #system("convert -geometry $PERCENT $BASE/$pix_name $THUMBNAILSDIR/$THUMB_PREFIX"."$pix_name");
            #if ( $? != 0 ) {
            #    die "ERROR: conversion failed\n $! ";
            #}
            print $LOGFILE ("\n"); 
        } 
        # end if thumbnail file

        # save pixname for the index.html file
        push @{$pixfiles{$BASE}}, "$THUMBNAILSDIR/$THUMB_PREFIX"."$pix_name";
        # update flags
        $LAST_BASE = $BASE;
        # update progressbar
        progressbar($PROGRESS,$TOTAL);
        $PROGRESS++;
    } #end foreach @ls

    if ( $NOINDEX == 0 ) {
        mkindex(\%pixfiles,$MENU_STR);  # pass hash reference
        # and a menu string
        # to be included in e/a file
    }

} # end mkthumb

sub thumb_html_files {
    # creates an HTML page for a thumbnail
    my $ROOT = $_[0];
    # locals
    my (@ls,%myconfig) = ();
    my $i = 0;
    my ($thisFile,
        $pix_name,
        $file_name,
        $next_pix_name,
        $next_file_name,
        $last_pix_name,
        $current_html_file,
        $last_file_name,
        $current_link,
        $last_link,
        $LAST_BASE,
        $NEXT_BASE,
        $HTMLSDIR) = "";
    # TODO find a more elegant solution here
    # init to dummy string:
    my $BASE = "trash/\file";
    my $tmp_BASE = "garbage\/file";
    my $last_html_file = "this_is/dummy\string";

    print $LOGFILE ("= Making HTML files in $ROOT \n");
    #construct array of all image files
    my @ary = do_file_ary("$ROOT");
    # parse array of images
    foreach (@ary){
        $thisFile = basename($_);
        next if ($thisFile =~ m/$EXCEPTION_LIST/);
        next if ($_ =~ m/\/$THUMBNAIL\/.*$EXT_INCL_EXPR$/i);
        next if ($thisFile !~ m/$EXT_INCL_EXPR/i);
        push @ls,$_;
    } #end images array creation

    # progressbar stuff
    # gauge message
    my $MESSAGE = "HTML Creation";
    # initial values for gauge, note total
    # is number of elements in array ;-) 
    my ($PROGRESS,$TOTAL) = (0,$#ls);
    progressbar_msg($MESSAGE);
    #print all picts now
    # $#VAR gets number of elements of an array variable
    for ( $i=0; $i <= $#ls; $i++) {
        $pix_name = basename($ls[$i]);
        # strip extension from file name
        ($file_name = $pix_name) =~ s/$EXT_INCL_EXPR//gi;
        # get base directory
        ( $BASE = $ls[$i] ) =~ s/(.*)\/$pix_name$/$1/g;
        # BASE is blank if we are already inside the directory
        # for which to do thumbnails, thus:
        if ( ! -d $BASE ) { 
            $BASE = "."; 
        }
        next if ($BASE eq $THUMBNAIL);
        # print STDOUT "Base: $BASE.\n";
        if ( $BASE gt ""
            && $BASE ne $tmp_BASE ) 
        {
            # read specific config file for this directory
            if (! -f "$BASE/.nopixdir2htmlrc" ) {
                print $LOGFILE "+ ThumbHtmlFiles Reading config for $BASE\n";
                %myconfig = init_config($BASE);
            }
        }
        # update flag
        $tmp_BASE = $BASE;
        next if ( -f "$BASE/.nopixdir2htmlrc" );
        # construct PATH for html directory
        $HTMLSDIR = "$BASE/$HTMLDIR";
        if (!-d "$HTMLSDIR") { 
            print $LOGFILE ("= Making html files directory in $BASE\n");
            mkdir("$HTMLSDIR",0755);
        }
        $current_html_file = "$HTMLSDIR/$file_name.".$myconfig{"ext"};
        $current_link = "$file_name.".$myconfig{"ext"};
        if ( -f $current_html_file ){
            print $LOGFILE ": Overriding $current_html_file\n";
        } # end if not current_html_file
        print $LOGFILE ("= Creating html file into $current_html_file\n");
        # TODO routine for creating file should be called here...
        open(FILE, "> $current_html_file") || 
        die "Couldn't write file $current_html_file";

        # start HTML
        print FILE ($myconfig{"header"}."\n");
        # start table
        print FILE ($myconfig{"table"}."\n");
        print FILE ("<tr><td>\n");
        # image here
        print FILE ("<img src='../$pix_name'>\n");
        print FILE ("</td></tr>\n<tr><td valign='bottom' align='center'><div align='center'>\n");
        # backward link here
        if ( $last_html_file ne "this_is/dummy\string" 
            && -f $last_html_file 
            && ($BASE eq $LAST_BASE) ) 
        {
            print FILE ("<a href='$last_link'>&lt;==</a>\n"); 
        } else {
            print FILE ("&lt;==");
        }
        # home link here
        print FILE (" | <a href='../$FILE_NAME.".$myconfig{"ext"}."'>HOME</a> | \n");

        if ( -f $ls[$i+1] ) {
            $next_pix_name = "....";
            # calculate next base
            $next_pix_name = basename($ls[$i+1]);
            # get next base directory
            ( $NEXT_BASE = $ls[$i+1] ) =~ s/(.*)\/$next_pix_name$/$1/g;
        }
        # forward link here
        if ( -f $ls[$i+1] && ($BASE eq $NEXT_BASE) ) {
            $next_file_name = "";
            ($next_file_name = $next_pix_name) =~ s/$EXT_INCL_EXPR//gi;
            #print FILE ("==&gt;");
            print FILE ("<a href='$next_file_name.".$myconfig{"ext"}."'>==&gt;</a>\n");
        } else {
            print FILE ("==&gt;");
            # TODO would be nice to jump to next directory in the
            #       array... 
            #print FILE (" <a href='../$next_file_name.$EXT'> |=&gt;&gt;</a> \n");
        }

        print FILE ("</div></td></tr>\n");
        print FILE ("</table>\n");
        # close the footer if one doesn't exist:
        if ( $myconfig{"footer"} eq "" ) {
            print FILE ($myconfig{"footer"}."\n");
            print FILE ("</center></body>\n");
            print FILE ("</HTML>\n");
        } else {
            print FILE ($myconfig{"footer"}."\n");
        }            
        close(FILE);
        # end HTML
        print $LOGFILE ("\n"); 
        # keep track of links
        $last_html_file = $current_html_file;
        $last_link = $current_link;
        # update flags
        $LAST_BASE = $BASE;
        $NEXT_BASE = "";
        #$PRINT_NEXT_LINK = 0;

        # update progressbar
        progressbar($PROGRESS,$TOTAL);
        $PROGRESS++;
    } #end foreach
} # end thumb_html_files

sub do_dir_ary {
    # uses find() to recur thru directories
    # returns an array of directories
    # i.e. in directory "a" with structure:
    # /a
    # /a/b
    # /a/b/c
    # /a/b2/c2
    # 
    # my @ary = &do_dir_ary(".");
    # 
    # will yield:
    # a
    # a/b
    # a/b/c
    # a/b2/c2
    # 
    my $ROOT = shift;
    my %opt = (wanted => \&process_dir, no_chdir=>1);
    find(\%opt,$ROOT);
    return @pixdir;
} # end do_dir_ary

sub process_dir {
    my $base_name = basename($_);
    if ( 
        !-f $_ && 
        $base_name !~ m/^($EXCEPTION_LIST|$THUMBNAIL|$HTMLDIR|\.[a-zA-Z0-9]+)$/ 
    ) {
        s/^\.\/*//g;
        push @pixdir,$_;
        #print $_ . "\n";
    }
} # end process_dir

sub do_file_ary {
    # uses find() to recur thru directories
    # returns an array of files
    # i.e. in directory "a" with the files:
    # /a/file.txt
    # /a/b/file-b.txt
    # /a/b/c/file-c.txt
    # /a/b2/c2/file-c2.txt
    # 
    # my @ary = &do_file_ary(".");
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
    return @pixfile;
} # end do_file_ary

sub process_file {
    my $base_name = basename($_);
    if ( 
        -f $_ && 
        $base_name !~ m/^($EXCEPTION_LIST|$THUMBNAIL|$HTMLDIR|\.[a-zA-Z0-9]+)$/ 
    ) {
        s/^\.\/*//g;
        push @pixfile,$_;
    }
} #end process_file

sub menu_file {
    #---------------------------------------------#
    # It creates a menu.$EXT file at 
    # the root level of the picture
    # directory (at the first 
    # directory that was passed to the script) or
    # it puts a menu in e/a index.$EXT file
    #
    # if there is a file named .new 
    # inside the given directory,
    # then a IMG tag will be put in 
    # front of the link with an image
    # src=myscript{new} in it
    # 
    # Thus in the config file put a line as such:
    # new=http://images.server.com/new_icon.png;
    #----------------------------------------------#

    my %myconfig = init_config($ROOT_DIRECTORY);
    my $MENU_STR = ""; # return this instead of making file
    my $IMG = ""; 
    my $line = "";
    #my $thisFile= "";
    my $x=0;    # counts number of links
    my $y=0;    # counts number of td's
    my $i=0;    # general purpose counter
    my $j=0;    # count number of TR's
    my @ls = ();
    my $ts = "";
    my @files=();
    my @pixdir = (); # reset array
    my @ary = do_dir_ary("$ROOT_DIRECTORY");
   
    # for e/a directory here
    # check if tha nopixdir2htmlrc file exists
    # if it does, then skip it and do the next one.
    # if it doesn't, then assume this will contain
    # a index.$EXT file and add it to the menu.
    #
    # TODO
    # If we check whether the index.$EXT file exists
    # first, then we get files with no menu table...
    # We should find a way to correct this.
    # Take into consideration that this function is called
    # before we even attempt to build the index.$EXT files
    # thus, that makes things kind of difficult a bit.
    foreach my $directory (@ary){
        if (
            !-f "$ROOT_DIRECTORY/$directory/.nopixdir2htmlrc"
            #&& -f "$ROOT_DIRECTORY/$directory/$FILE_NAME.".$myconfig{"ext"}
        ) {
            # note that @ls holds the HTML links...
            # thus, paths are relative and not absolute here:

            $ls[$x] = "$directory/$FILE_NAME.".$myconfig{"ext"}; # why not push()? just to keep count I guess...
            $x++; 
        }
    }   
    $total_links = $x;

    # sort menus alphabetically (dictionary order):
    # print STDERR join(' ', @ls), "\n";
    my $da;
    my $db;
    @ls = sort { 
        ($da = lc $a) =~ s/[\W_]+//g;
        ($db = lc $b) =~ s/[\W_]+//g;
        $da cmp $db;
    } @ls;
    if ( $MENUONLY > 0 ) {
        open(FILE, "> ".$ROOT_DIRECTORY."/".$MENU_NAME.".".$myconfig{"ext"}) ||
        die "Couldn't write file $MENU_NAME.".$myconfig{"ext"}." to $ROOT_DIRECTORY";
    }

    # menus are now part of the index.EXT...
    # print header only if menuonly is set and we want to show
    # the header/footer set in .pixdir2htmlrc
    if ( $MENUONLY > 0 && $myconfig{"menuheader_footer"} > 0 ) {
        print FILE ($myconfig{"header"}."\n");
    }
    if ( $total_links > 1 )
    {
        if ( $MENUONLY > 0 ) 
        {
            print FILE ($myconfig{"table"}."\n");
        }
        $MENU_STR .= $myconfig{"table"}."\n";
        # print all links now
        my $tmp_tr = ""; # used to color the rows
        while($x>0){
            # temporarily turn off warnings
            no warnings;
            # TODO
            # menu only routine: prints to a file... should merge
            # with the str portion (see else)
            #
            if ( $MENUONLY > 0 ) {
                if ($myconfig{"tr"}=~m/\%+bgcolor\%+/i){
                    if (($j % 2) == 0){
                        ($tmp_tr = $myconfig{"tr"}) =~ s/\%+bgcolor\%+/bgcolor=#efefef/i;
                    } else {
                        ($tmp_tr = $myconfig{"tr"}) =~ s/\%+bgcolor\%+//i;
                    }

                    print FILE ($tmp_tr."\n");

                } else {
                    print FILE ($myconfig{"tr"}."\n");
                }
                for ($y=1;$y<=$menu_td;$y++){
                    # close the TD tags
                    if ($y > 1) { 
                        print FILE ("\t </td> \n"); 
                    }   
                    print FILE ("\t".$myconfig{"td"}."\n");

                    if ( $ls[$i] ne "" ) {
                        # if link exists, otherwise leave it blank
                        # TODO there is a better way to do this... find it...
                        ($ts = $ls[$i]) =~ s#(.*)/$FILE_NAME.$myconfig{"ext"}#$1#gi;
                        # from nautilus one cannot pass arguments
                        # "--menuonly" but... just to keep things
                        # consistent...
                        # if number of characters is greater than $STR_LIMIT
                        # truncate $ts to a few characters.
                        if ( $nautilus_root gt "" ) {
                            ( $ls[$i] = $ls[$i] ) =~ s,$nautilus_root/,,g;
                            ( $ts = $ts ) =~ s,$nautilus_root/*,,g;
                        }
                        my $tmp_ts = str_truncate($ts);
                        $ts = ucfirst($tmp_ts);
                        $IMG = (-f "$ts/.new") ? "<img valign='middle' border=0 src='".$myconfig{"new"}."' alt='new'>":""; # if .new file
                        $ts = ucfirst($ts);
                        print FILE ("<a href='".$myconfig{"uri"}."/$ls[$i]' target='_top'>$IMG $ts</a>\n");
                    } else {
                        print FILE ("&nbsp;");
                    }
                    $i++;
                    $x--;
                } # end for $y
                print FILE ("</tr>\n");
                $j++; # incr TR counter
            } else {
                # general menu routine
                # TODO cleanup
                if ($myconfig{"tr"}=~m/\%+bgcolor\%+/i){
                    if (($j % 2) == 0){
                        ($tmp_tr = $myconfig{"tr"}) =~ s/\%+bgcolor\%+/bgcolor=#efefef/i;
                    } else {
                        ($tmp_tr = $myconfig{"tr"}) =~ s/\%+bgcolor\%+//i;
                    }
                    $MENU_STR .= $tmp_tr."\n";
                } else {
                    $MENU_STR .= $myconfig{"tr"}."\n";
                }
                for ($y=1;$y<=$menu_td;$y++){
                    # close the TD tags
                    if ($y > 1) { 
                        $MENU_STR .= "\t </td> \n";
                    }   
                    $MENU_STR .= "\t".$myconfig{"td"}."\n";
                    # menu entries
                    if ( $ls[$i] ne "" ) {
                        # if link exists, otherwise leave it blank
                        # TODO there is a better way to do this... find it...
                        ( $ts = $ls[$i]) =~ s,(.*)/$FILE_NAME.$myconfig{"ext"},$1,gi;
                        $IMG = (-f "$ts/.new") ? "<img valign='middle' border=0 src='".$myconfig{"new"}."' alt='new'>":""; # if .new file
                        # if number of characters is greater than $STR_LIMIT
                        # truncate $ts to a few characters.
                        if ( $nautilus_root gt "" ) {
                            ( $ls[$i] = $ls[$i] ) =~ s,$nautilus_root/,,g;
                            ( $ts = $ts ) =~ s,$nautilus_root/*,,g;
                        }
                        my $tmp_ts = str_truncate($ts);
                        $ts = ucfirst($tmp_ts);
                        # $ls tends to hold the whole filename path+filename
                        # we don't care about the whole path here...
                        $MENU_STR .= "<a href='".$myconfig{"uri"}."/$ls[$i]' target='_top'>$IMG $ts</a>\n";
                    } else {
                        $MENU_STR .= "&nbsp;";
                    }
                    $i++;
                    $x--;
                } # end for $y
                $MENU_STR .= "</tr>\n";
                $j++; # incr TR counter
            } # end if/else menuonly
        }
        if ( $MENUONLY > 0 ) {
            print FILE ("</table>\n");
        }
        $MENU_STR .= "</table>\n";
    } # end if total_links
    else 
    {
        print $LOGFILE (": Not a single link found\n");
    }
    # see previous notes on header
    if ( $MENUONLY > 0 && $myconfig{"menuheader_footer"} > 0) {
        print FILE ($myconfig{"footer"}."\n");
    } 
    if ( $MENUONLY > 0 ) {
        close(FILE);
    }
    if ( $total_links > 1 ) {
        print $LOGFILE (": $total_links links in menu.\n");
    }
    return $MENU_STR;
} #end menu_file

sub str_truncate 
{
    my $str = shift;
    my $str_length = length ($str);
    $str = ($str_length > $STR_LIMIT) ? "...".substr($str,($STR_LIMIT/2),$str_length):$str;
    # return truncated string
    return $str;
} #end str_truncate

sub progressbar
{
    my ($PROGRESS,$TOTAL)=@_;
    chomp($PROGRESS);
    chomp($TOTAL);
    my $current = 0;
    # make sure we don't divide by 0
    if ( $TOTAL > 0 ) 
    {
        $current = sprintf( "%02d",($PROGRESS/$TOTAL) * 100 );
        print $GAUGE $current."\n";
    } 
} # end progressbar

sub progressbar_msg
{
    my ($MESSAGE) = @_;

    chomp($MESSAGE);
    print $GAUGE  "XXX\n".$MESSAGE."\nXXX\n";
} # end progressbar_msg
