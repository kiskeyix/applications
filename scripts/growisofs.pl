#!/usr/bin/perl -w
# $Revision: 1.2 $
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

# we unset sudo variables and then set mkisofs path:
$ENV{"SUDO_COMMAND"} = "" if $ENV{"SUDO_COMMAND"} ne "";
$ENV{"MKISOFS"} = "/usr/bin/mkisofs" if $ENV{"MKISOFS"} ne "";

my $dvd = "/dev/dvd";
my $cmd="";
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
    $cmd = "growisofs -dvd-compat -Z /dev/dvd=$file";
    system( $cmd );
    if ( $? != 0 )
    {
        perror("$cmd failed! Could not create DVD from image $file");
    }
} elsif ( -d $file ) {
    # TODO check for VOB files inside $file/VIDEO_TS
    if ( -d "$file/VIDEO_TS" )
    {
        # see man mkisofs for -r -J
        $cmd = "growisofs -dvd-compat -Z /dev/dvd -r -J $file";
        system( $cmd );
        if ( $? != 0 )
        {
            perror("$cmd failed! Could not be create DVD from directory $file");
        }
    } else {
        perror("$file is not a valid DVD structure.");
        my $ret = prompt("Do you want to make a backup of this directory? [y/N]");
        if ( $ret == "y" )
        {
            $cmd = "growisofs -Z /dev/dvd -r -J $file";
            system( $cmd );
            if ( $? != 0 )
            {
                perror("$cmd failed! Could not backup $file");
            }
        } else {
            perror("aborting...");
        }
    }
}
