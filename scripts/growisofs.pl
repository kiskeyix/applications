#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Oct-31
#
# DESCRIPTION: Automatically detects how do you want to run growisofs. This would make growisofs work even for "sudo" (@#$#@$) 
# USAGE: $0 file.iso or $0 DVD_TREE_FROM_DVDAUTHOR or $0 DIRECTORY_TO_BACKUP
# 
# LICENSE: GPL (latest version)
#
use strict;
$|++;
my $file = shift;

my $dvd = "/dev/dvd";

my $RED="\033[1;31m";
my $GREEN="\033[0;32m";
my $NORM="\033[0;39m";

sub perror
{
    print STDERR "$RED @_ $NORM\n";
}

sub prompt
{
    #@param 0 string := question to prompt
    #returns answer
    print STDOUT "$GREEN @_ $NORM";
    my $rep= <STDIN>;
    chomp($rep);
    return $rep;
}

# If environmental variable DVD exists, use this device
if ( $ENV{"DVD"} =~ /\/dev\// and -b $ENV{"DVD"} )
{
    $dvd = $ENV{"DVD"}; 
    perror("Using dvd drive $dvd");
}

if ( $file =~ /\.iso$/i )
{
    system("growisofs -dvd-compat -Z /dev/dvd=$file");
    if ( $? != 0 )
    {
        perror("Creating DVD from $file failed!");
    }
} else if ( -d $file ) {
    # TODO check for VOB files inside $file/VIDEO_TS
    if ( -d "$file/VIDEO_TS" )
    {
        # see man mkisofs for -r -J
        my $cmd = "growisofs -dvd-compat -Z /dev/dvd -r -J $file";
        system( $cmd );
        if ( $? != 0 )
        {
            perror("$file DVD could not be created!");
        }
    } else {
        perror("$file is not a valid DVD structure.");
        ret = prompt("Do you want to make a backup of this directory? [y/N]");
        if ( $ret == "y" )
        {
            my $cmd = "growisofs -Z /dev/dvd -r -J $file"
            system($cmd);
            if ( $? != 0 )
            {
                perror("Backup creation failed!");
            }
        } else {
            perror("aborting...");
        }
    }
}
