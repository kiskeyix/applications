#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-May-24
#
# DESCRIPTION: backups a UNIX system using Perl's Archive::Tar
# USAGE: backup.pl [daily|weekly|monthly]
#
use strict;
$|++;

use Archive::Tar;

my $TAR="/usr/bin/tar";             # if needed specify your TAR 
                                    # in .backuprc
                                    # i.e:
                                    # TAR=/usr/local/bin/tar
                                     
my $CONFIG_FILE= $ENV{HOME}."/.backuprc";
my $BAK="/home/backup";             # default backup directory
                                    # you might want to change this
                                    # in your .backuprc file like:
                                    # BAK="/other/dir"
# tar EXCL list. specify EXCLUDES in your .backuprc to append to this list
my $EXCLUDES="--exclude='*.pid' --exclude='*.soc' --exclude='*.sock' --exclude='*.log' --exclude='*.log*.gz' ";


my $lowest_uid = "1000";            # debian standard lowest uid
my $exception_list = "man|nobody";  # separated by |

# backup "root" home dir, cvsroot and other important stuff

my $SYSTEM="/etc /home/cvsroot /var/lib/jabber /var/lib/mysql /var/mail /var/spool /var/lib/ldap /var/lib/iptables /root";

my %user = (); # user/userdir pair in a hash

while (my @r = getpwent()) {
          # $name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire
          #print "$r[0]:$r[1]:$r[2]:$r[3]:$r[6]:$r[7]:$r[8]\n";
          if ( $r[0] !~ m/$exception_list/i && $lowest_uid <= $r[2] ) {
            $user{$r[0]}=$r[7];
          }
}

print join(" ",%user);

# functions 

sub init_config {
    # Takes one argument:
    # CONFIG_FILE = file from which we will read extra variables
    #
    # returns a hash build from file variables:
    # 
    # VAR = 'argument'
    # 
    # to
    # 
    # hash{VAR}='argument'
    
    my %config_tmp = "";
    my $CONFIG_FILE = shift;

    if (open(CONFIG, "<$CONFIG_FILE")){
        while (<CONFIG>) {
            next if /^\s*#/;
            chomp;
            $config_tmp{$1} = $2 if m/^\s*([^=]+)=(.+)/;
        }
        close(CONFIG);

    } else {
        print STDERR "Could not open $CONFIG_FILE";
        return "-1";
    }
    
    return %config_tmp;
}
