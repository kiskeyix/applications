#!/usr/bin/perl -w
# $Revision: 1.11 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jun-08
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
# # NOTE that the defaults for these variables are sufficient
# # for a Debian system.
#
# BAK=/dir/to/store/backups
# EXCLUDES=".*this.*|.*that\$"
# 
# DIRS=other_dirs_to_backup_separated_by_spaces_or_commas
# SYSTEM=system_directories_separated_by_spaces_or_commas
# LOW_UID=lowest_uid_number_to_backup
# EXC_ULIST="exclude_users_from_list_separated_by_|"
#
# TIPS:
# To override a default value, just specify what you want
# in your .backuprc file. For instance: 
# SYSTEM="". 
# Would cause the SYSTEM list of directories to be disregarded. 
# And:
# SYSTEM=/dir/1 /dir/2 /dir/3
# Would backup only those directories
#
# Do not use quotes in your .backuprc except for the regexp strings
#

use strict;
$|++;

use Archive::Tar;
use File::Find;     # find();
use File::Basename; # basename();

my $DEBUG = 0;      # set to 1 to print debugging messages

my %MY_CONFIG = ();
my $CONFIG_FILE= $ENV{HOME}."/.backuprc";

$MY_CONFIG{BAK}="/home/backup";     # default backup directory
                                    # you might want to change this
                                    # in your .backuprc file like:
                                    # BAK="/other/dir"
# tar EXCL list regexp. specify EXCLUDES in your .backuprc to modify 
$MY_CONFIG{EXCLUDES}=".*\.pid\$|.*\.soc\$|.*\.log\$";


$MY_CONFIG{LOW_UID} = "1000";          # debian standard lowest uid.
                                    # change in .backuprc
$MY_CONFIG{EXC_ULIST} = "man|nobody";  # separated by | . Change in
                                    # .backuprc

# backup "root" home dir, cvsroot and other important stuff

$MY_CONFIG{SYSTEM}="/etc /var/mail /var/spool /var/lib/iptables /root";

#-------------------------------------------------------------#
#           No need to modify anything below here             #
#-------------------------------------------------------------#

my $TMP_LOCK = ".backup-lock";

my %TMP_CONFIG = init_config($CONFIG_FILE); # override defaults with...

my %CONFIG = ();   # where the two will be merged
my @tmp_files = (); # temporary list of files

# merge two hashes and warn about dups... use the last defined key=>val
my ($k, $v) = "";
foreach my $hashref ( \%MY_CONFIG, \%TMP_CONFIG ) {
    while (($k, $v) = each %$hashref) {
        if ( $DEBUG != 0 && exists $CONFIG{$k}) {
            print STDERR "Warning: $k seen twice.  Using the second definition.\n";
            # next;
        }
        $CONFIG{$k} = $v;
    }
}

# DEBUG: print content of hash
if ( $DEBUG != 0 ) {
    foreach ( \%CONFIG ) {
        while (($k,$v) = each %$_) {
            print "$k -> $v \n";
        }
    }
}

# change to backup directory
if ( -d $CONFIG{BAK} ) {
    chdir($CONFIG{BAK});
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
    
    if ( $CONFIG{SYSTEM} gt "" ) {
        # backup system
        # Archive::Tar->create_archive ("my.tar.gz", 9, "/this/file", "/that/file");
        my @filelist = ();
        # a bit of sanity checking... 
        # check for two spaces or commas in list
        my @tmp_dirs = split(/ +|,+/,$CONFIG{SYSTEM});

        foreach ( @tmp_dirs ) {
            if ( -d $_ ) {
                my @ary = &do_file_ary($_);
                push(@filelist,@ary);
            }
        }

        print STDOUT "Backing up system files \n";
        if ( $DEBUG == 0 ) {
            Archive::Tar->create_archive (
                "system-$MIDDLE_STR.tar.gz", 
                9, 
                @filelist
            );
        } # end if debug
    } # end if $CONFIG{SYSTEM} 

    # backup users
    my %user = ();                  # user/userdir pair in a hash

    my $users_excluded_pattern = eval($CONFIG{EXC_ULIST});
    while (my @r = getpwent()) {
        # $name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire
        #print "$r[0]:$r[1]:$r[2]:$r[3]:$r[6]:$r[7]:$r[8]\n";
        if ( $r[0] !~ m/$users_excluded_pattern/i && $CONFIG{LOW_UID} <= $r[2] ) {
            $user{$r[0]}=$r[7];
        }
    }

    # DEBUG: print content of %user hash
    if ( $DEBUG != 0 ) { 
        print STDOUT join(" ",%user)."\n"; 
    }

    # foreach user, put the list of their files in this array
    my ($k, $v) = "";
    @filelist = ();
    while (($k, $v) = each %user) {
        if ( -d $v ) {
            my @ary = &do_file_ary($v);
            push(@filelist,@ary);
        }
    }
    #print STDOUT join(" ",@filelist)."\n";
    
    print STDOUT "Backing up users files \n";
    if ( $DEBUG == 0 ) {
        Archive::Tar->create_archive (
            "users-$MIDDLE_STR.tar.gz", 
            9, 
            @filelist
        );
    } # end if debug

    if ( $CONFIG{DIRS} gt "" ) {
        # backup others
        @filelist = ();
        # a bit of sanity checking... 
        # check for two spaces or commas in list
        @tmp_dirs = split(/ +|,+/,$CONFIG{DIRS});

        foreach ( @tmp_dirs ) {
            if ( -d $_ ) {
                my @ary = &do_file_ary($_);
                push(@filelist,@ary);
            }
        }

        print STDOUT "Backing up other files $CONFIG{DIRS} \n";

        if ( $DEBUG == 0 ) {
            Archive::Tar->create_archive (
                "other-$MIDDLE_STR.tar.gz", 
                9, 
                @filelist
            );
        } # end if debug
    } # end if $CONFIG{DIRS}

    # debian specific
    if ( -f "/etc/debian_version" ) {
        # this is a debian system
        # create a selections file
        system("dpkg --get-selections \\* > selections.txt");
        if ( $? == 0 ) {
            print STDOUT "Debian selections file created as: selections.txt.\n Use:\n dpkg --set-selections < selections.txt && dselect update \n to restore from this list.";
        }
    }
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
    # /a/file.txt
    # /a/b/file-b.txt
    # /a/b/c/file-c.txt
    # /a/b2/c2/file-c2.txt
    # 
    @tmp_files = ();

    my $ROOT = shift;
    
    my %opt = (wanted => \&process_file, no_chdir=>1);
    
    find(\%opt,$ROOT);
    
    return @tmp_files;
}

sub process_file {
    my $base_name = basename($_);
    my $excludes = eval($CONFIG{EXCLUDES});
    #print STDOUT $excludes."\n";
    if ( 
        -f $_ && 
        $base_name !~ m/$excludes/ 
    ) {
        push @tmp_files,$_;
    }
}
