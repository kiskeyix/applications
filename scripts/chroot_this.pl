#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: set up a chroot environment for a binary
# USAGE: cd /chroot/path && $0 /path/to/program
# LICENSE: GPL

use strict;
$|++;

my $revision = "1.0"; # version

# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');
#use POSIX;                  # cwd() ... man POSIX
use File::Spec::Functions qw/splitdir catdir/;  # abs2rel() and other dir/filename specific
use File::Copy;     # copy() and move()
#use File::Find;     # find();
use File::Basename; # basename() && dirname()
#use FileHandle;     # for progressbar

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;
# get options
GetOptions(
    # flags
    'v|version'         =>  \$PVERSION,
    'h|help'            =>  \$HELP,
    'D|debug'           =>  \$DEBUG,
    # strings
    #'o|option=s'       =>  \$NEW_OPTION,
    # numbers
    #'a|another-option=i'      =>  \$NEW_ANOTHER_OPTION,
);

if ( $HELP ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file(File::Spec->catfile("$0"),
			   \*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }

my $usage = "From the chrooted directory do: $0 /path/to/binary";

foreach my $bin ( @ARGV )
{
    if ( -x $bin )
    {
        umask(0222);                            # make binaries executable and not writable
        my $binchrootedpath = dirname($bin);
        $binchrootedpath =~ s,^/,,;             # removes first /
        _mkdir($binchrootedpath);               # recursively makes needed dirs
        if ( copy($bin,"$binchrootedpath/".basename($bin)) )
        {
            chmod (0555,"$binchrootedpath/".basename($bin));
            _success("$binchrootedpath/".basename($bin));
        } else {
            die ("Could not copy $bin to $binchrootedpath/".basename($bin));
        }

        # get dependencies
        my $linked_deps = qx/ldd $bin/;

        foreach my $lib ( split(/\n/,$linked_deps) )
        {
            my $libchrootedpath = "";
            $lib =~ s/\s*\(0x[0-9a-fA-F]+\)\s*$//;              # cleaned: (0x00000da)
            my ($libname,$libpath) = split(/\s*=>\s*/,$lib);    # splitted by =>
            if ( -r $libpath ) # can we read this library name?
            {
                ($libchrootedpath = $libpath) =~ s,^/,,;            # cleaned first /

                $libname =~ s/\s+//g;                               # cleaned spaces
                _mkdir(dirname($libchrootedpath));                  # recursively makes needed dirs
                if ( ! -f "$libchrootedpath/$libname" )
                {
                    if ( copy($libpath,$libchrootedpath) )
                    {
                        _success($libchrootedpath);
                    } else {
                        print STDERR "*** Copying $libpath to $libchrootedpath failed! ***\n";
                        print STDERR "$!\n";
                    }
                } else {
                    print STDERR "$libchrootedpath already exists\n";
                }
            }
        }
    } else {
        print STDERR $usage,"\n","Non-executable\n";
    }
}
# @desc implements `mkdir -p`
sub _mkdir
{
    my $old_umask = umask(0022);            # make dirs executable, readable and writable
    my $path = shift;
    my $root = ( $path =~ m,^([/|\\|:]), ) ? $1 : ""; # relative or full path?
    my @dirs = splitdir($path);
    my $last = "";
    my $flag=1;
    foreach (@dirs)
    {
        next if ( $_ =~ m/^\s*$/ );
        $last = ( $flag > 1 ) ? catdir($last,$_) : "$root"."$_" ;
        mkdir ($last) if ( ! -d $last);
        $flag++;
    }

    umask($old_umask);                      # reset umask
    return $flag;                           # number of directories created
}

sub _success
{
    my $str = shift;
    print STDOUT "$str copied successfully\n" if ($DEBUG);
}

__END__

=head1 NAME

chroot_this - chroot_this script by Luis Mondesi <lemsx1@gmail.com>

=head1 SYNOPSIS

B<chroot_this>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                /path/to/program1 [/path/to/program2 | ... ]

=head1 DESCRIPTION 

    This script allows you to setup a chroot environment for a list of binaries

=head1 OPTIONS

=over 8

=item -v,--version

prints version and exits

=item -D,--debug

enables debug mode

=item -h,--help

prints this help and exits

=cut

