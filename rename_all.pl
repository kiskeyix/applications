#!/usr/bin/perl -w
# $Id: rename_all.pl,v 1.1 2002-11-07 06:26:41 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Nov-07
#
# Description: 
# Use this script to rename a bunch of files in the current
# directory to a given name.
#
# YOU SHOULD BACKUP YOUR DATA BEFORE USING THIS SCRIPT
#
# Usage:
# rename_all.pl -p"REGEX NAMEPATTERN" -s"NAMESEQUENCE"
# 
# i.e. the command:
# rename_all.pl -p".*\.jpg" -s"%D.jpg"
# will rename all files in the current directory
# in the form: 1.jpg, 2.jpg, 3.jpg, ..., n.jpg
# 
# You can also do things like:
# rename_all.pl -p".*.jpg" -s"file-%D.jpg"
# rename_all.pl -p".*.jpg" -s"%W-%D.jpg"
#
# %D == digits
# %W == text (use actual name. Combine with %D or other sequence)
# 
# the command:
# rename_all -p".*\+.*" -r"plus" with replace the + signs with the string
# "plus" 
#
use strict;
$|++;


my $PATTERN = "";
my $STRING = "";
my $REPLACE = "";

# get arguments
while ( $_ = ( $ARGV[0] ) ? $ARGV[0] : "" , /^-/) {
    shift;
    last if /^--$/;
    if (/^-+p(.*)/) { $PATTERN=$1; }
    elsif (/^-+s(.*)/) { $STRING=$1; } 
    elsif (/^-+r(.*)/) { $REPLACE=$1; }
    else {
        print STDERR "Usage: \n";
    }
} 

# returns list of files containing
# $pat in path
sub list_all(my $pat,my $dir) {
    my @ls;

    opendir (DIR,"$dir") || die "Couldn't open dir $dir \n";

    #construct array of all files
    while (defined($thisFile = readdir(DIR))) {
        next if (-d "$dir/$thisFile");
        next if ($thisFile !~ /\w/);
        next if ($thisFile !~ m/$pat/i);
        # stack file
        push($ls, $thisFile);
    }
    closedir(DIR);
    
    return @ls;
}

# creates a especially named file
# 
sub substitute(my $pat,my $str){
}

# replaces strings in files which
# you don't want
sub replace(my $pat,my $str){
    my $new_str; # new filename

    # get a list of all files which contain
    # $pat in current directory
    my @list = list_all($pat,".");

    foreach(@list) {
        # remove $str from file name ($pat) and put
        # resulting string in $new_str
        ($new_str = $_) =~ s/$pat/$_/;
    
        # rename all files with $pat
        # with new name now in $new_str
        rename($_,$new_str);
    
    }
}

# main routine
sub main {
    # determine what to call
    if ($PATTERN eq "") { exit(1); }
    else {
        
        if ( $STRING ne "" ) {
            substitute($PATTERN,$STRING);
            exit(0);
        }
        if ( $REPLACE ne "" ) {
            replace($PATTERN,$REPLACE);
            exit(0);
        }
    
        # we should never get here...
        print STDERR "You have to supply a string or pattern to rename files with. -s'string' or -r'string' \n";
    
    }
}

main
