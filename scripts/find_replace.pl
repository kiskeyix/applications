#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jan-08
#
use strict;
$|++;

my $DEBUG = 1;

# -------------------------------------------------------------------
#           NO NEED TO MODIFY ANYTHING PASS THIS LINE               #
# -------------------------------------------------------------------

my $modified = 0;

my $usage = "Usage: find_replace.pl \
    \"string\" \"replacement\" \"filenames_pattern\"\n";

my $thisFile = "";
my @new_file = ();

my ($this_string,$that_string,$f_pattern) = @ARGV;

if (!$ARGV[0] || !$ARGV[1] || !$ARGV[2]) {
    print STDERR $usage;
    exit 1;
}

if ($this_string =~ /\w/ 
    && $that_string =~ /\w/ 
    && $f_pattern =~ /\w/) {

    opendir (DIR,".") || die "Couldn't open current directory. $!\n";

    my @ls = ();
    my $x = 0;

#construct array of all files
    while (defined($thisFile = readdir(DIR))) {
        next if (-d "./$thisFile");
        next if ($thisFile !~ /\w/);
        next if ($thisFile !~ m/$f_pattern/i);
        
        if ($DEBUG) { print STDERR "this file $thisFile\n"; }
        
        $ls[$x] = $thisFile;
        $x+=1;
    }
    closedir(DIR);

# cleanup this_string and that_string
# escaping @

$this_string  =~ s/@/\@/g;
$that_string  =~ s/@/\@/g;

my $i =0;
    for (@ls) {
        # yes, this is a wrapper for a standard tip!
        #
        # open e/a file if it's a regular file
        # and replace $this_string with $that_string
        # and keep a backup .bak for e/a file modified
    
        if ($DEBUG) {print STDERR "opening $_\n"; }
        
        #system("perl -e 's/$this_string/$that_string/g;' -pi.bak $_");
        
        $thisFile = $_;

        $i = 0;
        $modified = 0; # clear flag

        open (FILE,"<$thisFile") or die "could not open $thisFile. $!\n";
        while(<FILE>) {
            
            if ($_ =~ s/$this_string/$that_string/g) {
                print STDOUT "$thisFile [$i]: $_"; 
                $modified = 1;
            }

            push @new_file,$_;

            $i++;
        }
        close(FILE);

        if ($modified) {
            open (NEWFILE,">$thisFile") 
                or die "could not write to $thisFile. $!\n";
            print NEWFILE @new_file;
            close(NEWFILE);
        }

    }
}
