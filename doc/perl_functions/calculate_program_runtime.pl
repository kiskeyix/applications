#!/usr/bin/perl -w
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Jul-26
#
# DESCRIPTION:
# USAGE:
# CHANGELOG:
#
use strict;
$|++;

sub format_date {
    if ( exists ($_[1]) && $_[1] eq "hours" ) {
        # we care about hours
        return sprintf("%.2f",$_[0] / ( 60 * 60 )); # 3600 number of seconds in an hour
    }

    # take a UNIX timestamp and returns a nicely formatted string
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(shift);
    my $ADATE=sprintf("%04d-%02d-%02d %02d:%02d:%02d",($year+=1900),$mon,$mday,$hour,$min,$sec);
    return $ADATE;
}

# get unixtimestamp (number of seconds since 1970-01-01)
my $start_time = time;
my $f_start_time = format_date($start_time);
print "Start Time: $f_start_time \n";

# do some number crunching cpu-intensive calc here

# substract unixtimestamp from our original timestamp
my $end_time = time - $start_time;
my $f_end_time = format_date($end_time,"hours");
print "Number of Hours: $f_end_time \n";

