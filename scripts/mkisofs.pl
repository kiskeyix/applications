#!/usr/bin/perl -w
# a quick nautilus script to make isos... 
# Just select the directory you want and choose this script
# from the nautilus script menu.

$DEBUG=0;

# You could get only the selected files from nautilus, but
# it's better to let the user put all those files in 
# a single directory and then run this script on that directory
# $ENV{"NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"}

chomp($ARGV[0]); # remove end-line

# Volume id needs no spaces or other characters
( $volumeid = $ARGV[0] ) =~ s,[\s-]+,_,g;
# put a .iso extension
( $name = $ARGV[0] ) =~ s,(.+),$1.iso,;

print "Argument: $ARGV[0] | Volume Name: $volumeid | FileName: $name\n" if $DEBUG == 1;
sleep(5) if $DEBUG == 1;
system("mkisofs -J -r -v -o '$name' -V '$volumeid' ".$ARGV[0]);

#eof
