#!/usr/bin/perl -w
# $Revision: 1.20 $
# Luis Mondesi || lemsx1 at gmail !! com 
# LICENSE: GPL (http://gnu.org/licenses/gpl.txt)
# 
# PLEASE NOTE THAT THIS SCRIPT CAN BE USED 'AS-IS' AND IF IT BREAKS
# YOUR SYSTEM YOU GET TO KEEP BOTH PIECES.
#
# A quick nautilus script to make CDROM/DVDROM images (ISOs).
#
# Simply select the directory you want and choose this script
# from the nautilus script menu.
#
# It can also be used from the command line passing the following 
# arguments:
# mkisofs.pl DIR            # makes ISO with default 680MB limit
# mkisofs.pl --dvd DIR      # makes a DVD image
# mkisofs.pl --size=780 DIR # makes ISO with 780MB limit
#
# mkisofs.pl --debug DIR    # dry-run where no ISO will be actually 
#                           # done, but everything will proceed as 
#                           # normal
# Technical stuff:
# The script uses "find" to get all files from the directory passed
# from the command line. It then creates a dummy CD structure using
# symlinks and finally calls "mkisofs" for e/a CD image to be created.
# Essentially this means that it will work correctly if:
#   - you use it under UNIX (or a system that understands symbolic links)
#   - your mkisofs binary supports the -f switch (follow symlink)
#
# Due to some limitations in ISO9660 (and Joliet extensions), this 
# script attempts to do the "right" thing for files which might violate
# this. Note that if you will use this CD under *NIX/Linux or Windows,
# then you will be ok. However, you should ALWAYS test your CD images
# throughly. You have been warned!
# 
# The volume id of the resulting CD/DVD image will be the same as the
# original DIR passed as an argument
#
use strict;
$|++;

use Getopt::Long;
Getopt::Long::Configure('bundling');

use POSIX qw(ceil getcwd);
use File::Spec::Functions qw(splitpath curdir updir catfile catdir splitpath);
use File::stat qw( stat );
use File::Temp qw( tmpnam );

my $USAGE = "mkisofs.pl [--debug] [--version|--help] [--dvd] [--size=N] DIR
--debug     Prints lots of compreshensive messages about what this
            script is doing. Do not create ISOs but do everything else.
--version   Prints version and exits
--help      Print version number plus this help and exists
--dvd       Assumes DIR is a DVD tree (made with dvdauthor 
            for instance) and creates a UDF DVD image
--size=N    Limits size of CD images to N megabytes
--batch     Runs in non-interactive mode. Auto-selected for Nautilus
";

my $nice =  ( -x "/usr/bin/nice" ) ? "/usr/bin/nice":"";

# You could get only the selected files from nautilus, but
# it's better to let the user put all those files in 
# a single directory and then run this script on that directory
# $ENV{"NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"}

###################################################################
#                 NO NEED TO MODIFY AFTER THIS LINE               #
###################################################################

die ($USAGE) if ( !@ARGV );

# hard coded values:

my $VOLIDMAXLENGTH=32;
my $FILENAMEMAXLENGTH=59; # gives room to 4 char extensions

# our log file
my ($logfh,$logfile) = tmpnam();
open ($logfh,">$logfile");

# users can/must change this from the command line:
my $ISOLOWEST=2*1024*1024; # lowest size for which we will create ISOs
my $ISOLIMIT=680;   # in megabytes (1*1024 kBytes) NOTE: Do not set to 
                    # your media limit; allow some extra space 
                    # for ISO9660 overhead (Joliet+RR extentions)
                    # i.e. 680 for 700MB disks should be fine

# flags
my $PVERSION = 0;
my $DVD = 0;
my $DEBUG = 0; 
my $INTERACTIVE=1; # assume we want to run interactively
# the directory we will do an ISO for:
my $folder = "";

# get options
GetOptions(
    # flags
    'v|version'     =>  \$PVERSION,
    'h|help'        =>  \$PVERSION,
    'd|dvd'         =>  \$DVD,
    'D|debug'       =>  \$DEBUG,
    'b|batch'       =>  sub { $INTERACTIVE=0; },
    # numbers
    's|size=i'      =>  \$ISOLIMIT,
) and $folder = shift;

if ( $PVERSION > 0 )
{
    print STDOUT "Version 1.0\tLuis Mondesi < lemsx1 at gmail dot com >\n\n$USAGE\n";
    exit(0);
}

{
no warnings; # turn of warnings for now
chomp($folder); # remove end-line
die($USAGE) if ( ! -d "$folder" );
} # warnings are restored
# if we are running under Nautilus, we are automatically NON-INTERACTIVE
if (  exists $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} )
{
    $INTERACTIVE=0;
}

# 1. cleanup dir name:
$folder =~ s#/+$##; # remove trailing slash(es)
# 2. generate volume id:
my $volumeid = do_volid("$folder");
# 3. genarate iso name:
my $name = $folder.".iso";

print STDOUT ("Directory: $folder | Initial Volume Name: $volumeid | ISO File Name: $name\n") if ( $DEBUG > 0 );
print STDOUT ("Sleeping for 5 seconds...\n") if ( $DEBUG > 0 );
sleep(5) if ( $DEBUG > 0 ); # give a chance to stop the script

# 4. calculate ISOLIMIT in bytes:
if ( $ISOLIMIT > 0 ) # deal with non-zero positive numbers only
{
    $ISOLIMIT = POSIX::ceil( $ISOLIMIT * 1024 * 1024);
}
print STDOUT ("ISO Limit: $ISOLIMIT\n") if ( $DEBUG > 0 );
sleep(5) if ( $DEBUG > 0 ); # give a chance to stop the script

if ( $DVD > 0 ) 
{
    die("** Directory is not valid DVD tree. Missing $folder/VIDEO_TS") if ( !-d "$folder/VIDEO_TS");
    mkdir("$folder/AUDIO_TS") if ( ! -d "$folder/AUDIO_TS" ); 
    # fix permissions
    m_system("chmod 0555 '$folder'",0);
    m_system("$nice find '$folder' -type d -exec chmod 0555 {} \\; ",0);
    m_system("$nice find '$folder' -type f -exec chmod 0444 {} \\; ",0);
    # make iso
    m_system("$nice mkisofs -dvd-video -udf -o '$name' -V '$volumeid' '$folder'",1) if ( $DEBUG == 0 );
} else {
    # making regular ISO
    my $temp = "$folder-tmp";
    die ("** Directory $temp exists. Please remove it before continuing. ** ") 
        if ( -d "$temp" );

    my $i = 1; # dummy counter
    my $nfolder = $folder."$i";
    $name = $nfolder.".iso";
    $volumeid = do_volid("$nfolder"); # new volumeid based on this dir

    my $size = 0; # current size of CD ISO
    
    my $rootdir = getcwd();
    # make file list
    my $fullpath = catdir($rootdir,$folder);
    my @files = find_files( $fullpath );
    
    mkdir("$temp") or die $!;
    chdir("$temp") or die $!;

    mkdir("$nfolder") or die $!; # $name-tmp/$nfolder

    foreach my $f (@files)
    {
        $size += get_size("$f"); # gets size in bytes
        print STDOUT ("Current file $f \nCurrent Size $size\n") 
            if ( $DEBUG > 0 );
        
        my ($vol,$basedir,$new_f) = splitpath( $f );
        
        my $nbasedir = $basedir;
        # makes relative path
        $nbasedir =~ s#\Q$fullpath##g;
        $nbasedir = catdir($nfolder,$nbasedir);
        m_system ( "mkdir -p \"$nbasedir\"",1 ) if ( ! -d "$nbasedir" ); # cheat!

        # clean up new filename:
        $new_f =~ s#\s+#_#g; # replace spaces with _
        $new_f =~ s#_+#_#g; # remove excessive _
        $new_f =~ s#[\(\)\[\]\#,]+##g; # other chars we don't care
        #$new_f =~ s#\W+##gi; # remove non-word char [^0-9a-zA-Z-]
        if ( length( $new_f ) > $FILENAMEMAXLENGTH )
        {
            my $ext = $new_f;
            $ext =~ s#(\.\w{1,4})$#$1#g;
            # truncate filename:
            $new_f = substr($new_f,0,$FILENAMEMAXLENGTH);
            $new_f =~ s#\.\w{1,3}$##; # be safe
            $new_f .= "$ext"; # appends extension
            do_log("Truncating file $f\n ==> $new_f\n");
            sleep(5) if ( $DEBUG > 0 );
        }
        $new_f = catfile($nbasedir,$new_f);
        symlink("$f","$new_f") or die ("** Symlink failed:\n  '$f -> $new_f'\n $! \n");
        do_log("$new_f -> $f");
        if ( $size >= $ISOLIMIT )
        {
            my $mb = POSIX::ceil(($size / 1024)/1024);
            print STDOUT ("Making CD ISO of size ".$mb."MB\n");
            sleep(5) if ( $DEBUG > 0 );
            m_system("$nice mkisofs -f -J -r -v -o '../$name' -V '$volumeid' '$nfolder' ",1) if ( $DEBUG == 0 );
            $size = 0; # reset size
            $i++;
            $nfolder = $folder."$i";
            $name = $nfolder.".iso";
            $volumeid = do_volid("$nfolder");
            print STDOUT "Making new folder $nfolder for $name with volume id $volumeid\n";
            mkdir ($nfolder);
            do_log("#==mark== $nfolder");
            #goto END; # FIXME
        }
    }

    my $MB = POSIX::ceil(($size / 1024)/1024);

    if ( $size >= $ISOLOWEST )
    {
        print STDOUT ("Making CD ISO of size ".$MB."MB\n");
        m_system("$nice mkisofs -f -J -r -v -o '../$name' -V '$volumeid' '$nfolder' ",1) if ( $DEBUG == 0 );
    } elsif ( $size > 0 ) {
        if ( $INTERACTIVE == 0 || prompt ("Do you want to make a CD image $name of size $MB MB (See $temp/$nfolder)? [y/N] ") eq "y" )
        {
            print STDOUT ("Making CD ISO of size ".$MB."MB\n");
            m_system("$nice mkisofs -f -J -r -v -o '../$name' -V '$volumeid' '$nfolder' ",1) if ( $DEBUG == 0 );
        }
    }
    # cleanup
    chdir($rootdir);
    print "Current directory ".getcwd()."\n";
    if ( $INTERACTIVE == 0 || prompt ("Do you want to delete temporary dir '$temp'? [y/N] ") eq "y" )
    {
        print STDOUT ("...Deleting '$temp' and its contents...\n");
        m_system("rm -fr '$temp'",1);
    } else {
        print STDOUT "++ Remember to delete '$temp' when done ++\n";
    }
}
close ($logfh);
if ( $INTERACTIVE == 0 || prompt ("Remove temporary log file $logfile? [y/N] ") eq "y" )
{
    unlink ($logfile);
    print STDOUT ("++ Removed log file $logfile ++\n");
}

sub m_system
{
    my $cmd = shift;
    my $die = shift;
    print STDOUT ("$cmd\n") if ( $DEBUG > 0 );
    if ( system($cmd) )
    {
        print STDERR $!."\n";
        if ( $die > 0 ) 
        {
            die("** Bailing out\n");
        }
    }
}

sub find_files 
{
    my $dir = shift;
    if ( ! -d "$dir" ) { return; }
    my @ret = ();
    my $find = "find $dir -follow ".
    #"\\( ".
          "  \\( -type f -o -type l \\) ". # -a
          #"  \\( -name \\*mp3 -o -name \\*MP3 \\) -a ".
          #"  \\( ".
          #"    \! \\( $prune \\) ".
          #"  \\) ".
#	  "\\) ".
	  " -print ";
    my $files = qx($find);
    @ret = split(/\n/,$files); 
    return @ret;
}

sub get_size
{
    my $file = shift;
    my $stat = stat("$file");
    # to conver to MB do something like:
    #$mb = POSIX::ceil(($stat->size / 1024)/1024); 
    return $stat->size;
}

sub do_log
{
    my $l = shift;
    print STDERR "$l\n" if ( $DEBUG > 0 );
    print $logfh "$l\n";
}

sub is_in_log
{
    my @lines = <$logfh>;
    my $matched = 0;
    if ( $matched = grep(@lines,shift) ) 
    {
        return 1;
    } 
    return 0;
}

sub do_volid
{
    my $volid = shift;
    # Volume id needs no spaces or other characters
    $volid =~ s,[\s-]+,_,g;
    # length should be less than $VOLIDMAXLENGTH
    #my $str_length = length ($volumeid);
    $volid = substr($volid,0,$VOLIDMAXLENGTH);
    return $volid;
}

sub prompt
{
    #@param 0 string := question to prompt
    #returns answer
    print STDOUT "@_";
    my $rep= <STDIN>;
    chomp($rep);
    return $rep;
}

#eof
