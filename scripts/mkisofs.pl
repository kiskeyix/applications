#!/usr/bin/perl -w
# $Revision: 1.15 $
# Luis Mondesi || lemsx1 at gmail !! com 
# LICENSE: GPL (http://gnu.org/licenses/gpl.txt)
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
use strict;
$|++;

use Getopt::Long;
Getopt::Long::Configure('bundling');

use POSIX qw(ceil getcwd); # ceil()
use File::Spec::Functions qw(splitpath curdir updir catfile catdir splitpath);
use File::stat qw( stat );
use File::Temp qw( tmpnam );

my $DEBUG=0;
my $VOLIDMAXLENGTH=32;
my $FILENAMEMAXLENGTH=59; # gives room to 4 char extensions
my $ISOLIMIT=680;   # in megabytes (1*1024 kBytes) NOTE: Do not set to 
                    # your media limit; allow some extra space 
                    # for ISO9660 overhead (Joliet+RR extentions)
                    # i.e. 680 for 700MB disks should be fine

my ($logfh,$logfile) = tmpnam();
open ($logfh,">$logfile");

# You could get only the selected files from nautilus, but
# it's better to let the user put all those files in 
# a single directory and then run this script on that directory
# $ENV{"NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"}

###################################################################
#                 NO NEED TO MODIFY AFTER THIS LINE               #
###################################################################
# some flags
my ( $DVD ) = 0; 
# get options
GetOptions(
    # flags
    'v|version'     =>  \$PVERSION,
    'd|dvd'         =>  \$DVD,
    # numbers
    's|size=i'      =>  \$ISOLIMIT,
);

my $folder = shift;
chomp($folder); # remove end-line


$folder =~ s#/+$##; # remove trailing slash(es)
my $volumeid = do_volid("$folder");
# put a .iso extension
my $name = $folder.".iso";

my $nice =  ( -x "/usr/bin/nice" ) ? "/usr/bin/nice":"";

print "Argument: $ARGV[0] | Volume Name: $volumeid | FileName: $name\n" if $DEBUG == 1;
sleep(5) if $DEBUG == 1;

# calculate ISOLIMIT in bytes:
$ISOLIMIT = POSIX::ceil( $ISOLIMIT * 1024 * 1024);
print STDOUT ("ISO Limit: $ISOLIMIT\n");# if ( $DEBUG > 0 );

if ( $ARGV[1] && $ARGV[1] eq "dvd" ) 
{
    die("Directory is not valid DVD tree. Missing $folder/VIDEO_TS") if ( !-d "$folder/VIDEO_TS");
    mkdir("$folder/AUDIO_TS"); # we can afford to try this
    # fix permissions
    m_system("chmod 0555 '$folder'",0);
    m_system("$nice find '$folder' -type d -exec chmod 0555 {} \\; ",0);
    m_system("$nice find '$folder' -type f -exec chmod 0444 {} \\; ",0);
    # make iso
    m_system("$nice mkisofs -dvd-video -udf -o '../$name' -V '$volumeid' '$folder'",1);
} else {
    # making regular ISO
    my $temp = "$folder-tmp";
    die ("** Directory $temp exists. Please remove it before continuing. ** ") 
        if ( -d "$temp" );

    my $i = 1; # dummy counter
    my $nfolder = $folder."$i";
    $name = $nfolder.".iso";

    my $size = 0; # current size of CD ISO
    
    my $rootdir = getcwd();
    # make file list
    my $fullpath = catdir($rootdir,$folder);
    my @files = find_files( $fullpath );
    
    mkdir("$temp");
    chdir("$temp");

    mkdir("$nfolder"); # $name-tmp/$nfolder

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
        m_system ( "mkdir -p \"$nbasedir\"",1 ); # cheat!

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
            sleep(3) if ( $DEBUG > 0 );
        }
        $new_f = catfile($nbasedir,$new_f);
        symlink("$f","$new_f") or die "Symlink failed:\n  '$f -> $new_f'\n $! \n";
        do_log("$new_f -> $f");
        if ( $size >= $ISOLIMIT )
        {
            my $mb = POSIX::ceil(($size / 1024)/1024);
            print STDOUT ("Making CD ISO of size ".$mb."MB\n");
            m_system("$nice mkisofs -f -J -r -v -o '../$name' -V '$volumeid' '$nfolder' ",1);
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
    if ( $size > 0 )
    {
        my $res = prompt ("Do you want to make ISO of remaining size $size MB ($nfolder|$name)? [y/N]");
        if ( $res eq "y" )
        {
            my $mb = POSIX::ceil(($size / 1024)/1024);
            print STDOUT ("Making CD ISO of size ".$mb."MB\n");
            m_system("$nice mkisofs -f -J -r -v -o '../$name' -V '$volumeid' '$nfolder' ",1);
        }
    }
    # cleanup
    chdir($rootdir);
    print "Current directory ".getcwd()."\n";
    if ( prompt ("Do you want to delete temporary dir '$temp'? [y/N] ") eq "y" )
    {
        print STDOUT "Deleting '$temp' and its contents\n";
        m_system("rm -fr '$temp'",1);
    } else {
        print STDOUT "++ Remember to delete '$temp' when done ++\n";
    }
}
close ($logfh);
if ( prompt ("Remove temporary log file $logfile? [y/N] ") eq "y" )
{
    unlink ($logfile);
    print STDOUT ("++ Removed log file $logfile ++\n");
}

sub m_system
{
    my $cmd = shift;
    my $die = shift;
    if ( $DEBUG )
    {
        print STDOUT $cmd."\n";
    }

    if ( system($cmd) )
    {
        print STDERR $!."\n";
        if ( $die > 0 ) 
        {
            die("Bailing out\n");
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
