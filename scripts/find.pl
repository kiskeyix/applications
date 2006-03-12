#!/usr/bin/perl -w
# $Revision: 1.30 $
# Luis Mondesi < lemsx1@gmail.com >
#
# URL: http://www.kiskeyix.org/downloads/find.pl.gz
#
# DESCRIPTION: finds a string in a set of files
#
# USAGE: find.pl --replace="bar" "foo"
#        find.pl "string" ".*\.html"
#
# BUGS: if replacement string contains invalid characters
#       nothing gets done. Have to find a way to escape
#       all characters which might be used by Perl's
#       s/// operator
#
# LICENSE: GPL


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

die ( "Sorry. Can't search for (nul)" ) 
    if ( defined($this_string) and $this_string =~ m/^\s*$/ );

if ( defined($f_pattern) and $f_pattern =~ m#^[^\\]\.# )
{
    print STDERR "WARNING: using a dot in file pattern can match too many files. Escape dots with '\.'.\n Waiting 5 seconds before continuing\n Press CTRL+C to abort script execution\n" ;
    sleep(5);
}

if ( not defined($f_pattern) ) {
    print STDERR "All files chosen\n";
    $f_pattern = ".*";
}

$that_string = clean_string($that_string ) if ( defined($that_string) );
$this_string = clean_string($this_string );

if ( $DEBUG > 0 )
{
    print STDERR "search for: '$this_string' \n";
    print STDERR "replace with: '$that_string' \n" if (defined($that_string));
    print STDERR "file pattern: '$f_pattern' \n" if (defined($f_pattern));
    print STDERR "\n";
    print STDERR "$RED DEBUG in place... pausing for 5 seconds$NORM\n";
    sleep(5);
}

if ($this_string =~ /[[:alnum:]\.\_\-\(\)\[\]\{\}\"\']+/)
{
    my $i=0;
    @ls = do_file_ary("."); # start at current directory
    print STDERR ("File list: ",join(":",@ls),"\n") if ( $DEBUG ); 
    foreach my $_file (@ls)
    {
        # yes, this is a wrapper for a standard tip!
        #
        # open e/a file if it's a regular file
        # and replace $this_string with $that_string
        # if $that_string is set
        # and keep a backup .bak for e/a file modified
        #system("perl -e 'm/$this_string/g;' $_");
        # or 
        #system("perl -e 's/$this_string/$that_string/g;' -pi.bak $_");

        if ( $DEBUG ) { print STDERR "opening $_file\n"; }

        $i = 0;
        $modified = 0; # clear flag

        open (FILE,"<$_file") or die "could not open $_file. $!\n";
        if ( defined($that_string) )
        {
            while(<FILE>) {
                $i++;
                if ($_ =~ s|$this_string|$that_string|g) {
                    print STDOUT "$GREEN $_file [$i]:$NORM $_"; 
                    $modified = 1;
                }
                push @new_file,$_;
            }
            close(FILE);
            if ($modified) {
                open (NEWFILE,">$_file") 
                    or die "could not write to $_file. $!\n";
                print NEWFILE @new_file;
                close(NEWFILE);
            }
            # cleanup array
            @new_file = ();
        } else {
            while(<FILE>) { 
                $i++; 
                if ($_ =~ m|$this_string|gi) {
                    print STDOUT "$_file [$i]: $_"; 
                }
            }
            close(FILE);
        }
    } #end for
} else {
    print STDERR ($usage,"\n");
}

sub clean_string
{
    my $str = shift;
    return undef if ( not defined $str );

    $str =~ s,\|,\\|,g; # take care of |
    $str =~ s/\\$//g; # take care of ending \

    return $str;
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
    print STDERR ( "is_binary() called: $file\n" ) if ( $DEBUG );
    my $file_t = qx/file "$file"/;
    if ( $file_t =~ m/(text\s+executable|\btext\b)/i )
    {
        return 0;
    }
    print STDERR ( "binary file\n" ) if ( $DEBUG );
    return 1;
}

sub process_file {
    print STDERR ("Processing : ",$_,"\n") if ( $DEBUG );
    my $base_name = basename($_);
    if ( 
        $_ =~ m($f_pattern) and
        -f $_ and
        $base_name !~ m($EXCEPTION_LIST) and
        ! is_binary ($_)
    ) {
        s/^\.\/*//g;
        print STDERR ("Pushing : ",$_,"\n") if ( $DEBUG );
        push @ls,$_;
    }
}

