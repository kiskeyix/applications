#!/usr/bin/perl -w
# $Revision: 1.13 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jul-17
#
# DESC: finds a string in a set of files
#
# USAGE: 
#   find_infile.pl "string" ".*\.html"
#

use File::Find;     # find();
use File::Basename; # basename();

use strict;
$|++;

my $DEBUG = 0;

my $EXCEPTION_LIST = "\.soc\$|\.sock\$|\.so\$|\.o\$|\.swp\$";

# -------------------------------------------------------------------
#           NO NEED TO MODIFY ANYTHING PASS THIS LINE               #
# -------------------------------------------------------------------

my $usage = "Usage: find_infile.pl \"string\" [\"FILE_REGEX\"]\n NOTE use quotes to avoid the shell expanding your REGEX";

my $thisFile = "";      # general current file
my @new_file = ();      # lines to be printed in new file
my @ls = ();            # array of files

if (!$ARGV[0]) {
    print STDERR $usage;
    exit 1;
}

my ($this_string,$f_pattern) = @ARGV;

if ( defined $f_pattern && $f_pattern =~ m(^\.) ) {
    print "WARNING: using a dot in file pattern can match too many files. Escape dots with '\.'.\n Waiting 5 seconds before continuing\n Press CTRL+C to abort script execution\n" ;
    sleep(5);
}

if (!$ARGV[1]) {
    print STDERR "All files chosen\n";
    $f_pattern = ".*";
}

print "s: '$this_string' f: '$f_pattern'\n" if ($DEBUG != 0);

if ($this_string =~ /\w/) {

    my $i =0;
    
    @ls = do_file_ary("."); # start at current directory
    
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
            
            if ($_ =~ m($this_string)gi) {
                print STDOUT "$thisFile [$i]: $_"; 
            }

            $i++;
        }
        close(FILE);

    }
}

sub do_file_ary {
    # uses find() to recur thru directories
    # returns an array of files
    # i.e. in directory "a" with the files:
    # /a/file.txt
    # /a/b/file-b.txt
    # /a/b/c/file-c.txt
    # /a/b2/c2/file-c2.txt
    # 
    # my @ary = &do_file_ary(".");
    # 
    # will yield:
    # a/file.txt
    # a/b/file-b.txt
    # a/b/c/file-c.txt
    # a/b2/c2/file-c2.txt
    # 
    my $ROOT = shift;
    
    my %opt = (wanted => \&process_file, no_chdir=>1);
    
    find(\%opt,$ROOT);
    
    return @ls;
}

sub process_file {
    my $base_name = basename($_);
    if ( 
        $_ =~ m($f_pattern) &&
        -f $_ && 
        $base_name !~ m($EXCEPTION_LIST)
    ) {
        s/^\.\/*//g;
        push @ls,$_;
    }
}

# without using Find
#sub file_ary {
#    
#    my $dir = $_[0];
#    my @subdir = ();
#
#    if ($DEBUG) { print STDOUT "dir $dir\n"; }
#    
#    opendir (DIR,"$dir") || die "Couldn't open current directory. $!\n";
#
#    #construct array of all files and put in @ls
#    while (defined($thisFile = readdir(DIR))) {
#        next if ($thisFile !~ /\w/);
#        if (-d "$dir/$thisFile") {
#            # we don't care about directories . and ..
#            next if ($thisFile =~ /^\.{1,2}$/);
#            push @subdir,"$dir/$thisFile"; 
#            next;
#        }
#        # is file a plain text (ASCII) file?
#        next unless (-f "$dir/$thisFile" && -T "$dir/$thisFile");
#       
#        # do we want specific file extensions?
#        no warnings;
#        if ( $f_pattern gt "" ) {
#            next if ($thisFile !~ m/$f_pattern/i);
#        }
#        
#        if ($DEBUG) { print STDERR "this file $thisFile\n"; }
#        
#        push @ls, "$dir/$thisFile";
#    }
#    closedir(DIR);
#
#    # recur thru rest of directories
#    # there is no limit in recursion. be careful!
#    foreach(@subdir) {
#        file_ary("$_");
#    }
#}
