#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jan-16
#
# DESC: finds a string in a set of files
#
# USAGE: 
#   find_infile.pl "string" "\.html"
#
use strict;
$|++;

my $DEBUG = 0;

# -------------------------------------------------------------------
#           NO NEED TO MODIFY ANYTHING PASS THIS LINE               #
# -------------------------------------------------------------------

my $usage = "Usage: find_infile.pl \"string\" \"FILE_PATTERN\"\n";

my $thisFile = "";      # general current file
my @new_file = ();      # lines to be printed in new file
my @ls = ();            # array of files

my ($this_string,$f_pattern) = @ARGV;

if (!$ARGV[0] || !$ARGV[1]) {
    print STDERR $usage;
    exit 1;
}

if ($this_string =~ /\w/ 
    && $f_pattern =~ /\w/) {

    my $i =0;
    
    file_ary("."); # start at current directory
    
    for (@ls) {
        # yes, this is a wrapper for a standard tip!
        #
        # open e/a file if it's a regular file
        # and find $this_string
    
        if ($DEBUG) {print STDERR "opening $_\n"; }
        
        #system("perl -e 'm/$this_string/g;' $_");
        
        $thisFile = $_;

        $i = 0;

        open (FILE,"<$thisFile") or die "could not open $thisFile. $!\n";
        while(<FILE>) {
            
            if ($_ =~ m($this_string)g) {
                print STDOUT "$thisFile [$i]: $_"; 
            }

            $i++;
        }
        close(FILE);

    }
}

sub file_ary {
    
    my $dir = $_[0];
    my @subdir = ();

    if ($DEBUG) { print STDOUT "dir $dir\n"; }
    
    opendir (DIR,"$dir") || die "Couldn't open current directory. $!\n";

    #construct array of all files and put in @ls
    while (defined($thisFile = readdir(DIR))) {
        next if ($thisFile =~ /^\..*/);
        next if ($thisFile !~ /\w/);
        if (-d "$dir/$thisFile") {
            push @subdir,"$dir/$thisFile"; 
            next;
        }
        next if ($thisFile !~ m/$f_pattern/i);
        
        if ($DEBUG) { print STDERR "this file $thisFile\n"; }
        
        push @ls, "$dir/$thisFile";
    }
    closedir(DIR);

    # recur thru rest of directories
    # there is no limit in recursion. be careful!
    foreach(@subdir) {
        file_ary("$_");
    }
}
