#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Feb-08
#
# DESCRIPTION: A simple script to install GnoMetal2 in one shot
# USAGE: [sudo] ./install.pl --all [or --user for single user]
# CHANGELOG:
#   * 2003-12-26 15:04 EST  initial version
#
use strict;
$|++;

my $NAME="GnoMetal2"; # name of this theme
my @packages=("gaim","icons","themes"); # packages inside: $NAME-$package[$i].tar.bz2. Also the names of the directories .themes, .icons, etc.. 


# you can customize this from the command line:
# -u -r -g "/path/to/gaim/pixmaps" -t "/path/to/themes" -i "/path/to/icons"
my $USER=0; # install only for the user executing this script
my $ALL=0; # installing for all users
my $GAIM="/usr/share/pixmaps";
my $THEMES="/usr/share/themes";
my $ICONS="/usr/share/icons";

# -------------------------------------------- #
#        No need to modify below this line     #
# -------------------------------------------- #

# get options. Most of the V2divxrc options (if not all)
# should be overriden by this command line ones
use Getopt::Long;
Getopt::Long::Configure('bundling');

# get options
# declare empty variables
my $HELP = 0;
GetOptions(
    # flags
    'h|help'        =>  \$HELP,
    'u|user'        =>  \$USER,
    'a|all'         =>  \$ALL,
    # strings
    'G|gaim=s'      =>  \$GAIM,
    'I|icons=s'     =>  \$ICONS,
    'T|themes=s'    =>  \$THEMES
    # numbers
);

my $USAGE = "./install.pl --user|--all [--gaim=$GAIM][--icons=$ICONS] [--themes=$THEMES]\n \t --user [exclusive] install only for this user\n \t --all [exclusive] install for all users\n \t --gaim path which contains gaim pixmaps directory [$GAIM]\n \t --themes path for the themes folder [$THEMES]\n \t --icons path for the icons folder [$ICONS]\n\n";

if ( $HELP > 0  || ( $ALL == 0 && $USER == 0 ) ) 
{
    print STDOUT "$USAGE";
    exit(0);
}

# ================ MAIN ================ #

my $file = "";
my $package_dir = `pwd`; # assuming we ran ./install.pl
chomp($package_dir); # remove new_line char

# this is very very ugly code, but it works... so shut up!
foreach $file (@packages)
{
    # when using root (uid 0) we install for all automatically
    if ( $ALL > 0 || $< == 0 ) 
    {
        if ( $file eq "gaim" ) 
        {
            chdir("$GAIM");
            extract("$package_dir/$NAME-$file.tar.bz2");
        } elsif ( $file eq "themes" ) {
            chdir "$THEMES";
            extract("$package_dir/$NAME-$file.tar.bz2");
        } elsif ( $file eq "icons" ) {
            chdir("$ICONS");
            extract("$package_dir/$NAME-$file.tar.bz2");
        }
    }

    # install for regular user only
    elsif ( $USER > 0 ) 
    {
        if ( $file ne "gaim" )
        {
            chdir "$ENV{'HOME'}/.$file";
            extract("$package_dir/$NAME-$file.tar.bz2");
        }
        # gaim notice
        if ( $file eq "gaim" )
        {
            print STDERR "You will need to unpack $package_dir/$NAME-$file.tar.bz2 in $GAIM or wherever your Gaim installation is.\n";
        }
    }
}

# ============= FUNCTIONS =============== #
sub extract
{
    my $TAR=shift;
    system("tar xjf $TAR");
    if ( $? != 0 )
    {
        print STDERR "Extracting $TAR failed. $!"
    }
}
