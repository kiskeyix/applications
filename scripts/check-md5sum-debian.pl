#!/usr/bin/perl -w
# $Revision: 1.3 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Sep-25
#
# DESCRIPTION: simple script to check md5sum of all
#               debian installed files. If a --binary
#               flag is given, it will check only binaries.
#               If --md5sum="" is given, it will use that
#               binary to check md5sum's.
#               Output will be printed to STDOUT unless
#               --log="/path/to/file.log" is given.
#
#               Note that if you don't have read access to
#               files/binaries then you might need to run
#               this with a different user who has permission
#               to read those binaries or files.
#
# NOTE: later discovered "debsums" perl script which essentially
#       does the same in a simpler and nicer way... use that instead.
# 
# USAGE:    $0 [-b|--binary] [-l|--log] [-m|--md5sum]
# CHANGELOG:
#

use File::Find;     # find();
use File::Basename; # basename();
use FileHandle;

use strict;
$|++;

use Getopt::Long;
Getopt::Long::Configure('bundling');

my $MD5SUM = ""; 
eval "use Digest::md5sum";
if ($@)
{
    print STDERR "\n ERROR: Digest::Md5sum was not found\n".
    "           Trying to find a valid 'md5sum' binary\n\n";
    
    if ( -x "/sbin/md5sum" ) 
    {
        $MD5SUM = "/sbin/md5sum";
    } elsif ( -x "/usr/sbin/md5sum" ) {
        $MD5SUM = "/usr/sbin/md5sum";
    } elsif ( -x "/usr/bin/md5sum" ) {
        $MD5SUM = "/usr/bin/md5sum";
    } elsif ( -x "/bin/md5sum" ) {
        $MD5SUM = "/bin/md5sum";
    } elsif ( -x "/usr/local/sbin/md5sum" ) {
        $MD5SUM = "/usr/local/sbin/md5sum";
    } elsif ( -x "/usr/local/bin/md5sum" ) {
        $MD5SUM = "/usr/local/bin/md5sum";
    }
    
    # sanity check
    if ( $MD5SUM ne "" ) 
    {
        print STDERR "\n WARN: Using $MD5SUM\n";
    } else {
        print STDERR "\n ERROR: no suitable 'md5sum' found.";
        exit(1);
    }
}

# list of files we should not check for
# note that only .md5sum files are checked anyway
my $EXCEPTION_LIST = "\.txt\$|\.rtf\$";

my $DEBIAN_INFO = "/var/lib/dpkg/info";
my $BIN_FLAG = 0; # search for binaries only

my $OUTPUT="STDOUT"; # output to, unless LOG is passed
my $LOG = ""; # log file (command line)

my ($tmp_md5sum, $tmp_file) = "";

GetOptions(
    # flags
    'b|binary'      =>  \$BIN_FLAG,
    'm|md5sum=s'    =>  \$MD5SUM,
    'l|log'         =>  \$LOG
);

if ( $LOG gt "" )
{
    $OUTPUT = new FileHandle;
    $OUTPUT->open("> $LOG");
    $OUTPUT->autoflush(1);
}  
#else {
#    $OUTPUT->open("STDOUT");
#}

main();

# functions
sub main {
    # get all md5sum files into @md5sumfiles
    my @files = do_file_ary($DEBIAN_INFO);

    my $this_md5sum=""; # current file md5sum 

    # debug
    #print join(" ",@files);

    foreach my $file (@files) 
    {
        if ( open(FILE,$file) )
        {
            while (<FILE>) 
            {
                chomp;
                ($tmp_md5sum,$tmp_file) = split(/\s+/,$_);

                $tmp_file = "/$tmp_file"; # prepend slash

                if ( $BIN_FLAG > 0 ) {
                    # we only care about binaries here
                    if ( -x "$tmp_file" ) 
                    {
                        $this_md5sum = get_md5sum($tmp_file);
                        #print STDOUT "DEBUG: $tmp_file\n -> $this_md5sum\n -> $tmp_md5sum\n";
                        if ($tmp_md5sum ne $this_md5sum)
                        {
                            if ( $OUTPUT eq "STDOUT" )
                            {
                                # is there a simpler way of checking
                                # this?
                                print STDOUT "\nWARN: $tmp_file \nNEW: [$this_md5sum] \nOLD: [$tmp_md5sum]";
                            } else {
                                print $OUTPUT "\nWARN: $tmp_file \nNEW: [$this_md5sum] \nOLD: [$tmp_md5sum]";
                            }
                        }
                    }
                } else {
                    # check all files
                    $this_md5sum = get_md5sum($tmp_file);
                    if ($tmp_md5sum ne $this_md5sum)
                    {
                        if ( $OUTPUT eq "STDOUT" )
                        {
                            # is there a simpler way of checking
                            # this?
                            print STDOUT "\nWARN: $tmp_file \nNEW: [$this_md5sum] \nOLD: [$tmp_md5sum]";
                        } else {
                            print $OUTPUT "\nWARN: $tmp_file \nNEW: [$this_md5sum] \nOLD: [$tmp_md5sum]";
                        }
                    }
                } #end if/else bin_flag
            } #end while
        } else {
            print STDERR "\n ERROR: Could not open $file";
        } #end if/else open
    } #end foreach
}

sub get_md5sum {
    my $file = shift;
    my ($str,$this_file) = "";

    # prefer to use md5sum binary
    # if one was passed in command line
    # or found after failing to import
    # Digest::Md5sum module
    if ( $MD5SUM gt "" ) {
        if ( -r $file ) {
            # usually first field is md5sum
            ($str,$this_file) = split(/\s+/,qx/$MD5SUM $file/);
        } else {
            # unable to read file, permission?
            $str  = "00000000000000000000000000000000";
        }
    } 
    # try to create a new md5sum object and
    # proceed
    #elsif ( ) {}
    return $str;
}

my @md5sumfiles = ();
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
    return @md5sumfiles;
} # end do_file_ary

sub process_file {
    my $base_name = basename($_);
    if  ( 
        -f $_ 
        && $base_name !~ m/^($EXCEPTION_LIST)$/
        && $base_name !~ m/^\.[a-zA-Z0-9]+$/ 
        && $_ =~ m/(.*\.md5sums)$/
        ) 
    {
        s/^\.\/*//g;
        push @md5sumfiles,$_;
    }
}
