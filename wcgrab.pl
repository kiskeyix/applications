#!/usr/bin/perl
# luis: www.sourceforge.net/projects/wcgrab
# A perl script to download and archive webcam images in jpg format.
# The script will determine how often the image is updated and will 
# download images to a series of sequentially numbered files.

# Get the url from the command line 
use LWP::Simple;
use HTML::Parser;

$| = 1;  # disable file buffering;

unless ($url = shift) {die "Must specify URL\n";}

# Convert the url into something that can be used as a dir.
$dirname = $url;
$dirname =~ s#http://##g;
$dirname =~ s#/#-#g;
print $dirname."\n";

# Change to the directory named in the url if it does not exist then create it
unless (chdir ("$dirname")) {
	mkdir ("$dirname", 0777) || die "Cannot create dir: $dirname\n";
	chdir ("$dirname") || die "Cannot chage to dir: $dirname\n";
}

#########################################################################
# Get an image from the specified url.  If the file is successfully downloaded
# and is different from previous download then save the image in incrementing
# file names. 
#########################################################################
$oldsum = '';		# Initialise some variables 
$dlcount = 0;
$timespan = 0;
$newtime = time;

do {
    # Get the last file number in the directory
	$highestnum = 0;
	while (defined ($nextname = <image*.jpg>)){
		$nextname =~ s/\.jpg//g;	# get rid of .jpg
		$nextname =~ m/\d*$/;		# get numbers at end
		$nextnum = $& + 0;
		if ($nextnum > $highestnum) {$highestnum = $nextnum}
	}
	$highestnum++;
	$filename = sprintf "%5s%7.7ld%4s", "image", $highestnum, ".jpg";
	#luis: I just care that the filename is the same as the previous one:
	#$filename = "mywebcam.jpg";
    # Download the Image
	$error = mirror($url, "temp.jpg");

	if ($error == RC_NOT_FOUND) 		{die "$url: not found\n";}
	if ($error == RC_MOVED_PERMANENTLY)	{die "$url: moved permananently\n";}
	if ($error == RC_MOVED_TEMPORARILY)	{die "$url: moved temporarily\n";}
	if ($error == RC_PARTIAL_CONTENT){
		print "$url: partial download...trying again\n";
	} 
	if ($error == RC_NOT_MODIFIED){
		print "x";
	}
	if ($error == RC_OK) {
		# Test to see if the jpg was downloaded completely by checking
		# to see if the last two digits of the downloaded file are xFF xD9
		# assume the download is complete if this is the case.
		$size = -s "temp.jpg";	# get size of file in bytes
		open (FIL, "temp.jpg");
		$badfile = 1;
		if ($size > 2) {
			$bufread = read (FIL, $buf, ($size - 2));
			if ($bufread != ($size - 2)) { die "wrong number of characters read\n"}
			$bufread = read (FIL, $buf, 2);
			if ($buf eq "\xff\xd9") {$badfile = 0}
		}
		close (FIL);	
		
		# Test the MD5SUM of the downloaded files against the MD5SUM of the
		# previous file if the file was completely downloaded.
		if ($badfile == 0) {
			$newsum = `md5sum temp.jpg`;
			if ($newsum == $oldsum) {
				print "\nMD5Sum indicates that file has not changed\n";
				$badfile = 1;
			} else {
				$oldsum = $newsum;
				$badfile = 0;
			}	
		}
		# Copy temp.jpg to the correctly sequenced file if it was completely
		# downloaded and is different from last image.  
		if ($badfile == 0) {
			open (IN, "temp.jpg") || die "Cant copy from temp.jpg\n";
			open (OUT, ">$filename") || die "Cant copy to $filename\n";
			while (<IN>) { print OUT $_; }
			close (IN);
			close (OUT);
    		print "$url: downloaded image: $filename\n";
			
			# Calculate the time between downloads
			$oldtime = $newtime;
			$newtime = time;
			$timespan = $newtime - $oldtime;
			print "Time since last download = $timespan seconds\n";

			# Add time between downloads to list			
			push(@timelist,$timespan);

			
			# Create list without anomalous values where each value 
			# is not less than half or greater than double the values
			# before and after it
			$#ntimelist = 0;   # reset ntimelist 
			for ($i = 1; $i < $#timelist; $i++) {
				if (($timelist[$i] < ($timelist[$i-1]*2)) and
					($timelist[$i] > ($timelist[$i-1]/2)) and
					($timelist[$i] < ($timelist[$i+1]*2)) and
					($timelist[$i] > ($timelist[$i+1]/2))) 
				{ 
					push (@ntimelist, $timelist[$i]);
					print "+++ adding $timelist[$i] to ntimelist.\n";
				} else {
					print "--- skipping $timelist[$i] as anomaly.\n";
				}
			}			
			
			# Find the average download time without anomalies after the
			# third download
			if ($dlcount > 2) {
				$sum = 0;
				foreach $i (@ntimelist) { 
					$sum += $i;
				}
				print "sum=$sum ntimelist=@ntimelist elements=$#ntimelist\n";
				$avg = int(($sum / ($#ntimelist+1))*0.9);
			} else {
				$avg = 0;
			}
			
			# Sleep for 90% of the average normalised download time
			print "Sleeping for $avg seconds.\n";
			sleep $avg;
			$dlcount++;
		} 
	} 
} while (1 == 1);

