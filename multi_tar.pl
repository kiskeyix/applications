#!/usr/bin/perl
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Apr-08
# $Revision: 1.2 $
#
# DESC: Creates multiple tar files of XX size and then
#       compresses them using a given command
# 
# USAGE: call this script from the directory where the
# tar files will be created passing the directories which
# will be included in the tar:
#   i.e.
#   multi_tar.pl --dir='DIRECTORY'
#   
#   This will start a tar archive using:
#
#   tar cvf test.tar --multi-volume \
#       --volno-file file_number  -L 1024 \
#       --info-script=./change_tape.sh  DIRECTORY

use strict;
$|++;

use Getopt::Long;
Getopt::Long::Configure('bundling');

my $usage="Usage: multi_tar [-v|--verbose] [-c bzip2| --compress='bzip2'] [-n name| --name='name'] [-s size | --size='size'] [-t file_number_name_for_tar] --dir='dirname'\n
\nUSAGE: call this script from the directory where the
tar files will be created passing the directories which
will be included in the tar:
  i.e.
  multi_tar.pl DIRECTORY
  
  This will start a tar archive using:

  tar cvf test.tar --multi-volume \
      --volno-file file_number  -L 1024 \
      --info-script=./change_tape.sh  usr/";

my $verbose="0";
my $COMPRESS="bzip2"; # compress command
my $NAME="temp-name.tar";
my $FILE_SIZE="102400"; # KB before compressing. 100*1024*1024B = 100MB 
my $FILE_NUMBER="/tmp/file_number";
my $NUMBER="";
my $DIR="";

#my $SCRIPT="./$0" # call yourself without arguments!

die "$usage"
unless GetOptions(
    'v|verbose' => \$verbose,
    'c|compress'   => \$COMPRESS,
    'n|name'    => \$NAME,          
    's|size'    => \$FILE_SIZE,
    't|filenumber'  => \$FILE_NUMBER,
    'dir' => \$DIR
);


if (!$ARGV[0]) {
    print STDERR $usage; 
    exit 1; 
}


# when directories or files are passed, we start tarring them
# else we act as part two, which takes the resulting filename and
# renames it and then compresses it
if ( -d $DIR ) { 
    unlink $FILE_NUMBER;
    #tar -cvf $NAME --multi-volume --volno-file $FILE_NUMBER -L $FILE_SIZE --info-script=$SCRIPT $@
    system("tar -cvf $NAME \
    --multi-volume --volno-file $FILE_NUMBER \
    -L $FILE_SIZE \
    --info-script=$SCRIPT $DIR");
    die "Tar failed\n" if ( $? != 0 );
        
}
if ( $COMPRESS =~ /\w+/ ) {
    rename  $NAME "$NAME.$NUMBER.tar"
    system("$COMPRESS $NAME.$NUMBER.tar");
    die "Compressing $NAME.$NUMBER.tar failed" if ($? != 0);
}

