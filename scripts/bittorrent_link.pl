#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Mar-07
#
# DESCRIPTION: creates a .torrent file in the local directory
#               which will be used to link with an announcer (tracker)
# USAGE: $0 /path/to/file
# CHANGELOG:
#
use strict;
$|++;

use File::Basename; #basename()
use File::Copy qw(move);

my $DEBUG = 0; # set to 1 to debug script

# point these two to /dev/null if you don't care about logging
my $CLIENT_LOG = "client_log.$$"; # keeps btdownload* logs
my $TRACKER_LOG = "tracker_log.$$"; # keeps tracker logs (if running local)

my $URL ="http://www.latinomixed.com"; # visible URL or public IP for tracker
my $URL_HTTP_PORT = "81"; # standard is 80
my $BTPORT = "6900"; # usually 6969
my $PATH_TO_DFILE = "/var/www/a/dstate"; # path to dstate file
# whole command for bttrack:
my $BTTRACK = "bttrack --port $BTPORT --dfile $PATH_TO_DFILE"; 

my $TRACKER_URL=$URL.":".$BTPORT."/announce"; # url construct for tracker

my $BTMAKEMETAFILE = "btmakemetafile ";
my $BTDOWNLOAD = "btdownloadheadless ";
my $BTUPLOAD_LIMIT=" --max_upload_rate 5 "; # number of kB/s

# ================================================== #
#            NO NEED TO MODIFY BELOW THIS LINE       #
# ================================================== #

if ( -e $ARGV[0] )
{
    #sanity checks
    chomp($ARGV[0]); # remove newlines
    ( $ARGV[0] = $ARGV[0] ) =~ s/\/+$//g; # remove trailing /
    # TODO see if tracker is running...
    print "Do you want me to start a tracker for you? [y/N] ";
    my $rep=<STDIN>;
    chomp($rep);
    if ( $rep =~ /^y/i )
    {
        print STDERR "Executing:\n$BTTRACK >> $TRACKER_LOG 2>&1 &\n" if $DEBUG;
        system("$BTTRACK >> $TRACKER_LOG 2>&1 &")
            and print STDOUT "check file $TRACKER_LOG for progress\n";
    } else {
        print "Assuming tracker running at $TRACKER_URL \n";
    }
    # could be a file or a whole directory
    $BTMAKEMETAFILE .= " $ARGV[0] $TRACKER_URL ";
    print STDERR "Executing:\n $BTMAKEMETAFILE\n" if $DEBUG;
    system("$BTMAKEMETAFILE");
    my $BASENAME = basename($ARGV[0].".torrent");
    # move file to current directory
    if ( -f "$ARGV[0].torrent" )  
    {
        move($ARGV[0].".torrent","$BASENAME")
            or die("Could not move $ARGV[0].torrent to ./$BASENAME");
        my $BT = "$BTDOWNLOAD $BTUPLOAD_LIMIT --url $URL\:$URL_HTTP_PORT/$BASENAME --saveas $ARGV[0]";
        print STDERR "Executing:\n$BT >> $CLIENT_LOG 2>&1 &\n" 
            if $DEBUG;
        system("$BT >> $CLIENT_LOG 2>&1 &")
            and print STDOUT "check file $CLIENT_LOG for client progress\n";
;
        #or die("Could not run '$BT', make sure that ./$BASENAME exists or copy .torrent file from $ARGV[0] to the current directory. $!\n");
        print STDOUT "Your public URL is: $URL\:$URL_HTTP_PORT/$BASENAME\n";
    } else {
        die("Could not find the .torrent file, check $ARGV[0] to see if there is a .torrent file there and then run '$BTDOWNLOAD $BTUPLOAD_LIMIT --url $URL\:$URL_HTTP_PORT/whatevername.torrent --saveas $ARGV[0]' manually");
    }
} else {
    print STDERR "USAGE:\n$0 /path/to/file_or_dir\n";
}
#EOF#
