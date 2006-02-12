#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Mar-15
#
# DESCRIPTION: A simple script to automatically find shares on a network
#               subnet. It will attempt to detect NFS and SMB (samba)
#               and create the necessary /etc/auto.shares file
# USAGE:    automount.pl --find-nfs [--find-smb] [--preferences=/etc/auto.shares]
# CHANGELOG:
#
use strict;
$|++;

use Getopt::Long;
Getopt::Long::Configure('bundling');

my $preferences="/etc/auto.shares";
my $showmount = "showmount -e \%s";  # where %s will be the host
my $sambaclient = "smbclient -U \%s -L //\%s "; # where %s is the username 
                                    # and the second %s is the host

# ----------------------------------------- #
#   Please Do Not Modify Below This Line    #
# ----------------------------------------- #

my $revision = "Automount.pl v0.1 Luis Mondesi <lemsx1\@hotmail.com>\n"; 
my %exports = (); # 3-d hash {smb}{host}{shares},{nfs}{host}{shares}

my $PVERSION=0;
my $HELP=0;
my $NFS=0;
my $SMB=0;
my $IP="0.0.0.0";
my $NETMASK=""; # later we should calculate our subnet using this

# get options
GetOptions(
    # flags
    'v|version'             =>  \$PVERSION,
    'h|help'                =>  \$HELP,
    'n|find-nfs'            =>  \$NFS,
    's|find-smb'            =>  \$SMB,
    # strings
    'p|preferences=s'       =>  \$preferences
);
if ( $HELP ) { system("pod2text $0"); exit 0; }
if ( $PVERSION ) { print STDOUT ($revision,"\n"); exit 0; }

sub main()
{
    find_nfs();
    find_smb();
    #write_preferences();
}

sub find_nfs()
{
}

sub find_smb()
{
}

sub write_preferences()
{
    open(ETC,"> $preferences ") 
        or die("Could not open $preferences. $!");
    foreach my $key (keys $exports{'nfs'})
    {
        my $tmp_str = sprintf("$showmount",$exports{'nfs'}{$key});
        print ETC "$tmp_str";
    }
    close(ETC);
}

main();

# eof 

__END__

=head1 NAME

automount.pl - A simple script to automatically find shares on a network

=head1 SYNOPSIS

B<automount.pl> [-n,--find-nfs]
                [-s,--find-smb]
                [-p,--preference] (/path/to/auto.file) 
                [-h,--help]

=head1 DESCRIPTION 

A simple script to automatically find shares on a network
subnet. It will attempt to detect NFS and SMB (samba)
and create the necessary /etc/auto.shares file

=head1 OPTIONS

=over 8

=item -n,--find-nfs

Attempt to find shares via NFS (showmount -e)

=item -s,--find-smb

Attempt to find shares via SMB (samba)

=item -p,--preference (/path/to/auto.file) 

Use /path/to/auto.file as configuration file instead of default /etc/auto.shares

=item -h,--help

Prints help and exits

=head1 ENVIRONMENT

No environment variables are used.

=head1 AUTHOR

Luis Mondesi <lemsx1@hotmail.com>

=head1 SEE ALSO

autofs(8), automount(8), auto.master(5), pod2text(1), pod2man(1)

=cut

