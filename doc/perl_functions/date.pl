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
    my $ADATE=($year+=1900)."-$mon-$mday $hour:$min:$sec"; 
    print $ADATE;
}
