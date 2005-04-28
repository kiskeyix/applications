#!/usr/bin/perl -w
# $Revision: 1.26 $
# Luis Mondesi < lemsx1@gmail.com >
#
# URL: http://www.kiskeyix.org/downloads/find.pl.gz
#
# DESC: finds a string in a set of files
#
# USAGE: 
#   find.pl "string" ".*\.html"
#   find.pl --replace="bar" "foo"
#
# BUGS: if replacement string contains invalid characters
#       nothing gets done. Have to find a way to escape
#       all characters which might be used by Perl's
#       s/// operator
#


use File::Find;     # find();
use File::Basename; # basename();
use Getopt::Long;
Getopt::Long::Configure('bundling');

use strict;
$|++;

my $DEBUG = 0;

my $EXCEPTION_LIST = "\.soc\$|\.sock\$|\.so\$|\.o\$|\.swp\$";

# some colors:

my $RED = "\033[1;31m";
my $NORM = "\033[0;39m";
my $GREEN = "\033[0;32m";
my $BLUE = "";

# -------------------------------------------------------------------
#           NO NEED TO MODIFY ANYTHING PASS THIS LINE               #
# -------------------------------------------------------------------

my $usage = "Usage: find.pl [--replace=\"string\"] \"string\" [\"FILE_REGEX\"]\n NOTE use quotes to avoid the shell expanding your REGEX";
my $modified = 0;

my $thisFile = "";      # general current file
my @new_file = ();      # lines to be printed in new file
my @ls = ();            # array of files

my $this_string=undef;
my $that_string=undef;
my $f_pattern = undef;

GetOptions(
    # flags
    #'v|version'         =>  \$PVERSION,
    #'h|help'            =>  \$HELP,
    'D|debug'           =>  \$DEBUG,
    # strings
    'r|replace=s'      =>   \$that_string
) and $this_string = shift and $f_pattern = shift;

die ( "Sorry. Can't search for (nul)" ) if ( defined($this_string) and $this_string =~ m/^\s*$/ );

if ( defined($f_pattern) and $f_pattern =~ m(^\.) )
{
    print "WARNING: using a dot in file pattern can match too many files. Escape dots with '\.'.\n Waiting 5 seconds before continuing\n Press CTRL+C to abort script execution\n" ;
    sleep(5);
}

if (! defined($f_pattern) ) {
    print STDERR "All files chosen\n";
    $f_pattern = ".*";
}

if ( $DEBUG > 0 )
{
    print "s: '$this_string' r: '$that_string' f: '$f_pattern'\n";
    print STDERR "$RED DEBUG in place... pausing for 10 seconds$NORM\n";
    sleep(10);
}

if ($this_string =~ /\w/) {
    my $i =0;
    @ls = do_file_ary("."); # start at current directory
    
    for (@ls) {
        # yes, this is a wrapper for a standard tip!
        #
        # open e/a file if it's a regular file
        # and replace $this_string with $that_string
        # if $that_string is set
        # and keep a backup .bak for e/a file modified
    
        if ($DEBUG) {print STDERR "opening $_\n"; }
        
        #system("perl -e 'm/$this_string/g;' $_");
        # or 
        #system("perl -e 's/$this_string/$that_string/g;' -pi.bak $_");

        $thisFile = $_;

        $i = 0;
        $modified = 0; # clear flag

        open (FILE,"<$thisFile") or die "could not open $thisFile. $!\n";
        if ( defined($that_string) )
        {
            while(<FILE>) {
                $i++;
                if ($_ =~ s($this_string)($that_string)g) {
                    print STDOUT "$GREEN $thisFile [$i]:$NORM $_"; 
                    $modified = 1;
                }
                push @new_file,$_;
            }
            close(FILE);

            if ($modified) {
                open (NEWFILE,">$thisFile") 
                    or die "could not write to $thisFile. $!\n";
                print NEWFILE @new_file;
                close(NEWFILE);
            }

            # cleanup array
            @new_file = ();

        } else {
            while(<FILE>) { 
                $i++; 
                if ($_ =~ m($this_string)gi) {
                    print STDOUT "$thisFile [$i]: $_"; 
                }
            }
            close(FILE);

        }

    } #end for
} else {
    print $usage;
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

sub is_binary
{
    # returns 1 if true
    my $file = shift;
    my $file_t = qx/file "$file"/;
    if ( $file_t =~ m/(text\s+executable|\s+text\s+)/i )
    {
        return 0;
    }
    return 1;
}

sub process_file {
    my $base_name = basename($_);
    if ( 
        $_ =~ m($f_pattern) &&
        -f $_ && 
        $base_name !~ m($EXCEPTION_LIST) &&
        ! is_binary ($_)
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
