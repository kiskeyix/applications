#!/usr/bin/perl -w
# $Revision: 1.7 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: set up a chroot environment for a binary
#
# USAGE: cd /chroot/path && chroot_this.pl /path/to/program
#
# LICENSE: GPL
#
# NOTES: 
# This script just does the right thing for the given program passed to it
# to setup a full chroot environment you will need all the common UNIX utils 
# used by the program you passed as an argument.
# Here is an example of what you would need if you want to setup ssh/sftp 
# chrooted on Fedora (with privilege separation):
#
# * /bin/{cp, ls, mkdir, mv, rm, rmdir, sh}: for i in cp ls mkdir mv rm rmdir sh; do chroot_this.pl /bin/$i; done
# * /usr/libexec/sftp-server: chroot_this.pl /usr/libexec/openssh/sftp-server
# * pam: mkdir -p etc/pam.d; cp -r /etc/pam.d/* etc/pam.d/
# * libpam: cp -r /lib/libpam* lib
# - cp /lib/libnss_files* lib
# - mkdir -p lib/security; chroot_this.pl `find /lib/security/ -depth`
# - mkdir -p etc/security; cp -r /etc/security/*.conf etc/security
# * ssh: mkdir -p etc/ssh; cp -a /etc/ssh/* etc/ssh/
# * /etc/nsswitch.conf: mkdir etc; cat > etc/nsswitch.conf <<-FIN
#     passwd:         files
#     group:          files
#     shadow:         files
#   FIN
# * /etc/{passwd,shadow,group}:
#   mkdir etc; cat > $CHROOTDIR/etc/passwd <<-FIN
#        root:x:0:0:Root:/:/bin/bash
#        nobody:x:65534:65534:nobody:/:/bin/false
#        sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin
#    FIN
#    cat > etc/shadow <<-FIN
#        root:*:11142:0:99999:7:::
#        nobody:*:11142:0:99999:7:::
#        sshd:!!:12871:0:99999:7:::
#    FIN
#    cat > etc/group <<-FIN
#        root:x:0
#        nogroup:x:65534:
#    FIN
# * /var:
#   - mkdir -p var/empty/sshd; chown root var/empty/sshd; chmod 0755 var/empty/sshd
#   - mkdir -p var/log
#   - mkdir -p var/run
#   - mkdir -p var/tmp; chmod 1777 var/tmp
# * /tmp: mkdir tmp; chmod 1777 tmp
# * /etc/init.d/ssh: mkdir -p etc/init.d; cp /etc/init.d/ssh* etc/init.d/
#   - cp /etc/init.d/functions etc/init.d/
# * Assorted kernel devices:
#   - mknod dev/null c 1 3
#   - mknod dev/zero c 1 5
#   - mknod dev/urandom c 1 9
#   - mknod dev/console c 5 1
#   
# * Assorted directories:
#   - mkdir -p etc/rc.d; cd etc/rc.d; ln -s ../init.d init.d
#
# * Assorted utilities:
#   - /sbin/initlog: chroot_this.pl /sbin/initlog; cp /etc/initlog.conf etc/
#   - /usr/bin/reset: chroot_this.pl /usr/bin/reset
#   - /sbin/nologin: chroot_this.pl /sbin/nologin
# * Assorted libraries:
#   - cp -a /lib/libssl* lib/
#   - cp -a /usr/lib/libssl* usr/lib/
#   - cp -a /usr/lib/libcrypt* usr/lib/
# * Assorted logging:
#   - syslog-ng: add unix-stream(/path/to/chroot/dev/log) to your s_all source
#   - syslog: edit /etc/sysconfig/syslog and add: -p /dev/log -a /path/to/chroot/dev/log
# * Assorted mounts:
#   ssh doesn't like to work without this:
#   - /dev/pts: mkdir dev/pts; mount -t devpts none dev/pts
#
# And finally, run: chroot /path/to/chrootdir
# And execute '/usr/sbin/sshd -dD' to test sshd in non-daemon debugging mode
# From a different shell/system, use "ssh -v -v user@server_or_ip" to test the client
# REFERENCES:
# * http://chrootssh.sourceforge.net/docs/chrootedsftp.html
# * http://www.bpfh.net/simes/computing/chroot-break.html

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

my $usage = "From the chrooted directory do: chroot_this.pl /path/to/binary";

foreach my $bin ( @ARGV )
{
    print STDERR "DEBUG: now doing: $bin \n " if ( $DEBUG );
    if ( ! -d $bin and -x $bin )
    {
        umask(0222);                            # make binaries executable and not writable
        my $binchrootedpath = dirname($bin);
        $binchrootedpath =~ s,^/,,;             # removes first /
        _mkdir($binchrootedpath);               # recursively makes needed dirs
        my $binchrootedpathnamed = "$binchrootedpath/".basename($bin);
        if ( copy($bin,$binchrootedpathnamed) )
        {
            chmod (0555,$binchrootedpathnamed);
            _success($binchrootedpathnamed);
        } else {
            warn ("*** Could not copy $bin to $binchrootedpathnamed ***");
        }

        # get dependencies
        my $linked_deps = qx/ldd $bin/;

        foreach my $lib ( split(/\n/,$linked_deps) )
        {
            my $libchrootedpath = "";
            $lib =~ s/\s*\(0x[0-9a-fA-F]+\)\s*$//;              # cleaned: (0x00000da)
            my ($libname,$libpath) = split(/\s*=>\s*/,$lib);    # splitted by =>
            next if ( ! defined($libpath) or $libpath !~ /^\s*$/ );
            if ( -r $libpath ) # can we read this library name?
            {
                ($libchrootedpath = $libpath) =~ s,^/,,;            # cleaned first /

                $libname =~ s/\s+//g;                               # cleaned spaces
                _mkdir(dirname($libchrootedpath));                  # recursively makes needed dirs
                if ( ! -f "$libchrootedpath/$libname" )
                {
                    if ( copy($libpath,$libchrootedpath) )
                    {
                        # surprisingly, in linux libraries must be exec also
                        chmod (0555,"$libchrootedpath/$libname");
                        _success($libchrootedpath);
                    } else {
                        print STDERR "*** Copying $libpath to $libchrootedpath failed! ***\n";
                        print STDERR "$!\n";
                    }
                } else {
                    print STDERR "$libchrootedpath already exists\n";
                }
            } else {
                no warnings;
                print STDERR "library '$libpath' is not valid from 'ldd $bin'\n";
                print STDERR "try copying this file by hand.\n";
            }
        }
    } else {
        print STDERR $usage,"\n","'$bin' Non-executable\n";
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

