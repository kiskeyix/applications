#!/usr/bin/perl -w
# $Revision: 1.28 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Sep-28
#
# DESCRIPTION: backups a UNIX system using Perl's Archive::Tar
#               or a user specified command archiver ( tar? )
#              
#              it will create files in the form:
#
#               backup-system-%date-tar.bz2
#               backup-user-USER1-%date-tar.bz2
#               backup-user-USER2-%date-tar.bz2
#               ...
#               backup-other-%date-tar.bz2
#               
#               or 
#
#               backup-system-daily-tar.bz2
#               backup-user-USER1-daily-tar.bz2
#               ...
#               backup-other-daily-tar.bz2
#               
#               Run from a cronjob daily by passing the "daily"
#               argument, or weekly/monthly whatever without
#               the daily argument
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
# #EXCLUDES=.*this.*|.*that$|other$|startswith.*
# 
# #DIRS=other_dirs_to_backup_separated_by_spaces_or_commas
# #SYSTEM=system_directories_separated_by_spaces_or_commas
# #LOW_UID=lowest_uid_number_to_backup
# #EXC_ULIST=exclude_users_from_list_separated_by_|
# # --- END CUT --- #
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
#     > install IO::Zlib
# 
#   Then follow the prompts.
# 
# * On any UNIX system you can always opt to defined your own version
#   of tar like (faster than Archive::Tar):
#     TAR = /usr/bin/tar
#   and whether you want to use gzip or bzip2
#     COMPRESS_DO = /usr/bin/gzip
#   and your compression level low "0" & "9" highest
#     COMPRESS_LEVEL=9
#
# * The script defaults should be enough for a Debian system :-D
#   In debian you will need to have installed:
#       libarchive-tar-perl
#       libio-zlib-perl (only for unstable)
#       libcompress-zlib-perl (only for Woody)
#
# BUGS:
# * UNIX has a limit of arguments that can be passed from a command line
#   or any app. This is usually 131,072 items. To circumbent that
#   we are:
#     1. using " --exclude='' " in tar and passing whole directories
#        to the argument via de system() call
#     2. if you use Archive::Tar this problem is not an issue
#
#     Make sure you have a version of Tar that has --exclude support.
#     This is version 1.13.25 ( tar --version )
#     If your version of UNIX ships with a version older than this, or
#     if it doesn't include this switch, then just use Archive::Tar (
#     note that this is slower, but works... )
# * PATTERNS for Perl regexs are different from those used by the shell;
#   so, if you are using regex like: 
#       [0-9]+.*
#   To match a file that starts with one or more numbers followed by 
#   anything, in a SHELL this will look like:
#       [0-9]*.*
#   As seen by this script. Which could be wrong because the dot (.)
#   in a SHELL has not the same meaning than in a PCRE. So be carefull
#   in what pattern you choose to exclude.
#
#   Note that this script will attempt to convert from Perl regex to
#   shell pattern as much as possible, but, you will have to test
#   that your regex/patterns are actually doing what you intend.
#   The best way to test this is to create a $HOME/.backuprc file 
#   and put a line like:
#       EXCLUDES=\.pid$|\.soc$|\.log$|[0-9]+.*
#   This will work correctly in both the shell and Perl's regex. Again,
#   because this script will convert that to a shell pattern in the form:
#       EXCLUDES=*.pid|*.soc|*.log|[0-9]*.*
#   To use either TAR (faster) or Archive::Tar perl module, all you have
#   to do in your $HOME/.backuprc is to set the "TAR" variable to point
#   to the tar binary you want to use, and while at it, also set the
#   COMPRESS_DO if you want to use compression:
#       TAR=/usr/bin/tar
#       COMPRESS_DO=/usr/bin/bzip2
#
#   Commenting these two will force the script to use Archive::Tar
#   COMPRESS_LEVEL will be used for either "tar" or Archive::Tar

use strict;
$|++;

# test whether we should use Archive::Tar
my $ARCHIVE_TAR=1; # assume yes
eval "use Archive::Tar";
if ($@)
{
    print STDERR "Archive::Tar Perl module not found. You must use TAR=/usr/bin/tar and COMPRESS_DO=/usr/bin/gzip in your ~/.backuprc\n";
    $ARCHIVE_TAR=0;
}

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
$MY_CONFIG{"EXCLUDES"}='\.pid$|\.soc$|\.log$';

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
my $SYSTEM_COMMAND="";  # what's send to the system from past 2 commands

my $USE_TAR = "0";      # use a binary of tar instead of Perl module?

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
    $mon += 1; ## adjust Month: 0..11 instead of natural 1 .. 12
    $year += 1900;

    my $MIDDLE_STR = ( exists $ARGV[0] && $ARGV[0] eq "daily" ) ? "daily" : $year."-$mon-$mday";

    # write lock file:
    open(FILE,"> $TMP_LOCK") || die "could not open $TMP_LOCK. $! \n";
    print FILE $year."-".$mon."-".$mday." ".$hour.":".$min.":".$sec;
    close(FILE); 

    # cleanup name
    # no spaces allowed here
    $CONFIG{"NAME"} =~ s/ +//g;
    # look for other strange characters...
    #$CONFIG{"NAME"} = clean($CONFIG{"NAME"});

    # NOTE some *NIX systems don't like the "-x" (executable) check 
    # if you are using one of those, then change this to "-e" (exists)
    # or something similar... you have been warned! Solaris?
    # Same for the -x in the following statement
    if ( exists $CONFIG{"TAR"} && -x $CONFIG{"TAR"} ) {
        $USE_TAR = 1;

        # get the excludes from the | (bar) separated list:
        # not too elegant, but better than looping!
        my $TMP_EXCLUDES = "--exclude='";
        # TODO find a way to clean the regex expression
        # from things like: \.log$
        # to things like: *.log
        ($TMP_EXCLUDES .= clean_regex($CONFIG{"EXCLUDES"})) =~ s/\|/' --exclude='/g; 
        $TMP_EXCLUDES .= "'";

        # construct our main command
        $COMMAND = sprintf("%s cf - %s  xxFILESxx 2> /dev/null",
            $CONFIG{"TAR"},
            $TMP_EXCLUDES
        );
    } elsif ( exists $CONFIG{"TAR"} && $DEBUG !=0 ) {
        print STDERR "Tar was given but not found! \n";
    }

    if ( exists $CONFIG{"COMPRESS_DO"} && 
        $USE_TAR &&
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
    if ( -x "/usr/bin/flite" ) 
    {
        # my $pid = fork(); # TODO look for a way to send this 
        # next system() call to the background and move on
        # with backup
        # emit an audible alert
        system("/usr/bin/flite -t 'Starting backup process at ".
            $hour." ".$min."'");
    }

    # System backup
    if ( exists $CONFIG{"SYSTEM"} ) {
        # backup system
        # Archive::Tar->create_archive ("my.tar.gz", 9, "/this/file", "/that/file");
        @filelist = ();
        # a bit of sanity checking... 
        # check for two spaces or commas in list
        @tmp_dirs = split(/ +|,+/,$CONFIG{"SYSTEM"});

        print STDOUT "Backing up system files \n";
        if ( $USE_TAR ) {
            # TODO maybe this should be in a subroutine?
            # compression is not needed? then use filename
            my $TMP_FILE_NAME = $CONFIG{"NAME"}."-system-$MIDDLE_STR.tar";
            # to allow other formats, let's probe one at a time
            $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/bzip2/ ) ? ".bz2" : "";
            $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/gzip/ ) ? ".gz" : "";

            my $TMP_FILE_LIST = join(' ',@tmp_dirs);
            # put files and tar file name in place holders
            ( $TMP_COMMAND = $COMMAND) =~ s/xxFILESxx/$TMP_FILE_LIST/;

            $SYSTEM_COMMAND = sprintf("%s > %s",
                $TMP_COMMAND,
                $TMP_FILE_NAME);

            print STDOUT "+ exec: $SYSTEM_COMMAND \n" if ($DEBUG > 0);

            system($SYSTEM_COMMAND);
            if ( $? !=0 ) {
                die "Command '$SYSTEM_COMMAND' failed terribly! $!\n";
            }
        } else {

            foreach ( @tmp_dirs ) {
                if ( -d $_ ) {
                    my @ary = &do_file_ary($_);
                    push(@filelist,@ary);
                }
            }
            if ( $ARCHIVE_TAR == 1 )
            {
                Archive::Tar->create_archive (
                    $CONFIG{"NAME"}."-system-$MIDDLE_STR.tar.gz", 
                    $CONFIG{"COMPRESS_LEVEL"}, 
                    @filelist
                );
            } else {
                print STDERR "Ditto. Nothing to do because Archive::Tar is not found! \$CONFIG{'SYSTEM'}\n";
            }
        }
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
        print STDOUT join("\n",%user)."\n"; 
    }


    # Users backup
    print STDOUT "Backing up users files... \n";
    # foreach user, put the list of their files in this array
    my ($k, $v) = "";

    while (($k, $v) = each %user) {

        # do archive for this user:

        if ( $USE_TAR ) {
            # TODO maybe this should be in a subroutine?
            # compression is not needed? then use filename
            my $TMP_FILE_NAME = $CONFIG{"NAME"}."-user-$k-$MIDDLE_STR.tar";
            # TODO put these in COMPRESS_DO general above
            # and declare a $EXT scalar holding the string to use
            # for all file_names
            # to allow other formats, let's probe one at a time
            $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/bzip2$/ ) ? ".bz2" : "";
            $TMP_FILE_NAME .= ( $CONFIG{"COMPRESS_DO"} =~ m/gzip$/ ) ? ".gz" : "";

            my $TMP_FILE_LIST = $v;
            # put files and tar file name in place holders
            ( $TMP_COMMAND = $COMMAND) =~ s/xxFILESxx/$TMP_FILE_LIST/;

            $SYSTEM_COMMAND = sprintf("%s > %s",
                $TMP_COMMAND,
                $TMP_FILE_NAME);

            print STDOUT "+ users exec: $SYSTEM_COMMAND \n" if ($DEBUG > 0);
            system($SYSTEM_COMMAND);
            if ( $? !=0 ) {
                die "Command '$SYSTEM_COMMAND' failed terribly! $!\n";
            }
        } else {
            if ( -d $v ) {
                my @ary = &do_file_ary($v);
                push(@filelist,@ary);
            } # end if volume
            #print STDOUT join(" ",@filelist)."\n";
            if ( $ARCHIVE_TAR == 1 )
            {
                Archive::Tar->create_archive (
                    $CONFIG{"NAME"}."-user-$k-$MIDDLE_STR.tar.gz", 
                    $CONFIG{"COMPRESS_LEVEL"}, 
                    @filelist
                );
            } else {
                print STDERR "Ditto. Nothing to do because Archive::Tar is not found! \$CONFIG{'USER'} $k\n";
            }
        } #end if/else use_tar

        # reset array
        @filelist = ();

    } #end while

    # Other directories ( non-system specific )
    if ( exists $CONFIG{"DIRS"} ) {
        # backup others
        @filelist = ();
        # a bit of sanity checking... 
        # check for two spaces or commas in list
        @tmp_dirs = split(/ +|,+/,$CONFIG{"DIRS"});

        printf STDOUT "Backing up other files %s \n",$CONFIG{"DIRS"};

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

            my $TMP_FILE_LIST = join(' ',@tmp_dirs);
            # put files and tar file name in place holders
            ( $TMP_COMMAND = $COMMAND) =~ s/xxFILESxx/$TMP_FILE_LIST/;

            $SYSTEM_COMMAND = sprintf("%s > %s",
                $TMP_COMMAND,
                $TMP_FILE_NAME);

            print STDOUT "+ others exec: $SYSTEM_COMMAND \n" if ($DEBUG > 0);

            system($SYSTEM_COMMAND);
            if ( $? !=0 ) {
                die "Command '$SYSTEM_COMMAND' failed terribly! $!\n";
            }
        } else {
            foreach ( @tmp_dirs ) {
                if ( -d $_ ) {
                    my @ary = &do_file_ary($_);
                    push(@filelist,@ary);
                }
            }
            if ( $ARCHIVE_TAR == 1 )
            {

                Archive::Tar->create_archive (
                    $CONFIG{"NAME"}."-other-$MIDDLE_STR.tar.gz", 
                    $CONFIG{"COMPRESS_LEVEL"}, 
                    @filelist
                );
            } else {
                print STDERR "Ditto. Nothing to do because Archive::Tar is not found! \$CONFIG{'OTHER'}\n";
            }
        }
    } # end if $CONFIG{"DIRS"}

    # ++++++++++ END BACKUP PROCESS ++++++++++ #

    # debian specific
    if ( -f "/etc/debian_version" ) {
        # this is a debian system
        # create a selections file
        my $sel = $CONFIG{"NAME"}."-selections.txt";
        system("dpkg --get-selections \\* > $sel");
        if ( $? == 0 ) {
            print STDOUT "Debian selections file created as:".
            " $sel.\n ".
            " Use:\n dpkg --set-selections < $sel".
            " && dselect install \n to restore from this list.\n";
        }
    }

    # gracely exit...
    unlink "$TMP_LOCK" or die "could not remove ".$TMP_LOCK.". $!\n";

} else {
    die "Lock file ".$CONFIG{"BAK"}."/$TMP_LOCK exists... exiting.\n";
}

#------------------------------------------------------#
#----------            functions            -----------#
#------------------------------------------------------#

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
        print STDERR "Could not open $CONFIG_FILE\n";
        my $response = prompt("Do you want to continue? [y/N] ");
        if ($response ne 'y') 
        {
            die "Bailing out\n";
        }
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
    #my $base_name = basename($_);
    if ( 
        $_ !~ m,$CONFIG{"EXCLUDES"},g &&
        -f $_ 
    ) {
        push @tmp_files,clean("$_") ;

        # use this sleep when testing your regex
        # just uncomment these lines and set 
        # $DEBUG to 1
        #print STDOUT "$_ \n";
        #if ($_ =~ m/Trash/g) { sleep(3) };
    }
}

sub clean {
    # ';&|><*?`$(){}[]!# ' /*List of chars to be escaped*/
    # will change, for example, a!!a to a\!\!a
    $_[0] =~ s/([;<>\*\|`&\$!#\(\)\[\]\{\}:'"\ ])/\\$1/g;
    return @_;
}

# This subroutine prompts a user for a response
# which is then returned to the original caller
# my $var = prompt("string");
sub prompt {
    # prompt user and return input     
    my $string = shift;
    my $input = "";                                                                                 
    print ($string."\n");
    chomp($input = <STDIN>);
    # chomp is the same as:
    # $input =~ s/\n//g; # remove lineend
    return $input;
} # ends prompt

sub clean_regex {
    # attemps to take a PCRE regex and returns a
    # shell pattern
    my $string = shift;
    ($string = $string) =~ s/\\//g; 
    ($string = $string) =~ s/([\.\w]+)\$/*$1/g;
    ($string = $string) =~ s/\+/*/g;
    return $string;
}
