#!/usr/bin/perl -w
# do not show so many warnings: -w ;    ;-)

# Luis Mondesi  <lemsx1@hotmail.com> 2002-01-17
# Last modified: 2002-May-28
# Use this script in Nautilus to create all index and thumbnails files
# recursively.
# This is part of pictDir2html.pl script, but it can be used
# by itself.
# 
# USAGE: pictDir2htmlALL.pl [force]
# - force   forces the pictDir2htmlrc file to be copied to all directories
# 
# How does it work?
# It copies the default pictDir2htmlrc file from the 
# current dir to all directories
# and then it starts making all index.html's and thumbnails by calling 
# ~/.gnome/nautilus-scripts/pictDir2html.pl for e/a folder :-)
# Make this file executable and put it in:
# ~/.gnome/nautilus-scripts
# 
# Then run it from from the Nautilus File::Scripts::script_name menu
# 
# put a .nopictDir2htmlrc file in the directories for which you do not wish to
# generate index.html or picture thumbnails
#
use File::Copy;
use strict;
use vars qw( $VERSION @INC );
use Config;
my $VERSION="0.3";

my $FORCE=($ARGV[0] =~ m/force/i) ? 1 : 0; # copy CONFIG_FILE to DIR even if file already exists? Default no (0)
my $HTML_DIRECTORY=".";
my $LOG="$HTML_DIRECTORY/pictDir2html.log";
my $CONFIG_FILE=".pictDir2htmlrc";
my $HMDIR="/home/luigi";

my $PICTDIR2HTML=$ENV{"HOME"}."/bin/pictDir2html.pl"; # path to the script (usually: ~/.gnome/nautilus-scripts/pictDir2html.pl )
my $MENUMAKER=$ENV{"HOME"}."/bin/menuMaker.pl";

my $SAVELOG = "/usr/bin/savelog";

###########################################################
###Nothing below this line should need to be configured.###
###########################################################

my $thisFile= "";
my $total_directories=0;

warn << "__EOF__";
Perl menuMaker v$VERSION (Luis Mondesi <lemsx1\@hotmail.com> / LatinoMixed.com) (running with Perl $] on $Config{'archname'}) \n \n
__EOF__

open (LOGFILE,"> $LOG");

opendir (DIR,"$HTML_DIRECTORY") || die "Couldn't open dir $HTML_DIRECTORY";

#construct array of all HTML files
while (defined($thisFile = readdir(DIR))) {
    next if ($thisFile !~ /\w/);
    next if ($thisFile =~ m/\..*/i);
    next if (!-d "$HTML_DIRECTORY/$thisFile");
    next if (-f "$HTML_DIRECTORY/$thisFile/.nopictDir2htmlrc");
    #from File::Copy
    if (-f "$HTML_DIRECTORY/$thisFile/$CONFIG_FILE") {
	if ($FORCE == 1) {
	    copy("$CONFIG_FILE", "$HTML_DIRECTORY/$thisFile/$CONFIG_FILE");
	    print LOGFILE ("copied $CONFIG_FILE to $HTML_DIRECTORY/$thisFile/$CONFIG_FILE \n");
	} else {
	    print STDERR ("$CONFIG_FILE already exists and FORCE is set to 0. \n");
	}
    } else {
	#file doesn't exist, copy it
	copy("$CONFIG_FILE", "$HTML_DIRECTORY/$thisFile/$CONFIG_FILE");
	print LOGFILE ("copied $CONFIG_FILE to $HTML_DIRECTORY/$thisFile/$CONFIG_FILE \n");
    }
    
    print LOGFILE ("Making pictures in $HTML_DIRECTORY/$thisFile \n");
    system("$PICTDIR2HTML $HTML_DIRECTORY/$thisFile >> $LOG 2>&1 ");
    #~/.gnome/nautilus-scripts/pictDir2html.pl
    
    $total_directories++;
}
closedir(DIR);

my $response = "";
$response = prompt("Do you want to create the menus for these directories ($MENUMAKER)? [Y/n]");

if ( $response eq 'n' || $response eq 'N' ) {
   print STDERR ("No menu created \n");
} else {
    print STDERR ("Menu created \n");
    system("$MENUMAKER >> $LOG 2>&1 ");
}

# you can simply comment this out if you don't have a log rotation
# facility...
# rotate logs:
system("$SAVELOG $LOG > /dev/null 2>&1");

# a good practice...
close(LOGFILE);

print STDERR "$total_directories directories.\n";
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
