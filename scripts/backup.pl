#!/usr/bin/perl -w
# $Revision: 1.16 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jul-06
#
# DESCRIPTION: backups a UNIX system using Perl's Archive::Tar
#              it will create 3 files:
#
#               backup-system-%date-tar.bz2
#               backup-users-%date-tar.bz2
#               backup-other-%date-tar.bz2
#               
#               or 
#
#               backup-daily-tar.bz2
#               backup-daily-tar.bz2
#               backup-daily-tar.bz2
#
# USAGE: backup.pl [daily]
#
# SAMPLE CONFIGURATION:
# ##Example $HOME/.backuprc
# # --- CUT HERE --- #
# # uncommend below what you want to customize
# # BAK must be specify for the script to work properly.
# # unless you want to put the files in /home/backup
# #TAR=/usr/local/bin/tar
# #COMPRESS_LEVEL=9
# ## bzip2 or gzip? or don't define if no compression is needed
# #COMPRESS_DO=/usr/bin/gzip
# ## prefix to name of the file
# #NAME=imac-home 
#
# ## Users must define this
# BAK=/dir/to/store/backups
# #EXCLUDES=.*this.*|.*that\$
# 
# #DIRS=other_dirs_to_backup_separated_by_spaces_or_commas
# #SYSTEM=system_directories_separated_by_spaces_or_commas
# #LOW_UID=lowest_uid_number_to_backup
# #EXC_ULIST=exclude_users_from_list_separated_by_|
#
# TIPS:
# * If you have "tar" or any other archive utility in your system,
#   using that makes this process faster than using Archive::Tar...
#   you have been warned!
# * Setting the script in debugging mode doesn't create any tar.gz
#   files.
# * To override a default value, just specify what you want
#   in your .backuprc file. For instance: 
#     SYSTEM="". 
#   Would cause the SYSTEM list of directories to be disregarded. 
#   And:
#     SYSTEM=/dir/1 /dir/2 /dir/3
#   Would backup only those directories
#
# * Do not use quotes in your .backuprc except for the regexp strings
#
# * MacOS X users should first make sure they have Archive::Tar 
#   installed
#   issue the command:
#     > sudo perl -e shell -MCPAN
# 
#   and when in CPAN prompt, type:
#     > install Archive::Tar
# 
#   Then follow the prompts.
# 
# * On any UNIX system you can always opt to defined your own version
#   of tar like:
#     TAR = /usr/bin/tar
#   and whether you want to use gzip or bzip2
#     COMPRESS_DO = /usr/bin/gzip
#   and your compression level low "0" & "9" highest
#     COMPRESS_LEVEL=9
#
# * The script defaults should be enough for a Debian system :-D
#

use strict;
$|++;

use Archive::Tar;
use File::Find;     # find();
use File::Basename; # basename();

my $DEBUG = 0;      # set to 1 to print debugging messages

my %MY_CONFIG = ();
my $CONFIG_FILE= $ENV{"HOME"}."/.backuprc";

$MY_CONFIG{"NAME"} = "backup";      # default name

$MY_CONFIG{"BAK"}="/home/backup";     # default backup directory
                                    # you might want to change this
                                    # in your .backuprc file like:
                                    # BAK="/other/dir"
# tar EXCL list regexp. specify EXCLUDES in your .backuprc to modify 
$MY_CONFIG{"EXCLUDES"}=".*\.pid\$|.*\.soc\$|.*\.log\$";

$MY_CONFIG{"COMPRESS_LEVEL"} = "9"; # default compression level

$MY_CONFIG{"LOW_UID"} = "1000";     # debian standard lowest uid.
                                    # change in .backuprc
$MY_CONFIG{"EXC_ULIST"} = "man|nobody";  # separated by | . Change in
                                    # .backuprc

# backup "root" home dir, cvsroot and other important stuff

$MY_CONFIG{"SYSTEM"}="/etc /var/mail /var/spool /var/lib/iptables /root";

#-------------------------------------------------------------#
#           No need to modify anything below here             #
#-------------------------------------------------------------#

my $TMP_LOCK = ".backup-lock";

# init defaults from $CONFIG_FILE
my %TMP_CONFIG = init_config($CONFIG_FILE); # override defaults with...

my %CONFIG = ();    # where the two will be merged
my @tmp_files = (); # temporary list of files
my @filelist = ();  # temp list
my @tmp_dirs = ();  # temp dirs

my $COMMAND = "";   # init scalar for command
my $TMP_COMMAND ="";# individual command line options
my $SYSTEM_COMMAND=""# what's send to the system from past 2 commands

my $USE_TAR = 0;    # use a binary of tar instead of Perl module?

# merge two hashes and warn about dups... use the last defined key=>val
my ($k, $v) = "";

foreach my $hashref ( \%MY_CONFIG, \%TMP_CONFIG ) {
    while (($k, $v) = each %$hashref) {
        if ( $DEBUG != 0 && exists $CONFIG{$k}) {
            print STDERR "Warning: $k seen twice.  Using the second definition.\n";
            # next;
        }
        $CONFIG{"$k"} = $v;
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
if ( -d $CONFIG{"BAK"} ) {
    chdir($CONFIG{"BAK"});
} else {
    die "could not change working dir to ".$CONFIG{"BAK"}." ".$!;
}

if ( ! -f $TMP_LOCK ) {
   
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime; # get date

    $year += 1900;

    my $MIDDLE_STR = ( $ARGV[0] eq "daily" ) ? "daily" : $year."-$mon-$mday";

    # write lock file:
    open(FILE,"> $TMP_LOCK") || die "could not open $TMP_LOCK. $! \n";
    print FILE $year."-".$mon."-".$mday." ".$hour.":".$min.":".$sec;
    close(FILE); 
 
    # NOTE some *NIX systems don't like the "-x" (executable) check 
    # if you are using one of those, then change this to "-e" (exists)
    # or something similar... you have been warned! Solaris?
    # Same for the -x in the following statement
    if ( exists $CONFIG{"TAR"} && -x $CONFIG{"TAR"} ) {
        $USE_TAR = 1;
        $COMMAND = sprintf("%s cf - xxFILESxx' ",$CONFIG{"TAR"});
    } elsif ( exists $CONFIG{"TAR"} && $DEBUG !=0 ) {
        print STDERR "Tar was given but not found! \n";
    }

    if ( exists $CONFIG{"COMPRESS_DO"} && 
        $USER_TAR &&
        -x $CONFIG{"COMPRESS_DO"} ) {
        # reuse COMMAND from above and 
        # pipe it to compress utility
        $COMMAND = sprintf(
            "%s | %s -%d -c ",
            $COMMAND,
            $CONFIG{"COMPRESS_DO"},
            $CONFIG{"COMPRESS_LEVEL"});
    } elsif ( exists $CONFIG{"COMPRESS_DO"} && $DEBUG !=0 ) {
        print STDERR "Compress utility not found! \n";
    }

    # ========== START BACKUP PROCESS ================= #
    # System backup
    if ( exists $CONFIG{"SYSTEM"} ) {
        # backup system
        # Archive::Tar->create_archive ("my.tar.gz", 9, "/this/file", "/that/file");
        @filelist = ();
        # a bit of sanity checking... 
        # check for two spaces or commas in list
        @tmp_dirs = split(/ +|,+/,$CONFIG{"SYSTEM"});

        foreach ( @tmp_dirs ) {
            if ( -d $_ ) {
                my @ary = &do_file_ary($_);
                push(@filelist,@ary);
            }
        }

        print STDOUT "Backing up system files \n";
        if ( $DEBUG == 0 ) {
            if ( $USE_TAR ) {
                # TODO maybe this should be in a subroutine?
                # compression is not needed? then use filename
                my $TMP_FILE_NAME = $CONFIG{"NAME"}."-system-$MIDDLE_STR.tar";
                # to allow other formats, let's probe one at a time
                $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/bzip2/ ) ? ".bz2" : "";
                $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/gzip/ ) ? ".gz" : "";
                
                my $TMP_FILE_LIST = join(' ',@file_list);
                # put files and tar file name in place holders
                ( $TMP_COMMAND = $COMMAND) =~ s/xxFILESxx/$TMP_FILE_LIST/;
                
                $SYSTEM_COMMAND = sprintf("%s > %s",
                    $COMMAND,
                    $TMP_FILE_NAME);
                system($SYSTEM_COMMAND);
                if ( $? !=0 ) {
                    print STDERR "Command '$SYSTEM_COMMAND' failed terribly!";
                }
            } else {
                Archive::Tar->create_archive (
                    $CONFIG{"NAME"}."-system-$MIDDLE_STR.tar.gz", 
                    $CONFIG{"COMPRESS_LEVEL"}, 
                    @filelist
                );
            }
        } # end if debug
    } # end if $CONFIG{"SYSTEM"} 

    # backup users
    my %user = ();  # user/userdir pair in a hash

    my $users_excluded_pattern = $CONFIG{"EXC_ULIST"};

    while (my @r = getpwent()) {
        # $name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire
        #print "$r[0]:$r[1]:$r[2]:$r[3]:$r[6]:$r[7]:$r[8]\n";
        if ( 
            
            $r[0] !~ m/$users_excluded_pattern/i && 
            $CONFIG{"LOW_UID"} <= $r[2] 
        ) {
            $user{$r[0]}=$r[7];
            #print $r[0]."\n";
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
   
    # Users backup
    print STDOUT "Backing up users files... \n";
    if ( $DEBUG == 0 ) {
        if ( $USE_TAR ) {
                # TODO maybe this should be in a subroutine?
                # compression is not needed? then use filename
                my $TMP_FILE_NAME = $CONFIG{"NAME"}."-user-$MIDDLE_STR.tar";
                # TODO put these in COMPRESS_DO general above
                # and declare a $EXT scalar holding the string to use
                # for all file_names
                # to allow other formats, let's probe one at a time
                $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/bzip2/ ) ? ".bz2" : "";
                $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/gzip/ ) ? ".gz" : "";
                
                my $TMP_FILE_LIST = join(' ',@file_list);
                # put files and tar file name in place holders
                ( $TMP_COMMAND = $COMMAND) =~ s/xxFILESxx/$TMP_FILE_LIST/;
                
                $SYSTEM_COMMAND = sprintf("%s > %s",
                    $TMP_COMMAND,
                    $TMP_FILE_NAME);
                system($SYSTEM_COMMAND);
                if ( $? !=0 ) {
                    print STDERR "Command '$SYSTEM_COMMAND' failed terribly!";
                }
        } else {
            Archive::Tar->create_archive (
                $CONFIG{"NAME"}."-users-$MIDDLE_STR.tar.gz", 
                $CONFIG{"COMPRESS_LEVEL"}, 
                @filelist
            );
        }
    } # end if debug

    # Other directories ( non-system specific )
    if ( exists $CONFIG{"DIRS"} ) {
        # backup others
        @filelist = ();
        # a bit of sanity checking... 
        # check for two spaces or commas in list
        @tmp_dirs = split(/ +|,+/,$CONFIG{"DIRS"});

        foreach ( @tmp_dirs ) {
            if ( -d $_ ) {
                my @ary = &do_file_ary($_);
                push(@filelist,@ary);
            }
        }

        printf STDOUT "Backing up other files %s \n",$CONFIG{"DIRS"};

        if ( $DEBUG == 0 ) {
            if ( $USE_TAR ) {
                # TODO maybe this should be in a subroutine?
                # compression is not needed? then use filename
                my $TMP_FILE_NAME = $CONFIG{"NAME"}."-other-$MIDDLE_STR.tar";
                # TODO put these in COMPRESS_DO general above
                # and declare a $EXT scalar holding the string to use
                # for all file_names
                # to allow other formats, let's probe one at a time
                $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/bzip2/ ) ? ".bz2" : "";
                $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/gzip/ ) ? ".gz" : "";

                my $TMP_FILE_LIST = join(' ',@file_list);
                # put files and tar file name in place holders
                ( $TMP_COMMAND = $COMMAND) =~ s/xxFILESxx/$TMP_FILE_LIST/;

                $SYSTEM_COMMAND = sprintf("%s > %s",
                    $TMP_COMMAND,
                    $TMP_FILE_NAME);
                system($SYSTEM_COMMAND);
                if ( $? !=0 ) {
                    print STDERR "Command '$SYSTEM_COMMAND' failed terribly!";
                }
            } else {
                Archive::Tar->create_archive (
                    $CONFIG{"NAME"}."-other-$MIDDLE_STR.tar.gz", 
                    $CONFIG{"COMPRESS_LEVEL"}, 
                    @filelist
                );
            }
        } # end if debug
    } # end if $CONFIG{"DIRS"}

    # ++++++++++ END BACKUP PROCESS ++++++++++ #

    # debian specific
    if ( -f "/etc/debian_version" ) {
        # this is a debian system
        # create a selections file
        system("dpkg --get-selections \\* > selections.txt");
        if ( $? == 0 ) {
            print STDOUT "Debian selections file created as: selections.txt.\n Use:\n dpkg --set-selections < selections.txt && dselect update \n to restore from this list.";
        }
    }

    # gracely exit...
    unlink "$TMP_LOCK" or die "could not remove ".$TMP_LOCK.". $!\n";

} else {
    die "Lock file ".$CONFIG{"BAK"}."/$TMP_LOCK exists... exiting.\n";
}

# ------------------------------------------------------#
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
    # hash{"VAR"}='argument'
    
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
    if ( 
        -f $_ && 
        $base_name !~ m/$CONFIG{"EXCLUDES"}/ 
    ) {
        push @tmp_files,clean("$_") ;
    }
}

sub clean {
    # ';&|><*?`$(){}[]!# ' /*List of chars to be escaped*/
    # will change, for example, a!!a to a\!\!a
    $_[0] =~ s/([;<>\*\|`&\$!#\(\)\[\]\{\}:'"\ ])/\\$1/g;
    return @_;
}
