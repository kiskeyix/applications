#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Oct-06
# 
# A quick and dirty way to print a date:
#
use strict;
$|++;

if ( $ARGV[0] ) {
    # arg is in the form: 09/01/2002 11:01:59
    # convert this to MySQL timestamp(14) format
    # YYMMDDHHmmSS
    my $str ="";
    ($str=$ARGV[0]) =~ s/^(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+).*/$3$1$2$4$5$6/;
    print "$str \n";
} else {

    my ($sec,$min,$hour,$mday,$mon,$year) = localtime; 
    $mon += 1; ## adjust Month: no 0..11 instead use natural 1..12
    $year+=1900;

    my $ADATE=sprintf("%04d",$year)."-".sprintf("%02d",$mon)."-".sprintf("%02d",$mday)." ".sprintf("%02d",$hour).":".sprintf("%02d",$min).":".sprintf("%02d",$sec); 
    print $ADATE,"\n";
}
