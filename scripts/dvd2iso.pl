#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use Term::ReadLine;

# VERSION: 1.5
# This file is released under the GNU General Public License. All rights 
# reserved. Please check out http://www.gnu.org/copyleft/gpl.html before you 
# use this code. Minimal support may be provided by sending email to 
# james@nontrivial.org. The mjpegtools 1.6.0 (http://mjpeg.sourceforge.net/), 
# dvdbackup 0.1.1 (http://dvd.chevelless230.com/dvdbackup.html), transcode 
# 0.6.3 (http://www.theorie.physik.uni-goettingen.de/~ostreich/transcode/) and
# dvdauthor 0.5.0 (http://dvdauthor.sourceforge.net/) packages are required.
# Hit CTRL-C at any prompt to cancel. You can recover from that point later.
# If you use this code on copyrighted movies then your government probably
# considers you a dirty, smelly, hellbound pirate, and (especially in the USA) 
# you could face fines, confiscation of your computer(s) and/or imprisonment!
# *********** USE THIS CODE AT YOUR OWN RISK!! *************

my @Order;
my @Titles;
my %Titles;
my %Options;
my %FrameRate;
my %AspectRatio;
my $AVSync = 0;
my $OptsOK = getopts("a:b:i:f:v:w:t:o:z:pehkcdDsxqr", \%Options);
my $WorkDir = $ENV{HOME} . '/video';
my $SourceDir = '/dev/dvd';
my $MaxOutSize = 4482;
my $AudioChannel = 0;
my $FudgeBitRate = 0;
my $AudioBitRate = 384;
my $VideoBitRate = 3800; 
my $BogusVOBSize = 350000;
my $AudioFrequency = 48000;
my $TranscodeExtra = '-e 48000,16,2 -n 0x2000';
my $TranscodeFactor = 0.45;
my $Term = new Term::ReadLine 'Howdy';
$FrameRate{'23.976'}   = '24,1';
$FrameRate{'24.000'}   = '24,2';
$FrameRate{'25.000'}   = '25,3';
$FrameRate{'29.970'}   = '30,4';
$FrameRate{'30.000'}   = '30,5';
$FrameRate{'50.000'}   = '50,6';
$FrameRate{'59.940'}   = '60,7';
$FrameRate{'60.000'}   = '60,8';
$AspectRatio{'1:1'}    = 1;
$AspectRatio{'4:3'}    = 2;
$AspectRatio{'16:9'}   = 3;
$AspectRatio{'2.21:1'} = 4;

if (!$OptsOK || $Options{h}) {
  print("\n  Usage: dvd2iso <options>\n");
  print("     -i <dir>  Source directory/device.        [/dev/dvd]\n");
  print("     -w <dir>  Working directory.              [HOMEDIR/video]\n");
  print("     -o <name> Name of the resulting ISO file. [0000.iso]\n");
  print("     -t <list> Ordered comma seperated titles to process.\n");
  print("     -h This help.                            \n");
  print("     -s Scan the DVD and exit.                \n");
  print("     -q Process by title instead of chapter.  \n");
  print("     -p Split the DVD, do not transcode.      \n");
  print("     -x Known DVD5 (4.7 Gig) DVD. Duplicate.  \n");
  print("     -k Do everything but create an image.    \n");
  print("     -c Clobber any preexisting working files.\n");
  print("     -d Delete some working files as we go. (Not reccommended)\n");
  print("     -D Delete all working files as we go.  (Not reccommended!!)\n");
  print("\n   Transcoding options:                      \n");
  print("     -f <ms>   Audio/video sync fudge.         [0]\n");
  print("     -a <chan> Audio channel to grab.          [0]\n");
  print("     -b <rate> Target audio bitrate.           [384]\n");
  print("     -z <freq> Target audio frequency. 0=ac3   [48000]\n");
  print("     -v <rate> Target video bitrate.           [3800]\n");
  print("     -e Do not use framerate fine tuning.     \n");
  print("     -r Believe info from ripped vob, not DVD.\n\n");

  exit(0);
}

if (defined $Options{f}) { $AVSync = $Options{f}; }
if (defined $Options{w}) { $WorkDir = $Options{w}; }
if (defined $Options{i}) { $SourceDir = $Options{i}; }
if (defined $Options{b}) { $AudioBitRate = $Options{b};}
if (defined $Options{a}) { $AudioChannel = $Options{a}; }
if (defined $Options{z}) { $AudioFrequency = $Options{z}; }
if (scalar(@ARGV)) { $TranscodeExtra = join(' ', @ARGV); }

if ($Options{v}) {
  $VideoBitRate = $Options{v};
  $TranscodeFactor = $TranscodeFactor * (($VideoBitRate / 3800)**4);
}

# Calculate some stuff
$MaxOutSize = $MaxOutSize * 1048576;
$FudgeBitRate = sprintf("%03d", ($AudioBitRate/100.0) + $AudioBitRate + 1);

# Scan the DVD and exit, if requested
if ($Options{s}) {
  LogThis("Scanning the DVD...");
  my $TotalNum = SetTitleVals(1);
  for (my $Title = 2; $Title <= $TotalNum; $Title++) { SetTitleVals($Title); }
  exit(0);
}

# Duplicate the DVD and exit, if requested
if ($Options{x}) {
  LogThis("Duplicating the DVD...");
  RunThis("rm -rf $WorkDir/in $WorkDir/out $WorkDir/vob $WorkDir/iso");
  GetDVD();
  MakeImage(); 
  exit(0);
}

# Clear the logs
open(LOG, ">$WorkDir/dvd2iso.log");
close(LOG);
open(LOG, ">$WorkDir/command.log");
close(LOG);

# Check to see if the VOB files have been cached or get them
if (!ReadCache()) {
  LogThis("Scanning the DVD...");
  my $TotalNum = SetTitleVals(1);
  for (my $Title = 2; $Title <= $TotalNum; $Title++) { SetTitleVals($Title); }
  WriteCache();
}

if (defined $Options{t}) {
  @Order = split(/,/, $Options{t});
} else {
  for my $VideoInfo (@Titles) {
    my @VideoItems = split(/ /, $VideoInfo);
    push(@Order, $VideoItems[0]);
  }
}

GetVOBs();
for (my $Title = 1; $Title <= (scalar(@Titles) + 20); $Title++) {
  if (!(defined $Titles{$Title})) {
    my $TitleFiles = sprintf("%s/out/%03d.*.vob", $WorkDir, $Title);
    if ($Options{D}) {
      $TitleFiles = sprintf("%s/out/%03d*", $WorkDir, $Title);
    }
    RunThis("rm -f $TitleFiles");
  }
}
for my $Title (@Order) {
  if (!MungeVOBs($Title)) { 
    my $TitleFiles = sprintf("%s/out/%03d.*.vob", $WorkDir, $Title);
    if ($Options{D}) {
      $TitleFiles = sprintf("%s/out/%03d*", $WorkDir, $Title);
    }
    RunThis("rm -f $TitleFiles");
  }
}
if (!$Options{k}) { 
  MakeImageDir(); 
  MakeImage();
}

# Subroutines
sub GetDVD {
  LogThis("Getting data from the DVD...");
  my $CurrentDir = $WorkDir . '/iso';
  if (-e $CurrentDir) {
    RunThis("chmod -f 755 $WorkDir/iso/AUDIO_TS");
    RunThis("chmod -f 755 $WorkDir/iso/VIDEO_TS");
    RunThis("chmod -f 666 $WorkDir/iso/VIDEO_TS/*.*");
    RunThis("rm -rf $WorkDir/iso");
  }
  RunThis("dvdbackup -M -i $SourceDir -n iso -o $WorkDir");
}

sub MakeImage {
  LogThis("Creating DVD image...");
  my $Done = 0;
  for (my $Num = 0; $Num <= 9999; $Num++) { 
    if (!$Done) {
      my $Name = sprintf("%s/%04d.iso", $WorkDir, $Num);
      if ($Options{o}) { $Name = $Options{o}; }
      if ($Options{o} || (($Options{D} && GetSize('iso', $Num, 0, 'iso')))) {
	RunThis("rm -f $Name");
      }
      if ($Options{o} || !GetSize('iso', $Num, 0, 'iso')) {
	$Done = 1;
	if ($Options{D}) { RunThis("rm -rf $WorkDir/out"); }
	RunThis("mkisofs -udf -dvd-video -o $Name $WorkDir/iso/");
	my $IsoSize = GetSize($Name);
	if (!$IsoSize) {
	  LogThis("Unable to create file $Name! Aborting!",2);
	} else {
	  RunThis("chmod -f 755 $WorkDir/iso/AUDIO_TS");
	  RunThis("chmod -f 755 $WorkDir/iso/VIDEO_TS");
	  RunThis("chmod -f 666 $WorkDir/iso/VIDEO_TS/*.*");
	  RunThis("rm -rf $WorkDir/iso");
	  LogThis("DVD image file $Name of size $IsoSize has been created.");
	  if (-e "$WorkDir/out") {
	    if (!$Options{D} && !$Options{d}) {
	      LogThis("To test: xine -p -V Xv -A oss $WorkDir/out/*.vob");
	    }
	    LogThis("To burn: dvdrecord -v -dao speed=1 dev=1,0,0 $Name",0);
	    if (!$Options{D}) {
	      if (substr($Name,-4) eq '.iso') {	$Name = substr($Name,0,-4); }
	      LogThis("To save: tar -cvf $Name.tar $WorkDir/info.dvd $WorkDir/out/*.m*");
	    }
	  }
	}
      }
    }
  }
}

sub MakeImageDir {
  my $CurrentDir = $WorkDir . '/iso';
  LogThis("Preparing to make DVD image...");
  #RunThis("chmod -f 755 $WorkDir/iso/AUDIO_TS");
  #RunThis("chmod -f 755 $WorkDir/iso/VIDEO_TS");
  #RunThis("chmod -f 666 $CurrentDir/VIDEO_TS/*.*");
  #if (-e $CurrentDir) {
  #  RunThis("rm -rf $CurrentDir");
  #}
  #if ($Options{D} || $Options{d}) {
  #  RunThis("rm -rf $WorkDir/vob/*.vob");
  #}

  #mkdir $CurrentDir or LogThis("Could not create $CurrentDir: $!",1);
  #mkdir "$CurrentDir/AUDIO_TS" or 
  #  LogThis("Could not create $CurrentDir/AUDIO_TS: $!",1);
  #mkdir "$CurrentDir/VIDEO_TS" or 
  #  LogThis("Could not create $CurrentDir/VIDEO_TS: $!",1);

  RunThis("dvddirgen -o ".$ENV{"HOME"}."/video/iso");
  for my $Title (@Order) { WriteVTS($Title); }
  
  #RunThis("tocgen $WorkDir/iso/VIDEO_TS");
  RunThis("dvdauthor -T -o $WorkDir/iso");
  RunThis("chmod -f 500 $WorkDir/iso/AUDIO_TS");
  RunThis("chmod -f 500 $WorkDir/iso/VIDEO_TS");
  RunThis("chmod -f 400 $CurrentDir/VIDEO_TS/*.*");
}

sub WriteVTS {
  my ($Title) = @_;

  my $Names = '';
  my @VideoItems = split(/ /, $Titles[$Titles{$Title}]);
  my $Resolution = substr($VideoItems[5], 0, 3);

  LogThis("Preparing title $Title...");
  for (my $Chapter = 1; $Chapter <= $VideoItems[1]; $Chapter++) { 
    if (GetSize('out', $Title, $Chapter, 'vob')) {
      $Names = $Names . ' ' . 
	sprintf("%s/out/%03d.%03d.vob", $WorkDir, $Title, $Chapter);
    }
  }

  # ifogen audio format detection seems to be broken. This could be a problem.
  my $AudioFormat = 'ac3';
  if ($AudioFrequency && !(defined $Options{p})) { $AudioFormat = 'mp2'; }

  if ($Names) {
    RunThis("dvdauthor -o $WorkDir/iso $Names");
    #RunThis("ifogen --aspect-ratio $VideoItems[4] --audio-format $AudioFormat --resolution $VideoItems[5] --tv $VideoItems[3] -o $WorkDir/iso/VIDEO_TS/VTS --next-vts $Names");
  }
}

sub MungeVOBs {
  my ($Title) = @_;

  my $CurrentDir = $WorkDir . '/out';
  if (-e $CurrentDir) {
    if (GetSize('out', $Title, 0, 'vob')) {
      if (!YesNo("y", "Title $Title output data exists. Use it? (Y/n) ")) {
	my $TitleFiles = sprintf("%s/%03d.*.vob", $CurrentDir, $Title);
	if (YesNo("y", "Remove all title $Title output data? (Y/n) ")) {
	  $TitleFiles = sprintf("%s/%03d*", $CurrentDir);
	}
	RunThis("rm -f $TitleFiles");
      }
    }
  } else {
    mkdir $CurrentDir or LogThis("Could not create $CurrentDir: $!",1);
  }

  my $VobSize = GetSize('vob', $Title); 
  my $OutSize = GetSize('out', 0, 0, 'vob') - GetSize('out',$Title, 0, 'vob');
  if ($VobSize) {
    my $TmpChannel = $AudioChannel;
    my @VideoItems = split(/ /, $Titles[$Titles{$Title}]);
    if (!defined $Options{p}) { $VobSize = $VobSize * $TranscodeFactor; }
    if (($VobSize + $OutSize) < $MaxOutSize) {
      if (defined $Options{p}) {
	LogThis("Trying to fit Title $Title onto the DVD...");
      } else {
	LogThis("Trying to transcode Title $Title...");
      }
      for (my $Chapter = 1; $Chapter <= $VideoItems[1]; $Chapter++) {
	my $InName = sprintf("%s/vob/%03d.%03d.vob", $WorkDir,$Title,$Chapter);
	my $OutRoot = sprintf("%s/%03d.%03d", $CurrentDir, $Title, $Chapter);
	if (GetSize('vob', $Title, $Chapter, 'vob') > $BogusVOBSize) {
	  if (defined $Options{p}) {
	    RunThis("rm -f $OutRoot.m2v $OutRoot.mpa $OutRoot.vob");
	    RunThis("ln -f $InName $OutRoot.vob");
	  } else {
	    my $FrameRate = $FrameRate{$VideoItems[6]};
	    if (defined $Options{e}) { $FrameRate = $VideoItems[6]; }
	    my $SyncOptions = "-M 2 --psu_mode ";
	    if ($VideoItems[3] eq 'pal') { $SyncOptions = "-M 1"; }
	    my $AudioOptions = "-F 5,' -r 20 -g 9 -G 15 -d' " .
	      "-y mpeg2enc,raw -m $OutRoot.mpa -N 0x2000 -A ";
	    if ($AudioFrequency) {
	      $AudioOptions = "-F 5,' -B $FudgeBitRate -r 20 -g 9 -G 15 -d' " .
		"-N 0x50 -y mpeg2enc,mp2enc -E $AudioFrequency -b $AudioBitRate";
	    }
	    while (!GetSize('out',$Title, $Chapter, 'mpa') && $TmpChannel < 8) { 
	      RunThis("rm -f $OutRoot.m2v $OutRoot.mpa $OutRoot.vob");
	      RunThis("transcode -q 0 -a $TmpChannel -x vob -i $InName -w $VideoBitRate -V -f $FrameRate -g $VideoItems[5] $SyncOptions $AudioOptions -o $OutRoot --import_asr $AspectRatio{$VideoItems[4]} --export_asr $AspectRatio{$VideoItems[4]} --no_split $TranscodeExtra");
	      if (!GetSize('out', $Title, $Chapter, 'mpa')) { 
		$TmpChannel = $TmpChannel + 1; 
	      }
	    }
	    if (!GetSize('out', $Title, $Chapter, 'm2v')) {
	      LogThis("Unable to create file $OutRoot.m2v! Aborting!",2);
	    }
	    if (!GetSize('out', $Title, $Chapter, 'mpa')) {
	      LogThis("Unable to create file $OutRoot.mpa! Aborting!",2);
	    }
	    if (!GetSize('out', $Title, $Chapter, 'vob')) {
	      RunThis("tcmplex -m d -D $AVSync -o $OutRoot.vob -i $OutRoot.m2v -p $OutRoot.mpa");
	    }
	  }
	  if (!GetSize('out', $Title, $Chapter, 'vob')) {
	    LogThis("Unable to create file $OutRoot.vob! Aborting!",2);
	  } elsif ($Options{D}) {
	    RunThis("rm -f $OutRoot.m2v $OutRoot.mpa");
	  }
	  print('.');
	} else {
	  print("\n");
	  LogThis("Ignoring potentially bogus raw VOB $InName");
	  RunThis("rm -f $OutRoot.m2v $OutRoot.mpa");
	  my @Items = split(/ /, $Titles[$Titles{$Title}]);
	  $Items[1] = $Items[1] - 1;
	  splice(@Titles, $Titles{$Title}, 1, join(' ', @Items));
	  WriteCache();
	}
      }
      print("\n");
      
      $OutSize = GetSize('out', 0, 0, 'vob'); 
      LogThis("Current video size: $OutSize out of $MaxOutSize");
      if ($OutSize < $MaxOutSize) {
	LogThis("Title $Title has been added to the DVD.");
	return 1;
      } else {
	my $TitleFiles = sprintf("%s/%03d.*.vob", $CurrentDir, $Title);
	if ($Options{D}) {
	  $TitleFiles = sprintf("%s/%03d*", $CurrentDir, $Title);
	}
	RunThis("rm -f $TitleFiles");
	LogThis("Unable to transcode Title $Title to fit onto the DVD.");
      }
    } else {
      my $TitleFiles = sprintf("%s/%03d.*.vob", $CurrentDir, $Title);
      if ($Options{D}) {
	$TitleFiles = sprintf("%s/%03d*", $CurrentDir, $Title);
      }
      RunThis("rm -f $TitleFiles");
      LogThis("Not trying to fit Title $Title onto the DVD.");
    }
  } elsif (!(defined $Titles{$Title})) {
    LogThis("No raw data for Title $Title exists!");
  }
  return 0;
}

sub GetSize {
  my ($Directory, $Title, $Chapter, $Type) = @_;
  # Built in Perl file functions seem to choke on large files.
  
  my $Name;
  if (!$Type) { $Type = '*'; }
  if ($Directory eq 'iso' && $Type eq 'iso') {
    $Name = sprintf("%s/%04d.iso", $WorkDir, $Title);
  } elsif (!$Title && !$Chapter && $Type eq '*') {
    $Name = $Directory;
  } elsif (!$Title) {
    $Name = sprintf("%s/%s/*.%s", $WorkDir, $Directory, $Type);
  } elsif (!$Chapter) {
    $Name = sprintf("%s/%s/%03d.*.%s", $WorkDir, $Directory, $Title, $Type);
  } else {
    $Name = sprintf("%s/%s/%03d.%03d.%s", $WorkDir, $Directory, $Title, $Chapter, $Type);
  }

  my $Size = 0;
  my $NotThere = system("ls $Name 1>/dev/null 2>&1");
  if (!$NotThere) { 
    my @FileSizes = `du -sb $Name`;
    for my $FileSize (@FileSizes) {
      ($FileSize) = split(/\t/, $FileSize);
      $Size = $Size + $FileSize;
    } 
  }

  return $Size;
}

sub GetVOBs {
  my $CurrentDir = $WorkDir . '/vob';
  LogThis("Extracting audio and video data...");
  if (!(-e $CurrentDir)) {
    mkdir $CurrentDir or LogThis("Could not create $CurrentDir: $!",1);
  }
  for my $Title (@Order) {
    my $OutSize = GetSize('vob', $Title, 0, 'vob'); 
    if ($OutSize && !YesNo("y", "Title $Title raw data exists. Use it? (Y/n) ")) {
      my $TitleFiles = sprintf("%s/%03d.*.vob", $CurrentDir, $Title);
      RunThis("rm -rf $TitleFiles");
    }
    my @VideoItems = split(/ /, $Titles[$Titles{$Title}]);
    LogThis("Extracting title $Title...");
    for (my $Chapter = 1; $Chapter <= $VideoItems[1]; $Chapter++) {
      my $Name = sprintf("%s/%03d.%03d.vob", $CurrentDir, $Title, $Chapter);
      if (!GetSize('vob', $Title, $Chapter, 'vob')) { 
	if (-e "$WorkDir/in") { RunThis("rm -rf $WorkDir/in"); }
	if (defined $Options{p}) {
	  if (defined $Options{q}) {
	    if ($Chapter == 1) {
	      RunThis("dvdbackup -i $SourceDir -o $WorkDir -n in -t $Title");
	    } else {
	      mkdir "$WorkDir/in" or 
		LogThis("Could not create $WorkDir/in: $!",1);
	      mkdir "$WorkDir/in/VIDEO_TS" or 
		LogThis("Could not create $WorkDir/in/VIDEO_TS: $!",1);
	      RunThis("echo Nothing to see here! > $WorkDir/in/VIDEO_TS/x");
	    }
	  } else {
	    RunThis("dvdbackup -i $SourceDir -o $WorkDir -n in -t $Title -s $Chapter -e $Chapter");
	  }
	  for my $Item (split(/\n/,`ls -1  $WorkDir/in/VIDEO_TS`)) {
	    if (GetSize("$Name")) {
	      RunThis("cat $WorkDir/in/VIDEO_TS/$Item >> $Name");
	    } else {
	      RunThis("mv -f $WorkDir/in/VIDEO_TS/$Item $Name");
	    }
	    RunThis("rm -rf $WorkDir/in");
	  }
	} elsif (defined $Options{q}) {
	  if ($Chapter == 1) {
	    RunThis("tccat -i $SourceDir -T$Title,-1 > $Name");
	  } else {
	    RunThis("echo Nothing to see here! > $Name");
	  }
	} else {
	  RunThis("tccat -i $SourceDir -T$Title,$Chapter > $Name");
	}
      }
      if (!GetSize('vob', $Title, $Chapter, 'vob')) {
	LogThis("Unable to create file $Name! Aborting!",2);
      }
      print('.');
    }
    print("\n");
    if (defined $Options{r}) {
      SetTitleVals($Title, sprintf("%s/%03d.001.vob", $CurrentDir, $Title));
      WriteCache();
    }
  }
}

sub WriteCache {
  my $CurrentDir = $WorkDir . '/vob';
  if (!(-e "$CurrentDir")) {
    mkdir $CurrentDir or LogThis("Could not create $CurrentDir: $!",1);
  }
  LogThis("Caching DVD information...");
  open(OUT, ">$WorkDir/info.dvd");
  for my $Item (@Titles) { print(OUT "VI $Item\n"); }
  close(OUT);
}

sub ReadCache {
  my $CurrentDir = $WorkDir . '/vob';
  if ($Options{D}) {
    RunThis("rm -rf $WorkDir/*");
  } elsif ($Options{c}) {
    RunThis("rm -rf $WorkDir/in $WorkDir/out $WorkDir/vob $WorkDir/iso");
  } elsif (-e "$WorkDir/info.dvd") {
    if (YesNo("y", "Cached DVD data exists. Use it? (Y/n) ")) {
      LogThis("Reading cached DVD information...");
      open(FILE, "<$WorkDir/info.dvd");
      my @Lines = <FILE>;
      for my $Line (@Lines) {
	my @Items = split(/ /, $Line);
	if ($Items[0] eq 'VI') {
	  my $VideoInfo = $Items[1] . ' ' .  $Items[2] . ' ' .  
	    $Items[3] . ' ' . $Items[4] . ' ' . $Items[5] . ' ' . 
	    $Items[6] . ' ' . $Items[7] . ' ' . substr($Items[8], 0, -1);
	  push(@Titles, $VideoInfo);
	  if (defined $Options{t}) {
	    my @TitleList = split(/,/, $Options{t});
	    for my $Item (@TitleList) {
	      if ($Item == $Items[1]) {
		$Titles{$Items[1]} = scalar(@Titles) - 1;
	      }
	    }
	  } else {
	    $Titles{$Items[1]} = scalar(@Titles) - 1;
	  }
	}
      }
      close(FILE);
      return 1;
    } else {
      if (YesNo("y", "Delete data for next steps as well? (Y/n) ")) {
	RunThis("rm -rf $CurrentDir $WorkDir/out $WorkDir/iso");
      } else {
	RunThis("rm -rf $CurrentDir");
      }
    }
  } else {
    RunThis("rm -rf $CurrentDir");
  }
  return 0;
}

sub SetTitleVals {
  my ($Title, $Source) = @_;

  my $TotalNum = 0;
  my $Duration = 0;
  my $VideoInfo = $Title;
  for my $Item (@Titles) {
    my @VideoItems = split(/ /, $Item);
    if ($VideoItems[0] == $Title) {
      $Duration =  $VideoItems[7];
      $VideoInfo = $VideoItems[0] . ' ' . $VideoItems[1] . ' ' . 
	$VideoItems[2] . ' ' . $VideoItems[3]. ' ' . $VideoItems[4]; 
    }
  }
  if (!$Source) { $Source = $SourceDir; }
  my @ProbeInfo = split(/\n/, `tcprobe -i $Source -T $Title 2>&1`);
  for my $Line (@ProbeInfo) {
    my @Items = split(/ /, $Line);
    if ($Items[0] eq '(dvd_reader.c)') {
      if ($Items[1] eq 'DVD' && $Items[2] eq 'title') {
	if (!$TotalNum) { $TotalNum = substr(substr($Items[3], 2), 0, -1); }
	$VideoInfo = $VideoInfo . ' ' . $Items[4];
      } elsif ($Items[1] eq 'mpeg2') {
	$VideoInfo = $VideoInfo . " $Items[1] $Items[2] $Items[3]";
      } elsif ($Items[1] eq 'title' && $Items[2] eq 'playback') {
	$Duration = $Items[4];
      }
    } elsif ($Items[0] eq 'import' && $Items[1] eq 'frame') {
      $VideoInfo = $VideoInfo . ' ' . $Items[4];
    } elsif ($Items[7] && $Items[7] eq 'frame' && $Items[8] eq 'rate:') {
      $VideoInfo = $VideoInfo . ' ' . $Items[10];
    }
  }

  $VideoInfo = $VideoInfo . ' ' . $Duration;
  my @VideoItems = split(/ /, $VideoInfo);
  if (scalar(@VideoItems) != 8) {
    LogThis("Error getting video values for Title $Title!",1);
  } elsif ($VideoItems[2] ne 'mpeg2') {
    LogThis("Unknown video type '$VideoItems[2]' for Title $Title!",1);
  } elsif ($VideoItems[3] ne 'ntsc' && $VideoItems[3] ne 'pal') {
    LogThis("Unknown video format '$VideoItems[3]' for Title $Title!",1);
  }  

  if (!$FrameRate{$VideoItems[6]}) {
    LogThis("Unknown frame rate '$VideoItems[6]' for Title $Title!",1);
  }

  if (!$AspectRatio{$VideoItems[4]}) {
    LogThis("Unknown aspect ratio '$VideoItems[4]' for Title $Title!",1);
  }

  my $Text ="Title $Title Video: Duration=$VideoItems[7]\n       " .
    "Type=$VideoItems[2] Format=$VideoItems[3] Size=$VideoItems[5] " .
    "Rate=$VideoItems[6] Ratio=$VideoItems[4] Chapter(s)=$VideoItems[1]";
  LogThis($Text);

  if (defined $Titles{$Title}) {
    splice(@Titles, $Titles{$Title}, 1, $VideoInfo);
  } else {
    push(@Titles, $VideoInfo);
    if (defined $Options{t}) {
      my @TitleList = split(/,/, $Options{t});
      for my $Item (@TitleList) {
	if ($Item == $Title) {$Titles{$Title} = scalar(@Titles) - 1;}
      }
    } else {
      $Titles{$Title} = scalar(@Titles) - 1;
    }
  }
  return $TotalNum;
}

sub YesNo {
  my ($Default, $Question) = @_;

  my $Result;
  LogThis($Question);
  while (!$Result) {
    $Result = $Term->readline($Question);
    if (!$Result) { $Result = "$Default"; }
    if ($Result eq "Y" || $Result eq "y") { return 1; }
    if ($Result eq "N" || $Result eq "n") { return 0; }
    $Result = 0;
  }
}

sub RunThis {
  my ($Command) = @_;

  my @Date = localtime(time);
  my $Text = sprintf("\n%04d-%02d-%02d %02d:%02d:%02d RUNNING-> $Command\n", 
		     $Date[5] + 1900, $Date[4], $Date[3], $Date[2], $Date[1], 
		     $Date[0]);
  open(CMD, ">>$WorkDir/command.log");
  print(CMD $Text);
  close(CMD);
  open(OLDOUT, ">&STDOUT");
  open(OLDERR, ">&STDERR");
  close(STDOUT);
  close(STDERR);
  open(STDOUT, ">>$WorkDir/command.log");
  open(STDERR, ">>$WorkDir/command.log");
  system($Command);
  close(STDOUT);
  close(STDERR);
  open(STDOUT, ">&OLDOUT");
  open(STDERR, ">&OLDERR");
  close(OLDOUT);
  close(OLDERR);
}

sub LogThis {
  my ($Text, $Level) = @_;
  
  my @Date = localtime(time);
  $Text = sprintf("%04d-%02d-%02d %02d:%02d:%02d - $Text\n",
		     $Date[5] + 1900, $Date[4], $Date[3], $Date[2], $Date[1], 
		     $Date[0]);
  print($Text);
  open(LOG, ">>$WorkDir/dvd2iso.log");
  print(LOG $Text);
  close(LOG);
  if (defined $Level) {
    exit($Level);
  }
}
