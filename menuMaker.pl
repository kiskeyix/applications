#!/usr/bin/perl -w
# do not show so many warnings: -w ;    ;-)
# Last modified: 2002-Aug-29
# Luis Mondesi  <lemsx1@hotmail.com> 2002-01-17
# Use this script in Nautilus to create menu HTML files
# This is part of pictDir2html.pl script, but it can be used
# by itself.
# 
# How does it work?
# Run it from the given folder where the menu.html
# file will be located, and relative to this file
# links will be constructed for e/a folder
# inside this given folder that has a file named: index.html or index.php
# 
# if there is a file named .new inside the given directory,
# then a IMG tag will be put in front of the link with a gif
# file $GIF
# 
# Make this file executable and put it in:
# ~/.gnome/nautilus-scripts
# 
# Then run it from from the File::Scripts::script_name menu
# 

use strict;
use vars qw( $VERSION @INC );
use Config;
my $VERSION="0.4";

my $HTML_DIRECTORY=".";

my $FILE_NAME="menu.html";
my $INDEX_HTML="index.php";

my $CONFIG_FILE=".pictDir2htmlrc";
# this is used for the 'new' gif
my $GIF = "http://www.latinomixed.com/sex/images/new.gif";

# URI is used for creating the link. Everything
# is relative to this. Will put this in the .pictDir2htmlrc file
my $URI = "http://sex.latinomixed.com";

my $IMG = ""; #init variable
# Extra information prior to <HTML> of menu page
my $EXTRAS="";

#"<?php  ".
#    "DEFINE ('COUNTER', './counter/counter_add.php');  ".
#    "if (file_exists(COUNTER)) {  ".
#    "    include_once(COUNTER);  ".
#    "    echo '<!-- sex rocks! -->';  ".
#    "}  ".
#    "?>";

# How many TDs per table?
my $tds=10;
# Not implemented yet:
# How many TRs before going to the next page?
# my $trs=4;

###Nothing below this line should need to be configured.###
my $line = "";
my $thisFile= "";
my $x=0;
my $y=0;
my $i=0;
my $total_links=0;
my @ls = ();
my $ts = "";
my @files=();
my %myconfig = ();

warn << "__EOF__";
Perl menuMaker v$VERSION (Luis Mondesi <lemsx1\@hotmail.com> / LatinoMixed.com) (running with Perl $] on $Config{'archname'}) \n \n
__EOF__


opendir (DIR,"$HTML_DIRECTORY") || die "Couldn't open dir $HTML_DIRECTORY";
#construct array of all HTML files
while (defined($thisFile = readdir(DIR))) {
    next if ($thisFile !~ /\w/);
    next if (!-f "$HTML_DIRECTORY/$thisFile/$INDEX_HTML");
	$ls[$x] = "$thisFile/$INDEX_HTML"; # link
	$x+=1;
    #@files = grep(/\.html$/,$thisFile);    
}
closedir(DIR);

# sort menus alphabetically (dictionary order):
# print STDERR join(' ', @ls), "\n";
# sort @ls;
my $da;
my $db;
@ls = sort { 
            ($da = lc $a) =~ s/[\W_]+//g;
            ($db = lc $b) =~ s/[\W_]+//g;
            $da cmp $db;
            } @ls;
# print STDERR join(' ', @ls), "\n";

$total_links = $x;

open(FILE, "> $HTML_DIRECTORY/$FILE_NAME") || die "Couldn't write file $FILE_NAME to $HTML_DIRECTORY";
if (open(CONFIG, "<$HTML_DIRECTORY/$CONFIG_FILE")){
    while (<CONFIG>) {
	next if /^\s*#/;
        chomp;
        $myconfig{$1} = $2 if /^\s*([^=]+)=(.+)\;\;+/;
    }
    close(CONFIG);

} else {
    warn << "__EOF__";
   Could not find $HTML_DIRECTORY/$CONFIG_FILE 
__EOF__

    $URI=$myconfig{uri}; # uri's should not end in trailing slahes (/)    
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
#construct a header
#not needed .... fixme fixme
#$myconfig{header}=$EXTRAS."
#"."<html>
#    <head>
#	".$myconfig{meta}."
#	<title>".$myconfig{title}."</title>
#	".$myconfig{stylesheet}."
#    </head>".
#    $myconfig{body}."
#    <center>
#    ";
#print contents of array @ls
#print FILE ("$myconfig{header}");
print FILE ("$myconfig{table}");

#print all links now
#foreach file (@files){
while($x>0){
    if ($myconfig{tr}=~m/\%+bgcolor\%+/i){
        if (($x % 2) == 0){
            ($myconfig{tr} = $myconfig{tr}) =~ s/\%+bgcolor\%+/bgcolor=#cccccc/i;
        }else {
            ($myconfig{tr} = $myconfig{tr}) =~ s/\%+bgcolor\%+//i;
        }
    }

    print FILE ($myconfig{tr}."\n");
    for ($y=1;$y<=$tds;$y++){
        
        if ($y > 1) { print FILE ("\t </td> \n"); }   # close the TD tags

	print FILE ("\t".$myconfig{td}."\n");
	if ( $ls[$i] ne "" ) {
            #=~ m/\w/i){
	    # if link exists, otherwise leave it blank
            ($ts = $ls[$i]) =~ s/(.*)\/$INDEX_HTML/$1/gi;
            $IMG = (-f "$ts/.new") ? "<img valign='middle' border=0 src='$GIF'>":""; # if .new file
            $ts = ucfirst($ts);
            
	    print FILE ("<a href='$URI/$ls[$i]' target='_top'>$IMG $ts</a>\n");
	} else {
	    print FILE ("&nbsp;");
	}
	$i++;
	$x--;
    }#end for $y
    print FILE ("</tr>\n");
}
print FILE ("</table>\n");
#print FILE ($myconfig{footer}."\n");
#print FILE ("</center></body>\n");
#print FILE ("</HTML>");
close(FILE);
print STDERR "Done with menus. I count $total_links files.\n";

