#!/usr/bin/perl -w
# $Revision: 1.32 $
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

use File::Find;        # find();
use File::Basename;    # basename();
use Getopt::Long;
Getopt::Long::Configure('bundling');

use strict;
$|++;

my $DEBUG = 0;

my $EXCEPTION_LIST = "(\\.soc|\\.sock|\\.so|\\.o|\\.swp)\$";

# some colors:

my $RED   = "\033[1;31m";
my $NORM  = "\033[0;39m";
my $GREEN = "\033[0;32m";
my $BLUE  = "\033[0;34m";

# -------------------------------------------------------------------
#           NO NEED TO MODIFY ANYTHING PASS THIS LINE               #
# -------------------------------------------------------------------

my $usage =
  "Usage:\nfind.pl [-i,--ignore-case] [-f,--file-pattern=\"REGEX\"] [-r,--replace=\"replacement\"] <-s,--string=\"string\">\nfind.pl <\"string to find\"> [\"REGEX file pattern\"] [\"replacement string\"]\n\nNOTE use quotes to avoid the shell expanding your REGEX\n\n";

my $this_string = undef;
my $that_string = undef;
my $f_pattern   = undef;
my $IGNORECASE  = 0;

GetOptions(

    'D|debug'          => \$DEBUG,
    'f|file-pattern=s' => \$f_pattern,
    's|string=s'       => \$this_string,
    'r|replace=s'      => \$that_string,
    'i|ignore-case'    => \$IGNORECASE,
  )
  and (not defined $this_string and $this_string = shift)
  and (not defined $f_pattern   and $f_pattern   = shift)
  and (not defined $that_string and $that_string = shift);

print STDERR ($usage) and die("Sorry. Can't search for (nul)\n")
  if (not defined($this_string) or $this_string =~ m/^\s*$/);

if (defined($f_pattern) and $f_pattern =~ m#^[^\\]\.#)
{
    print STDERR
      "WARNING: using a dot in file pattern can match too many files. Escape dots with '\.'.\n Waiting 5 seconds before continuing\n Press CTRL+C to abort script execution\n";
    sleep(5);
}

if (not defined($f_pattern))
{
    print STDERR "All files chosen\n";
    $f_pattern = ".*";
}

$that_string = _clean_string($that_string) if (defined($that_string));
$this_string = _clean_string($this_string);

if ($DEBUG > 0)
{
    print STDERR "search for: '$this_string' \n";
    print STDERR "replace with: '$that_string' \n" if (defined($that_string));
    print STDERR "file pattern: '$f_pattern' \n"   if (defined($f_pattern));
    print STDERR "\n";
    print STDERR "$RED DEBUG in place... pausing for 5 seconds$NORM\n";
    sleep(5);
}

# main()
if ($this_string =~ /[[:alnum:]\.\_\-\(\)\[\]\{\}\"\']+/)
{
    _process_files(".");
}
else
{
    print STDERR ($usage);
    exit 1;
}
exit 0;

# supporting functions

sub _clean_string
{
    my $str = shift;
    return undef if (not defined $str);

    $str =~ s,\|,\\|,g;    # take care of |
    $str =~ s/\\$//g;      # take care of ending \

    return $str;
}

sub _process_files
{

    # uses find() to recur thru directories
    my $ROOT = shift;

    my %opt = (wanted => \&_process_file, no_chdir => 1);

    find(\%opt, $ROOT);
}

sub _is_binary
{

    # returns 1 if true
    my $file = shift;
    print STDERR ("is_binary() called: $file\n") if ($DEBUG);
    my $file_t = qx/file "$file"/; # FIXME very expensive call. re-write in Perl
    if ($file_t =~ m/(text\s+executable|\btext\b|\s+script\b)/i)
    {
        return 0;
    }
    print STDERR ("binary file\n") if ($DEBUG);
    return 1;
}

sub _process_file
{
    print STDERR ("Processing : ", $_, "\n") if ($DEBUG);
    if (    $_ =~ m($f_pattern)
        and -r $_
        and basename($_) !~ m($EXCEPTION_LIST)
        and !_is_binary($_))
    {
        my $_file = $_;
        print STDERR ("opening $_file\n") if ($DEBUG);
        my $_file_tmp = "$_file.$$.tmp";

        my $modified = 0;
        my $i        = 0;

        if (-f $_file_tmp)
        {
            unlink($_file_tmp)
              or die("Could not remove file $_file_tmp. $!\n");
        }

        open(FILE, "<$_file") or die "could not open $_file. $!\n";
        while (<FILE>)
        {
            $i++;
            if (defined($that_string))
            {
                # TODO cleanup
                if ($IGNORECASE and ($_ =~ s|$this_string|$that_string|gi))
                {
                    my $_local = $_;    # beautify display
                    $_local =~ s/^\s+//;
                    print STDOUT "$GREEN $_file [$i]:$NORM $_local";
                    $modified = 1;
                }
                elsif ($_ =~ s|$this_string|$that_string|g)
                {
                    my $_local = $_;    # beautify display
                    $_local =~ s/^\s+//;
                    print STDOUT "$GREEN $_file [$i]:$NORM $_local";
                    $modified = 1;
                }
                open(NEWFILE, ">>$_file_tmp")
                  or die("could not write to $_file_tmp. $!\n");
                print NEWFILE $_;
                close(NEWFILE);
            }
            else
            {
                # TODO cleanup
                if ($IGNORECASE
                    and ($_ =~ m|$this_string|gi))
                {
                    my $_local = $_;
                    $_local =~ s/^\s+//;    # beautify display
                    print STDOUT "$BLUE $_file [$i]:$NORM $_local";
                }
                elsif ($_ =~ m|$this_string|g)
                {
                    my $_local = $_;
                    $_local =~ s/^\s+//;    # beautify display
                    print STDOUT "$BLUE $_file [$i]:$NORM $_local";
                }
            }
        }
        close(FILE);
        if ($modified)
        {
            if (-r "$_file_tmp")
            {
                rename("$_file_tmp", $_file);
            }
            else
            {
                die("Cannot read file $_file_tmp eventhough we created it? $!\n"
                );
            }
            $modified = 0;    # just in case...
        }

        # cleanup
        if (-f $_file_tmp)
        {

            #DEBUG warn "Removing left-over file $_file_tmp\n";
            unlink($_file_tmp)
              or die("Could not remove file $_file_tmp. $!\n");
        }
    }
}

