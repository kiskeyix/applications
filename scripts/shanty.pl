#! /usr/bin/perl -w
use GD;				# graphics library
use strict;			# bitch about everything

# Shanty v2 - 27 June 2002
# Written by Duncan Martin - http://www.codebunny.org
# take a text file and an image (PNG or JPG) and make a Postscript file.
# one pixel in the image becomes one character in the Postscript file.

# Source licence:  No warranty.  Reuse freely but give credit.

# format is
# shanty.pl  -i imagefile [-t textfile] [-o outputfile] [-s papersize]
#           [-d density] [-m margin] [-b background colour [-x padding]]
#           [-n title] [-l orientation]
#
#
#
# -i : name of the image to load in, this is the only compulsory field.
# -t : name of the text file to load in, if omitted STDIN is use.
# -o : name of the postscript file to produce, if omitted STDOUT is use.
# -s : size of the paper to work with.  This field should be a name, e.g.'a4',
#      see the list of paper sizes below.  Default is a4.
# -d : density of the text.  Higer numbers are most dense, default is 1.4.
# -m : the margins of the page in cm.  Default is 1.
# -b : The colour of a backing rectangle to place behind the text.  Colours are
#      specified as 'R,G,B' with each value between 0 and 255.  'off' means use
#      no backing colour.  Default is 'off'.
# -x : The distance in cm that the backing rectangle should extend from each
#      edge of the text.
# -n : The title of the output to write as meta-data in the Postscript file.
#      Default is 'Shanty output'.
#      Default is 0.5cm.
# -l : The orientation of the paper, can be 'portrait', 'landscape' or 'auto'.
#      Default is 'auto'.

# -----------------------------------------------------------------------------

# function declarations
sub error($);
sub getSwitches();
sub switchError($);

# page size lookups
# key is the lower case name, which is searched for my the -s switch
# the value is name to be used for paper size declaration in the output, and
# then the width and height in points.
my %pageSize = (
	'a0'		=> "A0,2380,3368",
	'a1'		=> "A1,1684,2380",
	'a2'		=> "A2,1190,1684",
	'a3'		=> "A3,842,1190",
	'a4'		=> "A4,595,842",
	'a5'		=> "A5,421,595",
	'a6'		=> "A6,297,421",
	'letter'	=> "Letter,612,792",
	'broadsheet'	=> "Broadsheet,1296,1584",
	'ledger'	=> "Ledger,1224,792",
	'tabloid'	=> "Tabloid,792,1224",
	'legal'		=> "Legal,612,1008",
	'executive'	=> "Executive,522,756",
	'36x36'         => "36x36,2592,2592"
);

# default values
my ($chosenSize, $density, $margin)	= ("a4", 1.4, 1);
my ($shade, $orientation, $shadeMargin)	= (0, "Auto", 0.5);
my $title = "Shanty output";

# globals
my ($imageFile, $textFile, $outputFile)	= ("", "", "");
my ($shadeRed, $shadeGreen, $shadeBlue);

# get options specified on the command line
getSwitches();

# say hello
print STDERR "Shanty v2\nWritten by Duncan Martin\nhttp://www.codebunny.org\n\n";
print STDERR "Image file: $imageFile\n";
print STDERR "Text file: ";
if ($textFile eq "") {
	print STDERR "STDIN\n";
} else {
	print STDERR $textFile,"\n";
}
print STDERR "Output file: ";
if ($outputFile eq "") {
	print STDERR "STDOUT\n";
} else {
	print STDERR $outputFile,"\n";
}
print STDERR "Paper size: $chosenSize\n";
print STDERR "Margin: ${margin}cm\n";
print STDERR "Orientation: $orientation\n";
print STDERR "Print density: ${density}\n";
print STDERR "Background: ";
if (!$shade) {
	print STDERR "none\n";
} else {
	print STDERR "$shadeRed,$shadeGreen,$shadeBlue\n";
	print STDERR "Background margin: ${shadeMargin}cm\n";
}

# open and get image file
if (!-r $imageFile) {
	error("couldn't read image file");
}
if ((lc $imageFile) !~ (/\.([a-z]+)$/g)) {
	error("couldn't work out image file extension");
}
my $extension = $1;
my $imageHandle;

# compare extension to find image file type, then load in
# for PNG files
my $transparent = -1;
if ($extension eq "png") {
	$imageHandle	= newFromPng GD::Image($imageFile);
	$transparent	= $imageHandle->transparent(); 

# for JPG files
} elsif (($extension eq "jpg") || ($extension eq "jpeg")) {
	$imageHandle = newFromJpeg GD::Image($imageFile);

# otherwise return an error
} else {
	error("files of type '$extension' are not supported, please use PNG or JPG");
}

# error check
if (!$imageHandle) {
	error("failed to load '$imageFile'");
}

# try to get input
my $textHandle;
my $allText	= "";

# for stdin
if ($textFile eq "") {
	$textHandle 	= *STDIN{IO};
	print STDERR "> waiting for STDIN....\n";
} else {
	open $textHandle, $textFile or error("couldn't open text file");
}

# read eveything from the file
while (<$textHandle>) {
	$allText .= $_;
}

# close the file
if ($textFile ne "") {
	close $textHandle;
}

# turn all white-spaces to a maximum one space
$allText =~ s/\s+/ /g;

# open the file for writing
my $outputHandle;

# for stdin
if ($outputFile eq "") {
	$outputHandle 	= *STDOUT{IO};
} else {
	open $outputHandle, "> $outputFile" or error("couldn't open output file");
}

# declare as postscript
print $outputHandle "%!PS-Adobe-2.0\n";

# Now get the dimensions of the picture
my ($xSize,$ySize) = $imageHandle->getBounds();
print STDERR "> picture size:  ${xSize}x${ySize}\n";

# presume portrait for now
my ($psPageSize, $pointWidth, $pointHeight) = split ",",$pageSize{$chosenSize};
print STDERR "> paper size: ${pointWidth}x${pointHeight}points\n";

# if orientation is automatic, work out what's best
if ($orientation eq "Auto") {
	if ($xSize > $ySize) {
		$orientation = "Landscape";
	} else {
		$orientation = "Portrait";
	}
	print STDERR "> orientation: $orientation\n";
}

# flip dimensions if landscape
if ($orientation eq "Landscape") {
	my $a = $pointWidth;
	$pointWidth	= $pointHeight;
	$pointHeight	= $a;
	$psPageSize	.= "l";
}

# work out if the page sizes when considering the margin
my $eWidth	= $pointWidth 	- ($margin * 144) / 2.54;
my $eHeight 	= $pointHeight	- ($margin * 144) / 2.54;

# find which dimension is the limiting factor
my $fontSize;
if (($eWidth / $xSize) < ($eHeight / $ySize)) {
	$fontSize = $eWidth / $xSize;
} else {
	$fontSize = $eHeight / $ySize;
}

# work out the starting positions
my $xStart = ($pointWidth - ($fontSize * $xSize)) / 2;
my $yStart = $pointHeight - (($pointHeight - ($fontSize * $ySize)) / 2) - $fontSize;

# declare document size in postscript
print $outputHandle <<EOF;
\%\%Title: $title
\%\%Creator: Shanty v2 - http://www.codebunny.org
\%\%DocumentPaperSizes: custom
\%\%DocumentMedia: $psPageSize $pointWidth $pointHeight 80 white ( )
\%\%Orientation: Portrait
\%\%Pages: 1
\%\%EndComments

\%\%BeginDefaults
\%\%PageMedia: $psPageSize $pointWidth $pointHeight 80 white ( )
\%\%PageOrientation: Portrait
\%\%EndDefaults

<< /PageSize [$pointWidth $pointHeight] >> setpagedevice

EOF

# change to Courier font
print $outputHandle "/Courier-Bold findfont\n";

# set the point size
print $outputHandle $fontSize*$density," scalefont setfont\n";

print STDERR "> starting y: $yStart\n> starting x: $xStart\n";

# store the y position
print $outputHandle "/ypos $yStart def\n";

# define the procedure to print one char
print $outputHandle "/onechar { xpos ypos moveto show /xpos xpos $fontSize add def} def\n";

# define the procedure to skip a char
print $outputHandle "/skipchar { /xpos xpos $fontSize add def} def\n";

# draw the backing box
if ($shade) {
	$shadeRed /= 255;
	$shadeGreen /= 255;
	$shadeBlue /= 255;
	my $shadeMar = ($shadeMargin * 72) / 2.54;
	my $shadeWidth	= ($shadeMar * 2) + ($fontSize * $xSize);
	my $shadeHeight = ($shadeMar * 2) + ($fontSize * $ySize);
	my $shadeX	= $xStart - $shadeMar;
	my $shadeY	= $yStart + $shadeMar + $fontSize; 
	print $outputHandle <<EOF;
$shadeRed $shadeGreen $shadeBlue setrgbcolor
newpath
$shadeX $shadeY moveto
$shadeWidth 0 rlineto
0 -$shadeHeight rlineto
-$shadeWidth 0 rlineto
0 $shadeHeight rlineto
fill
EOF
}

# get the length of the text, and set the counter to 0
my $textOffset = 0;
my $textLen	= length $allText;

# set the last colour seen to something impossible
my ($lastRed, $lastGreen, $lastBlue) = (-1, -1, -1);

# set the initial y position
print $outputHandle "/ypos $yStart def\n";

# loop for all pixels
for (my $yScan = 0; $yScan < $ySize; $yScan++) {

	# set the x position to the start of the line
	print $outputHandle "/xpos $xStart def\n";

	# scan through the horizontal line
	for (my $xScan = 0; $xScan < $xSize; $xScan++) {
	
		# get a single character of text
		my $char = substr($allText, $textOffset, 1);
		
		# adjust the character to keep it nice and legal
		$char =~ s/\\/\\\\/go;
		$char =~ s/\//\\\//go;
		$char =~ s/\(/\\\(/go;
		$char =~ s/\)/\\\)/go;

		# get the colour from the image
		my $colIndex = $imageHandle->getPixel($xScan,$yScan);
    	    	my ($red,$green,$blue) = $imageHandle->rgb($colIndex);

		# if this colour is transparent, skip on
		if ($colIndex == $transparent) {
			print $outputHandle "skipchar\n";
			next;
		}		
		
		# if this is too close to white, and we don't have
		# a background shade, just move on
		if (!$shade && (($red + $green + $blue) > 750)) {
			print $outputHandle "skipchar\n";
			next;
		}
		
		# turn the RGB colour into PS style colour		
		$red /= 255;
		$green /= 255;
		$blue /= 255;

		if (($red != $lastRed) || ($green != $lastGreen) || ($blue != $lastBlue)) {
			print $outputHandle "$red $green $blue setrgbcolor\n";	
			$lastRed	= $red;
			$lastGreen	= $green;
			$lastBlue	= $blue;
		}
		
		# call the routine to print a character
		print $outputHandle "($char) onechar\n";
		
		# move the text counter along, if at the end of the string
		# go back to the start
		$textOffset++;
		if ($textOffset >= $textLen) {
			$textOffset = 0;
		}
	} 
	
	# move the y position down a line
	print $outputHandle "/ypos ypos $fontSize sub def\n";
}


# show the page
print $outputHandle "showpage\n";

# close the file
if ($outputFile ne "") {
	close $outputHandle;
}

# we're done, thank you, it's been a pleasure.
exit(0);

# ------------------------
# function definitions

# get input switches
sub getSwitches() {
	my $numArgs	= @ARGV;
	my $scan	= 0;
	my $switch;
	my %seen;
	
	while ($scan < $numArgs) {
		
		# make sure this is a switch
		if ($ARGV[$scan] !~ /^-([a-z])$/) {
			switchError("found \"$ARGV[$scan]\" when expecting a switch");
		}
		$switch = $1;
		
		if ($seen{$switch}) {
			switchError("switch \"$switch\" specified twice");
		}
		$seen{$switch}++;

		# move onto the argument 
		$scan++;
		
		# if next argument is a switch, or no more arguments, that's an error
		if (($scan >= $numArgs) || ($ARGV[$scan] =~ /^-/)) {
			switchError("missing argument for switch \"$switch\"");
		}
		
		# do something with the switch
		if ($switch eq "i")	{ $imageFile	= $ARGV[$scan]; }
		elsif ($switch eq "o")	{ $outputFile	= $ARGV[$scan]; }
		elsif ($switch eq "t")	{ $textFile	= $ARGV[$scan]; }
		elsif ($switch eq "s") {
			$chosenSize = lc $ARGV[$scan];
			if (!exists $pageSize{$chosenSize}) {
				switchError("unknown page size");
			}
		} elsif ($switch eq "m") {
			if ($ARGV[$scan] =~ /^([\d\.]+)$/) {
				$margin		= $1;
			} else {
				switchError("invalid margin format");
			}
		} elsif ($switch eq "d") {
			if ($ARGV[$scan] =~ /^([\d\.]+)$/) {
				$density	= $1;
			} else {
				switchError("invalid margin format");
			}
		} elsif ($switch eq "b") {
			if ($ARGV[$scan] =~ /^([\d]+),([\d]+),([\d]+)$/) {
				$shadeRed	= $1;
				$shadeGreen	= $2;
				$shadeBlue	= $3;
				$shade		= 1;
			} else {
				switchError("bad background shade value");
			}
			
			if (($shadeRed > 255) || ($shadeGreen > 255) || ($shadeBlue > 255)) {
				switchError("RGB values must be between 0 and 255");
			}
		} elsif ($switch eq "x") {
			if ($ARGV[$scan] =~ /^([\d\.]+)$/) {
				$shadeMargin	= $1;
			} else {
				switchError("invalid background padding format");
			}
			
		} elsif ($switch eq "l") {
			if (($ARGV[$scan] eq "p") || ($ARGV[$scan] eq "portrait")) {	
				$orientation = "Portrait";
			} elsif (($ARGV[$scan] eq "l") || ($ARGV[$scan] eq "landscape")) {
				$orientation = "Landscape";
			} elsif (($ARGV[$scan] eq "a") || ($ARGV[$scan] eq "auto")) {
				$orientation = "Auto";
			} else {
				switchError("unknown orientation");
			}
		} elsif ($switch eq "n") {
			$title = $ARGV[$scan];
		
		} else {
			switchError("unknown switch \"$switch\"");
		}

		# move on
		$scan++;
	}
	
	# image file compulsory
	if (!$seen{"i"}) {
		switchError("no image file specified");
	}	
}
	
# problem with the switches
sub switchError($) {
	print STDERR "error> $_[0], use 'shanty' -h for help\n";
	exit(-1);
}

# general error
sub error($) {
	print STDERR "error> $_[0]\n";
	exit(-1);
}
