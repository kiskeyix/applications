#!/usr/bin/perl -w
# a quick nautilus script to make isos... 
# Just select the directory you want and choose this script
# from the nautilus script menu.
#
# from the command line you can do:
# mkisofs.pl DIR
# or
# mkisofs.pl DIR dvd # to make a DVD image

$DEBUG=0;
$VOLIDMAXLENGTH=32;

# You could get only the selected files from nautilus, but
# it's better to let the user put all those files in 
# a single directory and then run this script on that directory
# $ENV{"NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"}

chomp($ARGV[0]); # remove end-line

# Volume id needs no spaces or other characters
( $volumeid = $ARGV[0] ) =~ s,[\s-]+,_,g;
# length should be less than $VOLIDMAXLENGTH
#my $str_length = length ($volumeid);
$volumeid = substr($volumeid,0,$VOLIDMAXLENGTH);
# put a .iso extension
( $name = $ARGV[0] ) =~ s,(.+),$1.iso,;

print "Argument: $ARGV[0] | Volume Name: $volumeid | FileName: $name\n" if $DEBUG == 1;
sleep(5) if $DEBUG == 1;

my $folder = $ARGV[0];

if ( $ARGV[1] eq "dvd" ) 
{
    die("Directory is not valid DVD tree. Missing $folder/VIDEO_TS") if ( !-d "$folder/VIDEO_TS");
    mkdir("$folder/AUDIO_TS"); # we can afford to try this
    # fix permissions
    system("chmod 0555 '$folder'");
    system("find '$folder' -type d -exec chmod 0555 {} \\; ");
    system("find '$folder' -type f -exec chmod 0444 {} \\; ");
    # make iso
    system("mkisofs -dvd-video -udf -o '$name' -V '$volumeid' '$folder'");
} else {
    system("mkisofs -J -r -v -o '$name' -V '$volumeid' '$folder' ");
}
#eof
