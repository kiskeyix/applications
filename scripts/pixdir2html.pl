#!/usr/bin/perl 
# $Revision: 1.5 $
# Luis Mondesi  <lemsx1@hotmail.com> 2002-01-17
# 
# USAGE:
#   pictDir2html.pl [-n|--nomenu] [-f|--force] [-h|--help]
# 
#   force   - creates a .pictDir2htmlrc in every subdir overriding
#             any file with that name
#   nomenu  - do not create menus after finishing creating thumbnails
#   help    - prints this help and exit
#   
# DESCRIPTION:
# 
# Use this non-interactive script in Nautilus to create HTML files
# with their proper thumbnails for pictures (.jpeg or .gif)
# 
# Make this file executable and put it in:
# ~/.gnome/nautilus-scripts
# or 
# ~/.gnome2/nautilus-scripts
# 
# Then run it from from the File::Scripts::script_name menu
# 
# You could customize each directory differently by having a
# file named .pictDir2htmlrc in the directory containing the
# pictues. This file has the form:
# 
# percent=30%;; #size of the thumbnails for this folder
# title=Title;;
# html_msg=<h1>Free form using HTML tags</h1> <h2> ending in 
# two semicolons</h2> <p> this is a single line. Do not permit
# line breaks</p>;;
# body=<body bgcolor='#000000'>;;
# p=<p>;; # or whichever way you want to customize this tag
# table=<table border='0'>;;
# td=<td valign='left'>;;
# tr=<tr>;;
# footer=<a href='#'>A footer here</a>;;
# 
# These are the only tags that you can customize for now :-)
# Required: linux/UNIX "convert" command (to convert images from
#	    one format to another or sizes, etc...)
# 
# BUGS:
#   * config file cannot contain lines that spawn to multiple
#     lines. Will fix later.
#   * config file should not contain double quotes (") without
#     escaping them first (\")
#   * if a directory has a .nopictDir2htmlrc file, it will be skipped
#     even if there are subdirectories inside which might need thumbnails
#     created. Either do not put a .nopictDir2htmlrc file in these directories
#     or mv the subdirectories parallel to this directory. Will deal with
#     this issue later when menuMaker subroutine is completed and completely
#     recursive
# 
# TIPS:
# 
# Put a .nopictDir2htmlrc file in directories for which you do not want
# thumbnails and/or index.html to be written
#

use File::Copy;
use Getopt::Long;
Getopt::Long::Configure('bundling');

use strict;
use vars qw( $VERSION @INC );
use Config;

my $VERSION="0.5";

$|++; # disable buffer

my $USAGE = "pictDir2html.pl [-n|--nomenu] [-f|--force]
 
   force   - creates a .pictDir2htmlrc in every subdir overriding
             any file with that name
   nomenu  - do not create menus after finishing creating thumbnails
   help    - prints this help and exit\n";

# update these if needed
my $HTML_DIRECTORY=".";

my $LOG="$HTML_DIRECTORY/pictDir2html.log";

my $FILE_NAME="index.php";
my $MENU_NAME="menu.html";

my $CONFIG_FILE=".pictDir2htmlrc";

my $THUMBNAIL="t";

# list directories that should be skipped here
# separated by |
my $EXCEPTION_LIST = "CVS|RCS";

# How big are the thumbnails?
# This is the default, in case the config file
# doesn't exist or do not have this item in it
my $PERCENT="20%";
# How many TDs per table?
my $td=4;
# How many TDs per menu table?
my $menu_td=10;


# dont worry if you don't have a log rotation facility...
# just leave it as is
my $SAVELOG = "/usr/bin/savelog";

###Nothing below this line should need to be configured.###
#**************************************************************#

my %myconfig = ""; # init config hash

my $total_directories=0;

my $IMAGE_DIRECTORY=".";

my $FORCE=0; 
my $NOMENU=0; 
my $HELP=0;

# get options
GetOptions(
    'n|nomenu' => \$NOMENU,
    'f|force' => \$FORCE,
    'h|help' => \$HELP,
);

die $USAGE if $HELP;

#$FORCE++ if $force;
#$NOMENU++ if $nomenu;

# TODO find a way to pass a directory to
# which create images right from the command
# line
#$IMAGE_DIRECTORY = shift;

#eval $IMAGE_DIRECTORY;
#die $@ if $@; # if any error ocurred while evaluating, then die

my $THUMBNAILSDIR="$IMAGE_DIRECTORY/$THUMBNAIL";

warn << "__EOF__";
Perl PictDir2HTML v$VERSION (Luis Mondesi <lemsx1\@hotmail.com> / LatinoMixed.com) (running with Perl $] on $Config{'archname'}) \n \n
__EOF__

main();

#-------------------------------------------------#
#                     FUNCTIONS                   #
#-------------------------------------------------#
sub main {
    if (!-x "/usr/bin/convert") {
        die ("could not find 'convert'. Install ImageMagick.");
    }
    open (LOGFILE,"> $LOG");
    init_config(".");
    mkthumb($IMAGE_DIRECTORY);
    unless ( $NOMENU == 1 ) {
        print LOGFILE ("Creating menu file\n");
        menuMaker();
    }
    close(LOGFILE);
    if ( -x $SAVELOG ) {
        system("$SAVELOG $LOG > /dev/null 2>&1");
    }

    print STDOUT "$total_directories directories.\n Read log $LOG for details. \n";
} # endmain

# Takes one argument:
# ROOT = directory from which we will take the config file
sub init_config {
    
    my $ROOT = shift;
    if (open(CONFIG, "<$ROOT/$CONFIG_FILE")){
        while (<CONFIG>) {
            next if /^\s*#/;
            chomp;
            $myconfig{$1} = $2 if m/^\s*([^=]+)=(.+)\;\;+/;
        }
        close(CONFIG);

    } else {
        warn << "__EOF__";
   Could not find $ROOT/$CONFIG_FILE 
__EOF__

        $myconfig{percent}="20%";
        $myconfig{title}="Images";
        $myconfig{meta}="<meta http-equiv='content-type' content='text/html;charset=iso-8859-1'>";
        $myconfig{stylesheet}="<link rel='stylesheet' href='../styles.css' type='text/css'>";
        $myconfig{html_msg}="<h1>Free form HTML</h1>";
        $myconfig{body}="<body bgcolor='#000000' text='#ffffff'>";
        $myconfig{p}="<p>";
        $myconfig{table}="<table border='0'>";
        $myconfig{td}="<td valign='top' align='left'>";
        $myconfig{tr}="<tr>";
        $myconfig{footer}="";

    }
    
    #construct a header if it doesn't yet exist:
    if ( $myconfig{header} eq "" ) {

        print LOGFILE ("Blank header. Generating my own ... \n");

        $myconfig{header}="<html>
        <head>
        ".$myconfig{meta}."
        <title>".$myconfig{title}."</title>
        ".$myconfig{stylesheet}."
        </head>".
        $myconfig{body}."
        <center>".
        $myconfig{html_msg}."
        \n
        ";
    }

    return %myconfig;
}

# Takes one argument directory to create images for
# If a directory is found inside this directory containing
# images, then it recursively calls itself over and over
sub mkthumb {
    
    my $ROOT = $_[0];
    $THUMBNAILSDIR="$ROOT/$THUMBNAIL";

    my @subdir = ();
    my @ls = ();
    my @ts = ();
    my %myconfig = ();

    my $line = "";
    my $thisFile= "";
    my $i=0;
    my $total_picts=0;
    
    opendir (DIR,"$ROOT") || die "Couldn't open dir $ROOT";
    
    print LOGFILE ("Working in $ROOT \n");
    
#construct array of all image files
    while (defined($thisFile = readdir(DIR))) {
        next if ($thisFile =~ m/$EXCEPTION_LIST/);
        next if ($thisFile !~ /\w/);
        next if ($thisFile =~ /^\..*/); 
        if (-d "$ROOT/$thisFile" && $thisFile !~ m/^$THUMBNAIL$/ ) {
            if (-f "$ROOT/$thisFile/.nopictDir2htmlrc") {
                print LOGFILE ".nopictDir2htmlrc file exists in ($thisFile). Skipping ...\n";
                next;
            }
            $total_directories++;
            push @subdir,"$ROOT/$thisFile";
   
            if (-f "$ROOT/$thisFile/$CONFIG_FILE") {
                if ($FORCE == 1) {
                    if ( 
                        copy("$HTML_DIRECTORY/$CONFIG_FILE", 
                            "$ROOT/$thisFile/$CONFIG_FILE") 
                    ) {
                        print LOGFILE ("force copied $HTML_DIRECTORY/$CONFIG_FILE \
                            to $ROOT/$thisFile/$CONFIG_FILE \n");
                    }
                } 
            } else {
                #file doesn't exist, copy it
                if (
                copy("$HTML_DIRECTORY/$CONFIG_FILE", 
                    "$ROOT/$thisFile/$CONFIG_FILE")
                ) {
                    print LOGFILE ("copied $CONFIG_FILE to \
                        $ROOT/$thisFile/$CONFIG_FILE \n");
                }
            }
        }
        next if ($thisFile !~ m/\.(jpg|png|jpeg|gif)/i);
        push @ls,$thisFile;
        $total_picts++;
    } #end images array creation
    closedir(DIR);

#do we already have a dir with this name? no, then create one
    if (!-d "$THUMBNAILSDIR" && !-f "$ROOT/.nopictDir2htmlrc") { 
        print LOGFILE ("making thumbnails directory in $THUMBNAILSDIR\n");
        mkdir("$THUMBNAILSDIR",0755);
    }

    if (!-f "$ROOT/.nopictDir2htmlrc") {
       
        # read specific config file for this directory
        %myconfig = init_config($ROOT);
        
        open(FILE, "> $ROOT/$FILE_NAME") || die "Couldn't write file $FILE_NAME to $ROOT";

        # Percentage for this directory?
        $PERCENT = ("$myconfig{percent}") ? $myconfig{percent}:$PERCENT;

        # start HTML
        print FILE ("$myconfig{header}\n");

        # start table
        print FILE ("$myconfig{table}\n");

        my $my_bgcolor = "";

        #print all picts now
        foreach(@ls){
            if ( !-f "$THUMBNAILSDIR/"."t$_" ){
                # TODO determine which thumbnails need to be recreated
                # $FORCE_ALL || !-f "$THUMBNAILSDIR/"."t$_" 
                # file doesn't exists or we are being forced to recreated
                # create thumbnail below
                if ( -f "$ROOT/$_" ){

                    print LOGFILE ("\nConverting file $ROOT/$_ into $THUMBNAILSDIR/t$_ \n");
                    system("convert -geometry $PERCENT $ROOT/$_ $THUMBNAILSDIR/"."t$_");
                    print LOGFILE ("\n"); 
                } # end if -f ROOT/ls[i]
            } # end if THUMBNAILSDIR/myfile

            if ($i == 0) {
                # open a new row
                if ( $myconfig{tr} =~ m/\%+bgcolor\%+/i ) {
                    ($myconfig{tr} = $myconfig{tr}) =~ s/\%+bgcolor\%+//i;
                }

                print FILE ($myconfig{tr}."\n");
            } 
            print FILE ("\t".$myconfig{td}."\n");
            if (-f "$THUMBNAILSDIR/"."t$_"){
                # if file exists, create a link, otherwise leave it blank
                print FILE ("<a href='$_'><img src='$THUMBNAIL/"."t$_'></a>\n");
            } else {
                print FILE ("&nbsp;");
            }
            print FILE ("\t</td>\n");
            if ($i<($td-1)) {
                $i++;
            } else {
                # wrap and reset counter
                print FILE ("</tr>\n");
                $i = 0;
            }
        } #end foreach
        # complete missing TD
        if ($i != 0) {
            for (;$i<$td;$i++) {
                print FILE ("\t".$myconfig{td}."\n");
                print FILE ("&nbsp;");
                print FILE ("\t</td>\n");
            }
        }
        print FILE ("</tr>\n");
        print FILE ("</table>\n");

# close the footer if one doesn't exist:
        if ( $myconfig{footer} eq "" ) {
            print FILE ($myconfig{footer}."\n");
            print FILE ("</center></body>\n");
            print FILE ("</HTML>");
        } else {

            print FILE ($myconfig{footer});
        }
        close(FILE);
        print LOGFILE "Counted $total_picts pictures here $ROOT\n";
    }

# loop thru rest of directories
    foreach(@subdir){
        mkthumb("$_"); 
    }
} #end mkthumb

#sub thumbfile {
    # creates an HTML page for a thumbnail
    # this will be implemented later

#}
sub prompt {
    # promt user and return input 
    # pass string when calling subroutine: $var = prompt("string");
    my($string) = $_[0];#shift;
    my($input) = "";
    
        #if ($Suppress_readline) { 
    print ("* ".$string."\n");
    chomp($input = <STDIN>);
        # chomp is the same as:
        # $input =~ s/\n//g; # remove lineend
        #} else {
        # No readline support for now
        #$input = $term->readline($string);
        #}
    return $input;
}

sub menuMaker {
# How does it work?
# Run it from the given folder where the menu.html
# file will be located, and relative to this file
# links will be constructed for e/a folder
# inside this given folder that has a file named: index.html or index.php
# 
# if there is a file named .new inside the given directory,
# then a IMG tag will be put in front of the link with an image
# src=myscript{new} in it
# 
# Thus in the config file put a line as such:
# new=http://images.server.com/new_icon.png;;

    # init a couple of needed variables
    my $IMG = ""; 
    my $line = "";
    my $thisFile= "";
    my $x=0;
    my $y=0;
    my $i=0;
    my $j=0; # count number of TR's
    my $total_links=0;
    my @ls = ();
    my $ts = "";
    my @files=();

    opendir (DIR,"$HTML_DIRECTORY") || die "Couldn't open dir $HTML_DIRECTORY";

    # TODO use function to init the @ls array recursively
    #construct array of all HTML files
    while (defined($thisFile = readdir(DIR))) {
        next if ($thisFile !~ /\w/);
        next unless (-d "$HTML_DIRECTORY/$thisFile");
        next if (-f "$HTML_DIRECTORY/$thisFile/.nopictDir2htmlrc");
        next unless (-f "$HTML_DIRECTORY/$thisFile/$FILE_NAME");
        $ls[$x] = "$thisFile/$FILE_NAME"; # link
        $x+=1;
    }
    closedir(DIR);

# sort menus alphabetically (dictionary order):
# print STDERR join(' ', @ls), "\n";
    my $da;
    my $db;
    @ls = sort { 
        ($da = lc $a) =~ s/[\W_]+//g;
        ($db = lc $b) =~ s/[\W_]+//g;
        $da cmp $db;
    } @ls;

    $total_links = $x;

    open(FILE, "> $HTML_DIRECTORY/$MENU_NAME") || \
        die "Couldn't write file $MENU_NAME to $HTML_DIRECTORY";

# TODO sometimes menus don't need headers and footers
#       device a way to turn it off in the rc file
#print FILE ($myconfig{header}."\n");
    print FILE ("$myconfig{table}\n");

# print all links now

    my $tmp_tr = ""; # used to color the rows

    while($x>0){
        # temporarily turn off warnings
        no warnings;

        if ($myconfig{tr}=~m/\%+bgcolor\%+/i){
            if (($j % 2) == 0){
                ($tmp_tr = $myconfig{tr}) =~ s/\%+bgcolor\%+/bgcolor=#efefef/i;
            } else {
                ($tmp_tr = $myconfig{tr}) =~ s/\%+bgcolor\%+//i;
            }

            print FILE ($tmp_tr."\n");

        } else {
            print FILE ($myconfig{tr}."\n");
        }
        for ($y=1;$y<=$menu_td;$y++){
            if ($y > 1) { print FILE ("\t </td> \n"); }   # close the TD tags
            print FILE ("\t".$myconfig{td}."\n");
            if ( $ls[$i] ne "" ) {
                # if link exists, otherwise leave it blank
                ($ts = $ls[$i]) =~ s/(.*)\/$FILE_NAME/$1/gi;
                $IMG = (-f "$ts/.new") ? "<img valign='middle' border=0 src='$myconfig{new}' alt='new'>":""; # if .new file
                $ts = ucfirst($ts);
                print FILE ("<a href='$myconfig{uri}/$ls[$i]' target='_top'>$IMG $ts</a>\n");
            } else {
                print FILE ("&nbsp;");
            }
            $i++;
            $x--;
        } # end for $y
        print FILE ("</tr>\n");
        $j++; # incr TR counter
    }
    print FILE ("</table>\n");
#print FILE ($myconfig{footer}."\n");
    close(FILE);
    print STDERR "Done with menus. I count $total_links files.\n";
}
