#!/usr/bin/perl 
# do not show so many warnings: -w ;    ;-)

# Luis Mondesi  <lemsx1@hotmail.com> 2002-01-17
# Use this script in Nautilus to create HTML files
# with their proper thumbnails for pictures (.jpeg or .gif)
# 
# Make this file executable and put it in:
# ~/.gnome/nautilus-scripts
# 
# Then run it from from the File::Scripts::script_name menu
# 
# You could customize each directory differently by having a
# file named .pictDir2htmlrc in the directory containing the
# pictues. This file has the form:
# 
# percent=30%;; #size of the thumbnails for this folder
# title=Title;;
# html_msg=<h1>Free form using HTML tags</h1> <h2> ending in 
# two semicolons</h2> <p> this is a single line. Do not permit
# line breaks</p>;;
# body=<body bgcolor='#000000'>;;
# p=<p>;; # or whichever way you want to customize this tag
# table=<table border='0'>;;
# td=<td valign='left'>;;
# tr=<tr>;;
# footer=<a href='#'>A footer here</a>;;
# 
# These are the only tags that you can customize for now :-)
# Required: linux/UNIX "convert" command (to convert images from
#	    one format to another or sizes, etc...
# 
# Known bugs: config file cannot contain lines that spawn to multiple
# lines. Will fix later.
# 
# Put a .nopictDir2htmlrc file in directories for which you do not want
# thumbnails and/or index.html to be written
#
#use Image::Size; #messures image sizes... not needed for now
use strict;
use vars qw( $VERSION @INC );
use Config;
my $VERSION="0.3";
$|++; # disable buffer

# later I will use $argument = shift; to parse all directories
# for now, only one dir can be parse at a time :-D

# Use current directory works with Nautilus :-)
# put this file in ~/.gnome/nautilus-scripts
my $IMAGE_DIRECTORY=(-d "$ARGV[0]") ? "$ARGV[0]":".";
my $FILE_NAME="index.php";
my $CONFIG_FILE=".pictDir2htmlrc";
my $THUMBNAIL="t";

# How big are the thumbnails?
# This is the default, in case the config file
# doesn't exist or do not have this item in it
my $PERCENT="20%";
# How many TDs per table?
my $tds=4;
# Not implemented yet:
# How many TRs before going to the next page?
# my $trs=4;

###Nothing below this line should need to be configured.###
my $line = "";
my $thisFile= "";
my $x=0;
my $y=0;
my $i=0;
my $total_picts=0;
my @ls = ();
my @ts = ();
my %myconfig = ();
my $THUMBNAILSDIR="$IMAGE_DIRECTORY/$THUMBNAIL";

warn << "__EOF__";
Perl PictDir2HTML v$VERSION (Luis Mondesi <lemsx1\@hotmail.com> / LatinoMixed.com) (running with Perl $] on $Config{'archname'}) \n \n
__EOF__

# test for .nopictDir2htmlrc file
open(NOCONFIG,"$IMAGE_DIRECTORY/.nopictDir2htmlrc") && die ".nopictDir2htmlrc file exists here ($IMAGE_DIRECTORY). Exiting...";
close(NOCONFIG);

#do we already have a dir with this name? no, then create one
opendir(TESTDIR,"$THUMBNAILSDIR") || mkdir($THUMBNAILSDIR,0755);
#close it now (regardless
closedir(TESTDIR);

opendir (DIR,"$IMAGE_DIRECTORY") || die "Couldn't open dir $IMAGE_DIRECTORY";
#construct array of all image files
while (defined($thisFile = readdir(DIR))) {
    next if (-d "$IMAGE_DIRECTORY/$thisFile");
    next if ($thisFile !~ /\w/);
    next if ($thisFile !~ m/\.(jpg|png|jpeg|gif)/i);
    $ls[$x] = $thisFile;
    $x+=1;
}
closedir(DIR);

$total_picts = $x;

open(FILE, "> $IMAGE_DIRECTORY/$FILE_NAME") || die "Couldn't write file $FILE_NAME to $IMAGE_DIRECTORY";
if (open(CONFIG, "<$IMAGE_DIRECTORY/$CONFIG_FILE")){
    while (<CONFIG>) {
	next if /^\s*#/;
        chomp;
        $myconfig{$1} = $2 if /^\s*([^=]+)=(.+)\;\;+/;
    }
    close(CONFIG);

} else {
    warn << "__EOF__";
   Could not find $IMAGE_DIRECTORY/$CONFIG_FILE 
__EOF__

    $myconfig{percent}="20%";
    $myconfig{title}="Images";
    $myconfig{meta}="<meta http-equiv='content-type' content='text/html;charset=iso-8859-1'>";
    $myconfig{stylesheet}="<link rel='stylesheet' href='../styles.css' type='text/css'>";
    $myconfig{html_msg}="<h1>Free form HTML</h1>";
    $myconfig{body}="<body bgcolor='#000000' text='#ffffff'>";
    $myconfig{p}="<p>";
    $myconfig{table}="<table border='0'>";
    $myconfig{td}="<td valign='top' align='left'>";
    $myconfig{tr}="<tr>";
    $myconfig{footer}="";

}
#construct a header if it doesn't yet exist:
if ( $myconfig{header} eq "" ) {
    
    print "Blank header. Generating my own ... \n";
    
    $myconfig{header}="<html>
    <head>
	".$myconfig{meta}."
	<title>".$myconfig{title}."</title>
	".$myconfig{stylesheet}."
    </head>".
    $myconfig{body}."
    <center>".
    $myconfig{html_msg}."
    \n
    ";
}

# Percentage for this folder?
$PERCENT = ("$myconfig{percent}") ? $myconfig{percent}:$PERCENT;

#print contents of array @ls

# start HTML
print FILE ("$myconfig{header}");

# start table
print FILE ("$myconfig{table}");

my $my_bgcolor = "";

#print all picts now
while($x > 0){
    if ( $myconfig{tr} =~ m/\%+bgcolor\%+/i ) {
        #print STDERR "yess, it did: $x \n ";
        # make sure modulus is calculated right
        #if ( ($x % 2) == 0 ){
            #print STDERR "modulus used";
            #($myconfig{tr} = $myconfig{tr}) =~ s/\%+bgcolor\%+/bgcolor=#cccccc/i;
            #} else {
            #print STDERR "No modulus";
             ($myconfig{tr} = $myconfig{tr}) =~ s/\%+bgcolor\%+//i;
             #}
    }
    print FILE ($myconfig{tr}."\n");
    for ($y=1;$y<=$tds;$y++){
        #if (open (Test,"$THUMBNAILSDIR/t"."$ls[$i]")){
        if ( -f "$THUMBNAILSDIR/t"."$ls[$i]" ){
	    # file exists, no need to create
	    # if not then create thumbnail below
	}else{
	if ( -f "$IMAGE_DIRECTORY/$ls[$i]" ){
            if (!-x "/usr/bin/convert") {
                die ("could not find 'convert'");
            }
	    print ("\nConverting file $IMAGE_DIRECTORY/$ls[$i] into $THUMBNAILSDIR/t$ls[$i] \n");
	    system("convert -geometry $PERCENT $IMAGE_DIRECTORY/$ls[$i] $THUMBNAILSDIR/t"."$ls[$i]");
	   print ("\n"); 
	    } # end if -f IMAGE_DIRECTORY/ls[i]
	} # end if/else open Test
	print FILE ("\t".$myconfig{td}."\n");
	if (open Test,"$THUMBNAILSDIR/t"."$ls[$i]"){
	    # if file exists, create a link, otherwise leave it blank
	    print FILE ("<a href='$ls[$i]'><img src='$THUMBNAIL/t"."$ls[$i]'></a>\n");
	} else {
	    print FILE ("&nbsp;");
	}
	print FILE ("\t</td>\n");
	$i++;
	$x--;
    }#end for $y
    print FILE ("</tr>\n");
}
print FILE ("</table>\n");

# close the footer if one doesn't exist:
if ( $myconfig{footer} eq "" ) {
    print FILE ($myconfig{footer}."\n");
    print FILE ("</center></body>\n");
    print FILE ("</HTML>");
} else {

    print FILE ($myconfig{footer});
}
close(FILE);
print STDERR "Done. I count $total_picts pictures here $IMAGE_DIRECTORY.\n";

#sub tumb {
    # creates an HTML page for a thumbnail
    # this will be implemented later

    #}
