#! /usr/bin/perl

# deprecated!
die "Use V2divx.pl instead";

use POSIX;

$usage=
"Warning:

Please note that you are only allowed to use this program according to fair-use
laws which vary from country to country. You are not allowed to
redistribute copyrighted material. Also note that you have to use this software
at your own risk.

You will find more info here:

  http://www.doom9.org/divx_linux_guide.html

There are 2 ways of using this program:

1: Easy
-----------

vob2divx4 /path/to/vobs 700
(where 700 is the desired filesize in Megabytes)

2: Better
----------

Step I:
vob2divx4 /path/to/vobs sample
(Program creates low-quality video and audio sample files so you can
choose the right audio track and the right cropping/resizing)

Step II:
(Choose the sample with perfect cropping and the right audio track)
vob2divx4 700 [audio_sample._-a_0_.000.avi] [video_sample._-j_0,0_-B_,0.000.avi]
(700 is the desired filesize again, the sample files are of course examples)

------------

You can interrupt the program anytime. To continue encoding, just run the script
without parameters in the same directory.

";

$audio_bitrate = 96;
$nice = 1;
$keyframes = 1000;
$sample = "";
$audiosample_length = 1000;
$videosample_length = 100;
$create_timeout = 2;
$timeout = 600;
$long_timeout = 20;

 sub IsInt
 {
    my ($a, $b);

    $a = $_[0];     # Original number
    $b = int($a);   # Convert to integer
    if ($a eq $b)   # Original number is an integer
    {
       return 1;
    }
    return 0;

 }

sub create_extract
{	$begin_time=time;
	if (! -e "tmp/extract.text")
	{	print("creating tmp/extract.text\n");
		print("This will take a little while....\n");
		$sys = " nice -".$nice." cat ".$vobpath."/*.[Vv][Oo][Bb] | nice -".$nice." tcextract -x ac3 -t vob | nice -".$nice." tcdecode -x ac3 | nice -".$nice." tcscan -b ".$audio_bitrate." -x pcm 2>> tmp/extract.text  >> tmp/extract.text";
		print ($sys."\n");
		system ("nice -".$nice." ".$sys);
	}
	$elapsed=time-$begin_time;
	print("\n\nTime extracting file info: ".floor($elapsed / 3600).":".floor(($elapsed % 3600)/60).":".($elapsed % 3600)."\n");
}

sub calculate_bitrate
{
 	$tmp = `cat tmp/extract.text | grep "A:" | grep MB`;
 	@tmp = split /A:/, $tmp;
#	$tmp = `cat tmp/extract.text | grep "audio:" | grep MB`;
#	@tmp = split /audio:/, $tmp;
	@tmp2 = split /MB/, @tmp[1];
	foreach $tmp (@tmp2)
	{	if ($tmp > 1)
		{
			$audio_size = $tmp * $audio_bitrate / 128;
			last;
		}
	}
	print("Audio_size: ".$audio_size."\n");

#	$tmp = `cat tmp/extract.text | grep "runtime:"`;
#	@tmp = split /runtime:/, $tmp;
	$tmp = `cat tmp/extract.text | grep "frames,"`;
	@tmp = split /frames,/, $tmp;
	@tmp2 = split /sec/, @tmp[1];
	foreach $tmp (@tmp2)
	{	if ($tmp > 1)
		{
			$runtime = $tmp;
			last;
		}
	}
	print("Runtime: ".$runtime."\n");

        $bitrate = floor(($filesize - $audio_size)/$runtime * 1024 * 1024 * 8 / 1000);
	if ($bitrate < 20)
	{	$bitrate = 700;
		print("\n#### ATTENTION ####\n\tCalculated bitrate is ".$bitrate." kbps, \nwhich does not make much sense, I'll use 700 kbps instead. \nFilesize will not match your preferred filesize. Sorry");
	}

	$tmp = `cat tmp/extract.text | grep "volume rescale"`;
	@tmp = split /rescale=/, $tmp;
	if ($tmp[1] > 1)
	{	chomp ($tmp[1]);
		$audio_rescale = $tmp[1];
	} else
	{	$audio_rescale = 1;
	}
	print ("Audio rescale: ".$audio_rescale."\n");
	system ("echo ".$audio_rescale." > tmp/audio_rescale.conf");
	print ("Bitrate: ".$bitrate."\n");
	system ("echo ".$bitrate." > tmp/bitrate.conf");


}

sub make_sample
{
	#print @_[0];
	if (! defined(@_[2]))
	{	@_[2] = 100;
	}
	$prefix = @_[1];
#	$sys = "transcode -i ".$vobpath."/".$sample." ".@_[0]." -w 100,".@_[2]." -t ".@_[2].",sample.".$prefix;
#	print ($sys."\n");
	my $pid = fork();
	die "couldn't fork\n" unless defined $pid;
	if ($pid)
	{       $time = 0;
		while (! -e $prefix.".001.avi")
		{	sleep $create_timeout;
			$time += $create_timeout;
			if (! -e $prefix.".000.avi")
			{       print $prefix.".000.avi can't be created\n";
				last;
			}
			if ($time > $timeout)
			{	print "Timeout! \n";
				last;
    			}

		}
		unlink $prefix.".001.avi";
#		print "parent\n";
		system("kill ".$pid);
	} else
	{
		$sys = "transcode -i ".$vobpath."/".$sample." ".@_[0]." -w 100,".@_[2]." -t ".@_[2].",".$prefix.".";
	#	$sys = "transcode  -i ".$ARGV[0]."/".$dateien[$probe]." -j ".$i.",".$j." -B ".$B.",0 -x vob -y divx4 -w 400,100 -t 100,probe_-j_".$i.",".$j."_-B-".$B.",0_";
		print ($sys."\n");
		exec ("nice -".$nice." ".$sys);
		# should never get here
		exit(1);
	}

}



mkdir ("tmp");

if ($ARGV[1] eq "sample")
{       $vobpath = $ARGV[0];

	$tmp = `ls -1 $vobpath | grep ".[Vv][Oo][Bb]"  `;
	@dateien = split /\n/, $tmp;
	$i = 0;
	system("echo ".$vobpath." > tmp/vobpath.conf");
	foreach $datei (@dateien)
	{	$i++;
		print ("File ".$i.": ".$datei."\n");
	}
	$sample = $dateien[floor($i / 2)];
	$anzahl = $i;

	$samples_look_like_crap = "Please note that these samples are exclusively to find the right
	cropping parameters (video_sample.*) and audio track (audio_sample.*)
	They look awful, the real movie will look much, much better!\n\n";

	print ("-> Using \"".$sample."\" to create low quality samples ".$samples_look_like_crap);
	$begin_time=time;
	for ($i = 0; $i <=6; $i ++)
	{
		make_sample("-x vob -y divx4 -a ".$i." ", "audio_sample._-a_".$i."_", $audiosample_length);
	}
	for ($i = 0; $i <= 80; $i += 16)
	{	for ($j = 0; $j <= 8; $j += 8)
		{	for ($B = 0; $B <= 4; $B ++)
			{       make_sample(" -j ".$i.",".$j." -B ".$B.",0 -x vob -y divx4 ", "video_s._-j_".$i.",".$j."_-B_".$B.",0", $videosample_length);
			}
		}
	}
	$elapsed=time-$begin_time;

	print("\n".$samples_look_like_crap."\n\nTime for creating samples: ".floor($elapsed / 3600).":".floor(($elapsed % 3600)/60).":".($elapsed % 3600)."\n");
	exit(0);
}

if ($ARGV[1] eq "continue" || $ARGV[0] eq "continue" || ! defined($ARGV[0]))
{	if (-e "tmp/vobpath.conf" && -e "tmp/filesize.conf" && -e "tmp/params.conf")
	{	$vobpath = `cat tmp/vobpath.conf`;
		chomp($vobpath);
		if (! -d $vobpath)
		{	print("Path: ".$vobpath." does not exist.\n");
			exit(1);
		}
		$filesize = `cat tmp/filesize.conf`;
		chomp ($filesize);
		$params = `cat tmp/params.conf`;
		chomp ($params);
	} else
	{	print($usage);
		exit(0);
	}
	print("Path to VOBs: ".$vobpath."\n");
	print("Preferred Filesize: ".$filesize."\n");
	print("Additional Parameters: ".$params."\n");
} else
{       $i = 0;
	if ( -e $ARGV[$i])
	{	$vobpath = $ARGV[$i];
		$i ++;
	} else
	{	if ( ! -e "tmp/vobpath.conf")
		{	print("Please supply path to find vobfiles");
			exit(1);
		} else
		{	$vobpath = `cat tmp/vobpath.conf`;
			chomp($vobpath);
			if (! -e $vobpath)
			{	print("Path: ".$vobpath." does not exist.\n");
				exit(1);
			}
		}
	}
	if ($ARGV[$i] > 1)
	{	$filesize = $ARGV[$i];
		$i++;
	} else
	{	if (-e "tmp/filesize.conf")
		{	$filesize = `cat tmp/filesize.conf`;
			chomp($filesize);
		} else
		{	print("Please supply filesize \n\tor \"sample\" if you want to create samples for cropping.\n\n");
			exit(1);
		}
	}
	while(defined($ARGV[$i]))
	{       @tmp = split /\./, $ARGV[$i];
		$t = $tmp[1];
		$t =~ tr [_] [ ];
		$params .= $t;
		$i++;
	}

	print("Path to VOBs: ".$vobpath."\n");
	system("echo ".$vobpath." > tmp/vobpath.conf");
	print("Preferred Filesize: ".$filesize."\n");
	system("echo ".$filesize." > tmp/filesize.conf");
	print("Additional Parameters: ".$params."\n");
	system("echo ".$params." > tmp/params.conf");
}

if (1)
{       if (! -e "tmp/extract.text")
	{	create_extract;
	}
	# else
	#{	if (! defined($bitrate))
#		{	$bitrate = `cat tmp/bitrate.conf`;
 #               	chomp($bitrate);
#		}
#		$audio_rescale = `cat tmp/audio_rescale.conf`;
#		chomp($audio_rescale);
 #
#	}
	calculate_bitrate;

	$tmp = `ls -1 $vobpath | grep ".[Vv][Oo][Bb]"  `;
	@dateien = split /\n/, $tmp;
	$i = 0;

	#my $pid = fork();
	#die "couldn't fork\n" unless defined $pid;
	#if ($pid)
	#}	for(;;)
	#	{	sleep 10000;
	#	}
	#} else
	#{

#	$i = 0;
#	$optionen = $ARGV[1];
	#$audio = 2.6;
	system("rm tmp/*.started");
	foreach $datei (@dateien)
	{	if (! -e "tmp/1-".$datei.".done")
		{	print("Encode: ".$datei."\n");
			my $pid = fork();
			die "couldn't fork\n" unless defined $pid;
			if ($pid)
			{	while(! -e  "tmp/1-".$datei.".started")
				{	sleep $long_timeout;
				}
				system("touch tmp/1-".$datei.".done");
			} else
			{
				$sys = "transcode -i ".$vobpath."/".$datei." ".$params." -s ".$audio_rescale." -w ".$bitrate.",".$keyframes." -b ".$audio_bitrate." -x vob -y divx4 -R 1 -t ".$keyframes.",tmp/1-".$datei."-";
				print($sys."\n");
				system("nice -".$nice." ".$sys);
				#$exit_value  = $? >> 8;
				#print "\n\n--->>".$exit_value."<<---\n\n\n";
				system("touch tmp/1-".$datei.".started");
				exit(0);
			}
		} else
		{	print($datei." already encoded, remove \"tmp/1-".$datei.".done\" to reencode \n");
		}
		if (! -e "tmp/2-".$datei.".done")
		{	print("Encode: ".$datei."\n");
			my $pid = fork();
			die "couldn't fork\n" unless defined $pid;
			if ($pid)
			{	while(! -e  "tmp/2-".$datei.".started")
				{	sleep $long_timeout;
				}
				system("touch tmp/2-".$datei.".done");
			} else
			{
				$sys = "transcode -i ".$vobpath."/".$datei." ".$params." -s ".$audio_rescale." -w ".$bitrate.",".$keyframes." -b ".$audio_bitrate." -x vob -y divx4 -R 2 -t ".$keyframes.",tmp/2-".$datei."-";
				print($sys."\n");
				system("nice -".$nice." ".$sys);
				system("touch tmp/2-".$datei.".started");
				exit(0);
			}
		} else
		{	print($datei." already encoded, remove \"tmp/2-".$datei.".done\" to reencode \n");
		}
		#if (! -e "tmp/2-".$datei.".done")
		#{	$sys = "transcode -i ".$vobpath."/".$datei." ".$params." -s ".$audio_rescale." -w ".$bitrate.",".$keyframes." -b ".$audio_bitrate." -x vob -y divx4 -R 2 -t ".$keyframes.",tmp/2-".$datei."-";
		#	print($sys."\n");
		#	system("nice -".$nice." ".$sys);
		#	system("touch tmp/2-".$datei.".done");
		#} else
		#{	print($datei." already encoded, remove \"tmp/2-".$datei.".done\" to reencode \n");
		#}
		#$i++;
	}
	if (! -e "tmp/merge.done")
	{       my $pid = fork();
		die "couldn't fork\n" unless defined $pid;
		if ($pid)
		{	while(! -e  "tmp/merge.started")
			{	sleep $long_timeout;
			}
			system("touch tmp/merge.done");
		} else
		{
			$sys = "avimerge -i tmp/2-*.avi -o movie.avi";
			print($sys."\n");
			system("nice -".$nice." ".$sys);
			system("touch tmp/merge.started");
			exit(0);
		}
	}
}

# 2.6
