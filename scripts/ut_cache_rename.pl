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

# some globals
my $CACHE_CLEAN=0;
my $GREEN="\033[0;32m";
my $NORM="\033[0;39m";

# helper functions

sub detect_ut_dir
{
    my $ut_dir = "/usr/local/games/ut";
    if ( !-d "$ut_dir" )
    {
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
        print("$GREEN File cache.ini has been cleared $NORM\n");
    }
    return $FLAG;
}

# main script

# are we already in ~/.loki/ut/Cache? check for cache.ini
my $home_ut_dir = ( -f "cache.ini" ) ? "." : "$ENV{'HOME'}/.loki/ut/Cache";

chdir("$home_ut_dir") or die("Could not change to dir $home_ut_dir. $!");

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

my $ut_dir = detect_ut_dir();
my $rep = prompt("Copy renamed files to $ut_dir [y/N] ");

if ( $rep =~ /^y/i )
{
    # TODO check if we have permission to write to $ut_dir
    system("/bin/mv *.u *.int $ut_dir/System/ 2> /dev/null");
    print("$GREEN System files were moved $NORM\n") if ! $?;
    system("/bin/mv *.utx $ut_dir/Textures/ 2> /dev/null");
    print("$GREEN Textures files were moved $NORM\n") if ! $?;
    system("/bin/mv *.unr $ut_dir/Maps/ 2> /dev/null");
    print("$GREEN Maps files were moved $NORM\n") if ! $?;
    system("/bin/mv *.umx $ut_dir/Music/ 2> /dev/null");
    print("$GREEN Music files were moved $NORM\n") if ! $?;
    system("/bin/mv *.uax $ut_dir/Sounds/ 2> /dev/null"); 
    print("$GREEN Sounds files were moved $NORM\n") if ! $?;
    # we cleanup cache.ini
    $CACHE_CLEAN = cleanup_cache_ini();
}

if (!$CACHE_CLEAN)
{
    # we ask user to cleanup cache.ini if they didn't
    # want to move the files to $ut_dir automatically above
    my $crep = prompt("Do you want to cleanup cache.ini? [y/N] ");
    if ( $crep =~ /^y/i )
    {
        cleanup_cache_ini();
    } else {
        print("cache.ini left intact\n");
    }
}

