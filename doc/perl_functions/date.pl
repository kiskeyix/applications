#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Jul-27
# 
# A quick and dirty way to print a date:
#
use strict;
$|++;

my ($sec,$min,$hour,$mday,$mon,$year) = localtime; 
my $ADATE=($year+=1900)."-$mon-$mday $hour:$min:$sec"; 
print $ADATE;
