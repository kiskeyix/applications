#!/usr/bin/perl 
# $Revision: 1.2 $
# Luis Mondesi  <lemsx1@hotmail.com> 2002-01-17
# 
# USAGE:
#   pictDir2html.pl [DIR] [force] [nomenu]
# 
#   DIR     - make thumbnails for DIR or current directory if no argument
#             is given
#   force   - creates a .pictDir2htmlrc in every subdir overriding
#             any file with that name
#   nomenu  - do not create menus after finishing creating thumbnails
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
use strict;
use vars qw( $VERSION @INC );
use Config;
my $VERSION="0.3";
$|++; # disable buffer

# update these if needed
my $HTML_DIRECTORY=".";
my $LOG="$HTML_DIRECTORY/pictDir2html.log";
my $FILE_NAME="index.php";
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

#TODO will make this into  a sub later
#       remember to make it recursive
my $MENUMAKER=$ENV{"HOME"}."/bin/menuMaker.pl";

# dont worry if you don't have a log rotation facility...
# just leave it as is
my $SAVELOG = "/usr/bin/savelog";

###Nothing below this line should need to be configured.###
#**************************************************************#

my $IMAGE_DIRECTORY=(-d "$ARGV[0]") ? "$ARGV[0]":".";
my $FORCE=(($ARGV[1] =~ m/force/i) || ($ARGV[2] =~ m/force/i) ) ? 1 : 0; 
my $NOMENU=(($ARGV[1] =~ m/nomenu/i) || ($ARGV[2] =~ m/nomenu/i) ) ? 1 : 0; 

my $total_directories=0;
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
    mkthumb($IMAGE_DIRECTORY);
    unless ( $NOMENU == 1 ) {
        print LOGFILE ("Creating menu file\n");
        system("$MENUMAKER >> $LOG 2>&1 ");
    }
    close(LOGFILE);
    if ( -x $SAVELOG ) {
        system("$SAVELOG $LOG > /dev/null 2>&1");
    }

    print STDOUT "$total_directories directories.\n Read log $LOG for details. \n";
} # endmain

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
        open(FILE, "> $ROOT/$FILE_NAME") || die "Couldn't write file $FILE_NAME to $ROOT";
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

# Percentage for this folder?
        $PERCENT = ("$myconfig{percent}") ? $myconfig{percent}:$PERCENT;

#print contents of array @ls

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
