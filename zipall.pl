#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Aug-13
#
use strict;
$|++;

my $i;
my $i_noext;

foreach $i (`ls *`) {

    chomp $i;

    ( $i_noext = $i ) =~ s/\.[a-zA-Z]{1,3}//gi;

    print ("$i_noext.zip <-- $i \n");
    system ("zip $i_noext $i");

}

