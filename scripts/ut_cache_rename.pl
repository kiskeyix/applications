#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Sep-03
# 
# Description: this script renames the files
# found in your Cache directory according to
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
use strict;
$|++;


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
