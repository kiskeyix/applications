#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Feb-08
# 
# Description: this script renames the files
# found in your ~/.loki/ut/Cache directory according to
# the cache.ini
# basically the cache.ini has the form:
#
# 32CEA6454874BE54DB65BC9E6F08C8EB=DM-Mountain_Man.unr
#
# this script takes the file:
# 32CEA6454874BE54DB65BC9E6F08C8EB.uxx
# and names it:
# DM-Mountain_Man.unr
#
# "cache.ini" exists in the current directory
#
# After renaming the files, it asks the user whether
# he/she wants to move them to the /usr/local/games/ut
# directory for all users :-)
#
use strict;
$|++;

# helper functions

sub detect_ut_dir
{
    if ( -d "/usr/local/games/ut" )
    {
        $ut_dir = "/usr/local/games/ut";
    } else {
        $ut_dir = prompt("Where is your Unreal Tournament installed? [DEFAULT: /usr/local/games/ut ] ");
    }
    return $ut_dir;
}

sub prompt
{
    #@param 0 string := question to prompt
    #returns answer
    print STDOUT "@_";
    my $rep= <STDIN>;
    chomp($rep);
    return $rep;
}

sub cleanup_cache_ini
{
    my $FLAG=0;
    $FLAG=1 if ( rename "cache.ini","cache.ini.$$.bak" );
    if ( $FLAG )
    {
        open(CACHE,">cache.ini");
        print CACHE "[Cache]\n";
        close(CACHE);
        print("File cache.ini has been cleared\n");
    }
    return $FLAG;
}

# main script

my $home_ut_dir = "$ENV{'HOME'}/.loki/ut/Cache";

$home_ut_dir = ( defined($ARGV[0]) ) $ARGV[0] : $home_ut_dir;

chdir("$home_ut_dir") or die("Could not change to dir $home_ut_dir");

open (my_file,"cache.ini");

while (<my_file>){
    chomp $_;
    # This removes other carriage returns...
    # darng dos files...
    # uncomment this on UNIX:
    $_ =~ s/\r//g;

    my ($old_name,$new_name) = split("=","$_");
    # rename cache name
    $old_name .= ".uxx";
    if ( -f $old_name ) {
        #system("mv $old_name.uxx $new_name");
        rename $old_name,$new_name;
    }
}

my $CACHE_CLEAN=0;

my $ut_dir = detect_ut_dir();
my $rep = prompt("Copy renamed files to $ut_dir [y/N] ");

if ( $rep =~ /^y/i )
{
    # TODO check if we have permission to write to $ut_dir
    system("/bin/mv *.u *.int $ut_dir/System/ ");
    print("System files were moved\n") if $?;
    system("/bin/mv *.utx $ut_dir/Textures/ ");
    print("Textures files were moved\n") if $?;
    system("/bin/mv *.unr $ut_dir/Maps/ ");
    print("Maps files were moved\n") if $?;
    system("/bin/mv *.umx $ut_dir/Music/ ");
    print("Music files were moved\n") if $?;
    system("/bin/mv *.uax $ut_dir/Sounds/ "); 
    print("Sounds files were moved\n") if $?;
    # we cleanup cache.ini
    $CACHE_CLEAN = cleanup_cache_ini();
}

if (!$CACHE_CLEAN)
{
    # we ask user to cleanup cache.ini if they didn't
    # want to move the files to $ut_dir automatically above
    my $rep = prompt("Do you want to cleanup cache.ini? [y/N] ");
    if ( $rep =~ /^y/i )
    {
        cleanup_cache_ini();
    } else {
        print("cache.ini left intact\n");
    }
}

