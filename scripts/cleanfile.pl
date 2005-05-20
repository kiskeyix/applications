#!/usr/bin/perl -w
# $Revision: 1.1 $
# $Date: 2005-05-20 15:55:40 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESC: A script to find a string in a file and replaces it with another one
#
# USAGE: 
#   cleanfile.pl "string" file [file2 file3 ... ]
#
# EXAMPLES: 
#   cleanfile.pl "string" filename  filename2 # replaces "string" with "" in filename and filename2
#   cleanfile.pl --replace="bar" "foo" filename # replaces "string" with "bar" in filename
#
# BUGS: if replacement string contains invalid characters
#       nothing gets done. Have to find a way to escape
#       all characters which might be used by Perl's
#       s/// operator
#


#use File::Find;     # find();
use File::Basename; # basename();
use Getopt::Long;
Getopt::Long::Configure('bundling');

use strict;
$|++;

my $DEBUG = 0;
my $VERBOSE = 0;

# some colors:

my $RED = "\033[1;31m";
my $NORM = "\033[0;39m";
my $GREEN = "\033[0;32m";
my $BLUE = "";

# -------------------------------------------------------------------
#           NO NEED TO MODIFY ANYTHING PASS THIS LINE               #
# -------------------------------------------------------------------

my $usage = "Usage: cleanfile.pl [--verbose] [--replace=\"string\"] \"string\" file [file2 file3 ...]\n".
            "NOTE use quotes to avoid the shell expanding your REGEX\n";
my $this_string=undef;
my $that_string="";

GetOptions(
    'D|debug'       =>  \$DEBUG,
    'V|verbose'     =>  \$VERBOSE,
    'r|replace=s'   =>  \$that_string
) and $this_string = shift;

# sanity checks
warn ( "Replacing with empty string\n" ) if ( ! defined($that_string) );

die ( "$usage.\nSorry. Can't search for (nul)\n" ) if ( ! defined($this_string) 
    or $this_string =~ m/^\s*$/ );

if ($this_string =~ /.+/)
{
    # go through any number of files passed from the command line
    foreach my $_file ( @ARGV )
    {
        print STDERR "doing $_file\n" if ( $DEBUG );
        if ( ! -r $_file ) 
        {
            print STDERR ("Not a valid file name: '$_file'\n");
            print STDERR ("Do you have read permissions for it?\n");
            next;
        }
        my $i =0;
        # yes, this is a wrapper for a standard tip!
        #
        #system("perl -e 'm/$this_string/g;' $_");
        # or 
        #system("perl -e 's/$this_string/$that_string/g;' -pi.bak $_");
        #
        # algorithm:
        # open file if it's a regular file
        # and replace $this_string with $that_string
        # and keep a backup .bak for e/a file modified

        open (FILE,"<$_file") or die "could not open $_file. $!\n";
        die ("Cannot truncate $_file.new. Please remove or rename this file first\n") if ( -f "$_file.new" );
        open (NEWFILE,">$_file.new") 
            or die "could not write to $_file.new. $!\n";
        while(<FILE>) {
            $i++;
            if ($_ =~ s($this_string)($that_string)g) {
                print STDOUT "$GREEN $_file [$i]:$NORM $_" if ( $VERBOSE );
            }
            print NEWFILE $_;
        }
        close(FILE);
        close(NEWFILE);

        # make a backup of file
        if ( rename($_file,"$_file.bak") )
        {
            # move .new to filename
            if ( ! rename("$_file.new",$_file) )
            {
                die("Could not rename $_file.new to $_file. $!\n");
            }
        } else {
            die ("Could not save a backup for $_file. $!\n");
        }
    }
} else {
    print STDERR ($usage);
}
