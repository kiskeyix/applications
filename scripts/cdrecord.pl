#!/usr/bin/perl -w
# a quick nautilus script to burn isos... 
# Just select the iso you want and choose this script
# from the nautilus script menu.
use strict;
use FileHandle; # std Perl
$|++; # disable buffer (autoflush)

my $CDRECORD = "cdrecord";
my $CDRECORD_ARGS = ""; #" -dummy "; # on Debian cdrecord reads /etc/default/cdrecord. So, there is no need to put dev= or any other argument here
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
my $title = "$file writing in progress";
$GAUGE->open("| $DIA --progress $DIA_ARGS --title='$title'"); # pipe-in

if ( defined($child) ) {
    my $list;
    my $current=0;
    while ( <$child> )
    {
        #print STDOUT "$_";
        if ( defined($GAUGE) ) {
            # massage data
            # TODO there should be a nicer way to do this...
            # we only care about 1 track here...
            ($list = $_) =~ s/Track\s+\d+:\s+(\d+)\s+of\s+(\d+)\s+MB\s+written.*/$1 $2/gi;
            print STDOUT "DEBUG: List '$list'\n";
            my @str = split(/\s+/,$list); # split by spaces
            # test if str0 and str1 are numbers
            if ( $str[0] && $str[1] && $str[0] =~ m/^\d+$/ && $str[1] =~ m/^\d+$/ )
            {
                $str[1] = ( $str[1] > 0 ) ? $str[1] : 100; # we don't divide by 0
                $current = sprintf( "%02d",($str[0]/$str[1]) * 100 );
                print STDOUT "DEBUG: real $current\n";
            } else {
                print STDOUT "DEBUG: fake $current\n";
                $current += 1;
            }
            print $GAUGE $current."\n";
        }
    }
    $GAUGE->close;
}
# close all open filehandles:
undef($GAUGE);
undef($child);
