#!/usr/bin/perl -w
# a quick nautilus script to burn isos... 
# Just select the iso you want and choose this script
# from the nautilus script menu.
use strict;
use FileHandle; # std Perl
$|++; # disable buffer (autoflush)

my $CDRECORD = "cdrecord";
my $CDRECORD_ARGS = ""; # on Debian cdrecord reads /etc/default/cdrecord. So, there is no need to put dev= or any other argument here
my $DIA = "zenity"; 
my $DIA_ARGS = ""; # additional arguments. Zenity needs none

# end config #

# a single .iso was passed to us from the command line:
my $file = $ENV{"NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"};

if ( ! -f $file ) {
    print STDERR "No file path. Sorry";
    exit(1);
}

my $GAUGE = new FileHandle; # progressbar widget
$GAUGE->autoflush(1);
my $child = new FileHandle; # cdrecord progress
$child->autoflush(1);


$child->open("$CDRECORD -v $CDRECORD_ARGS $file|"); # pipe-out

$GAUGE->open("| $DIA $DIA_ARGS --title='$file writing in progress' --progress  8 70 0"); # pipe-in

if ( defined($child) ) {
    while ( <$child> )
    {
        print STDOUT "$_";
        if ( defined($GAUGE) ) {
            # massage data
            my @str =~ s/^Track\s+\d+:\s+(\d+)\s+of\s+(\d+).*/\1 \2/gi;
            my $current = sprintf( "%02d",($str[0]/$str[1]) * 100 );
            print $GAUGE $current."\n";
        }
    }
    $GAUGE->close;
}
# close all open filehandles:
undef($GAUGE);
undef($child);
