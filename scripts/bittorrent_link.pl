#!/usr/bin/perl -w
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Mar-10
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

# logging is not necessary, but it helps. You can set this
# as you see fit...
my $LOG_DIR = "log";
if ( !-d $LOG_DIR )
{
    mkdir($LOG_DIR) or die("Could not create log dir. $!");
}
# point these two to /dev/null if you don't care about logging
my $CLIENT_LOG = "$LOG_DIR/client_log.$$"; # keeps btdownload* logs
my $TRACKER_LOG = "$LOG_DIR/tracker_log.$$"; # keeps tracker logs (if running local)

# applications
my $BTMAKEMETAFILE = "btmakemetafile ";
my $BTDOWNLOAD = "btdownloadheadless ";

# switches for applications
my $HOST ="www.latinomixed.com";
my $URL ="http://$HOST"; # visible URL or public IP for tracker
my $URL_HTTP_PORT = "81"; # standard is 80
my $BTPORT = "6900"; # usually 6969
my $PATH_TO_DFILE = "/var/www/a/dstate"; # path to dstate file

my $BTUPLOAD_LIMIT=" --max_upload_rate 7 "; # number of kB/s

# constructing whole command for bttrack:
my $BTTRACK = "bttrack --port $BTPORT --dfile $PATH_TO_DFILE"; 
# constructing whole URL for tracker:
my $TRACKER_URL=$URL.":".$BTPORT."/announce"; 

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
        if ( -f "$PATH_TO_DFILE" ) 
        {
            print STDOUT "Removing $PATH_TO_DFILE\n";
            unlink("$PATH_TO_DFILE") 
                or warn("Could not remove $PATH_TO_DFILE. You might have to do it manually.$!");
        }
        print STDERR "Executing:\n$BTTRACK >> $TRACKER_LOG 2>&1 &\n" if $DEBUG;
        system("$BTTRACK >> $TRACKER_LOG 2>&1 &")
            and print STDOUT "check file $TRACKER_LOG for progress\n";
    } else {
        print "Assuming tracker running at $TRACKER_URL \n";
    }
    my $BASENAME = basename($ARGV[0].".torrent");
    if ( !-f $BASENAME )
    {
        # could not find the given .torrent file.. so create one
        $BTMAKEMETAFILE .= " $ARGV[0] $TRACKER_URL ";
        print STDERR "Executing:\n $BTMAKEMETAFILE\n" if $DEBUG;
        system("$BTMAKEMETAFILE");
        # move file to current directory
        move($ARGV[0].".torrent","$BASENAME")
            or die("Could not move $ARGV[0].torrent to ./$BASENAME");
    }
    if ( -f "$BASENAME" )  
    {
        # assuming that btdownload is the same box as the one running
        # the tracker, thus the '--ip $HOST' switch. Remove this is
        # this assumption is incorrent
        my $BT = "$BTDOWNLOAD $BTUPLOAD_LIMIT --ip $HOST --url $URL\:$URL_HTTP_PORT/$BASENAME --saveas $ARGV[0]";
        print STDERR "Executing:\n$BT >> $CLIENT_LOG 2>&1 &\n" 
            if $DEBUG;
        system("$BT >> $CLIENT_LOG 2>&1 &")
            and print STDOUT "check file $CLIENT_LOG for client progress\n";
        #or die("Could not run '$BT', make sure that ./$BASENAME exists or copy .torrent file from $ARGV[0] to the current directory. $!\n");
        print STDOUT "Your public URL is: $URL\:$URL_HTTP_PORT/$BASENAME\n";
    } else {
        die("Could not find the .torrent file, check $ARGV[0] to see if there is a .torrent file there and then run '$BTDOWNLOAD $BTUPLOAD_LIMIT --url $URL\:$URL_HTTP_PORT/whatevername.torrent --saveas $ARGV[0]' manually");
    }
} else {
    print STDERR "USAGE:\n$0 /path/to/file_or_dir\n";
}
#EOF#
