#!/usr/bin/perl -w
# $Revision: 1.4 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-May-24
#
# DESCRIPTION: backups a UNIX system using Perl's Archive::Tar
#              it will create 3 files:
#
#               system-%date-tar.bz2
#               users-%date-tar.bz2
#               other-%date-tar.bz2
#               
#               or 
#
#               system-daily-tar.bz2
#               users-daily-tar.bz2
#               other-daily-tar.bz2
#
# USAGE: backup.pl [daily|weekly|monthly]
#
# Example $HOME/.backuprc
#
# BAK="/dir/to/store/backups"
# EXCLUDES="--exclude='*this' --exclude='*that' "
# 
# DIRS="dirs_to_backup_separated_by_spaces "
# SYSTEM="system_directories_separated_by_spaces"
# LOW_UID="lowest_uid_number_to_backup"
# EXC_ULIST="exclude_users_from_list_separated_by_|"
#
use strict;
$|++;

use Archive::Tar;

my %MY_CONFIG = ();
my $CONFIG_FILE= $ENV{HOME}."/.backuprc";

$MY_CONFIG{BAK}="/home/backup";        # default backup directory
                                    # you might want to change this
                                    # in your .backuprc file like:
                                    # BAK="/other/dir"
# tar EXCL list. specify EXCLUDES in your .backuprc to modify 
$MY_CONFIG{EXCLUDES}="--exclude='*.pid' --exclude='*.soc' --exclude='*.sock' --exclude='*.log' --exclude='*.log*.gz' ";


$MY_CONFIG{LOW_UID} = "1000";          # debian standard lowest uid.
                                    # change in .backuprc
$MY_CONFIG{EXC_ULIST} = "man|nobody";  # separated by | . Change in
                                    # .backuprc

# backup "root" home dir, cvsroot and other important stuff

$MY_CONFIG{SYSTEM}="/etc /home/cvsroot /var/lib/jabber /var/lib/mysql /var/mail /var/spool /var/lib/ldap /var/lib/iptables /root";

#$MY_CONFIG{LOCK} = "/tmp/.backup-init"; # timestamp of when backup started

#-------------------------------------------------------------#
#           No need to modify anything below here             #
#-------------------------------------------------------------#

my $TMP_LOCK = ".backup-lock";

my %TMP_CONFIG = init_config($CONFIG_FILE); # override defaults with...

my %CONFIG = ();   # where the two will be merged

# merge two hashes and warn about dups... use the last defined key=>val
my ($k, $v) = "";
foreach my $hashref ( \%MY_CONFIG, \%TMP_CONFIG ) {
    while (($k, $v) = each %$hashref) {
        if (exists $CONFIG{$k}) {
            print STDERR "Warning: $k seen twice.  Using the second definition.\n";
            # next;
        }
        $CONFIG{$k} = $v;
    }
}

# DEBUG: print content of hash
#foreach ( \%CONFIG ) {
#    while (($k,$v) = each %$_) {
#        print "$k -> $v \n";
#    }
#}
#die "the end \n";

# change to backup directory
if ( -d eval($CONFIG{BAK}) ) {
    chdir(eval($CONFIG{BAK}));
} else {
    die "could not change working dir to $CONFIG{BAK}. $!";
}

if ( ! -f $TMP_LOCK ) {
   
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime; # get date

    $year += 1900;

    my $MIDDLE_STR = ( $ARGV[0] eq "daily" ) ? "daily" : $year."-$mon-$mday";

    # write lock file:
    open(FILE,"> $TMP_LOCK") || die "could not open $TMP_LOCK. $! \n";
    print FILE $year."-".$mon."-".$mday." ".$hour.":".$min.":".$sec;
    close(FILE); 

    # backup system
    # Archive::Tar->create_archive ("my.tar.gz", 9, "/this/file", "/that/file");
    #split(",", $CONFIG{SYSTEM})
    print STDOUT "$CONFIG{BAK}\n";
    Archive::Tar->create_archive (
            "system-$MIDDLE_STR.tar.gz", 
            9, 
            "/etc"
        );
    
    # backup users
    my %user = ();                  # user/userdir pair in a hash

    while (my @r = getpwent()) {
        # $name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire
        #print "$r[0]:$r[1]:$r[2]:$r[3]:$r[6]:$r[7]:$r[8]\n";
        if ( $r[0] !~ m/$CONFIG{EXC_ULIST}/i && $CONFIG{LOW_UID} <= $r[2] ) {
            $user{$r[0]}=$r[7];
        }
    }

    # DEBUG: print content of %user hash
    #print STDOUT join(" ",%user)."\n";

    # backup others

} else {
    die "Lock file $TMP_LOCK exists... exiting.\n";
}

# gracely exit...
unlink "$TMP_LOCK" or die "could not remove ".$TMP_LOCK.". $!\n";

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
    
    my %config_tmp = ();

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
