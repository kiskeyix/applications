#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Sep-20
# $Id: etodo.pl,v 1.3 2002-09-20 17:17:58 luigi Exp $
#
# DESC:
#   This script takes your tasks.ics file from Evolution
#   and parses some fields and present that in a nicely format
#   HTML file
#
# USAGE:
#   Run this from a cronjob every X number of hours/minutes
#   or whatever pleases you :-)
#   This could've been written as a CGI, but, just to make it
#   globally available to all users without compromising security
#   it's done as a per-user basis...
#
#   ex:
#       etodo.pl -u "Name of User"
#       etodo.pl -hc -t -u "Name of User" -d SECONDS
#   
# BUGS:
#   * tasks cannot have the Time set because the file is splitted in 
#     more than one lines and it's harder to match with a regex. will
#     find work-around later...
#   * doesn't run in CGI mode. This would imply passing the user 
#     or something that identifies the user in the URL and that's
#     consider a security problem... a way to do it would be to have
#     a symlink to the task.ics file somewhere and pass the file as an
#     argument, or have numbers mapped to usernames somehow and pass 
#     those numbers instead... there are a million ways to accomplished
#     this... for now it's just better to have e/a user run their own
#     etodo.pl script.
# TODO:
#   * add switch to hide completed tasks ( -hc or --hide-completed )
#   * add the date and a optional switch to put the date in the title
#     of the HTML file ( -t or --time )
#   * add switch to run in daemon mode for with number of second sleep
#     ( -d SECONDS or --daemon=SECONDS ). Daemon mode should detach 
#     from the terminal and become a background process. Thus there
#     would be no need to run it from a cron job
#   * add a switch for displaying the help ( --help or -h )
#
# CHANGELOG:
#   - initial relase
#  
use strict;
$|++;

# Modules to load
# 
# uses CGI module for all our HTML needs...
use CGI qw(:standard);

# Configuration:
# Variables
# 
my $debugging = 0;

my $vtask = $ENV{'HOME'}."/evolution/local/Tasks/tasks.ics";
# output to this HTML file
my $ohtml = "/var/www/html/tasks.html";

# End configuration... no need to edit below this comment
#************************************************************
my $HIDE_COMPLETED = 0;
my $SHOW_TIME = 0;
my $user_name = "none";
my $SECONDS_TO_RUN = 0;

while ( $_ = ( $ARGV[0] ) ? $ARGV[0] : "" , /^-/) {
    shift;
    last if /^--$/;
#   * add switch to hide completed tasks ( -hc or --hide-completed )
#   * add the date and a optional switch to put the date in the title
#     of the HTML file ( -t or --time )
#   * add switch to run in daemon mode for with number of second sleep
#     ( -d SECONDS or --daemon=SECONDS ). Daemon mode should detach 
#     from the terminal and become a background process. Thus there
#     would be no need to run it from a cron job
#   * add a switch for displaying the help ( --help or -h )
#
    if (/^-+hc/) { $HIDE_COMPLETED = 1; } 
    elsif (/^-+t/) { $SHOW_TIME = 1;}
    elsif (/^-+user\s*=\s*(\w+)|^-+u\s*(\w+)/){ $user_name=$1;}
    elsif (/^-+d[aemon]*(=| )([0-9]+)/) { $SECONDS_TO_RUN=$2;}
    elsif (/^-+h|^-+help/) { 
        print "USAGE: etodo.pl [options] \n 
        \t -u \"USER\",--user=\"user\" \t use this name for the title 
        \n \t -u,-update \t updates config 
        \n \t -d,-daemon \t non interactive (no /dev/tty)
        \n \t -example \t creates an example config file that can be edited by hand (for the impatient \n\n";
    exit(0); 
    }
}

#my $user_name = ( $ARGV[1] ) ? $ARGV[1] : "none";
my @ary;

my $i = 0; # counter
my $k = 0; # counter
my $records = 0;

# get_fields() gets relevant fields from .ics file:
#           PERCENT-COMPLETE 
#           DTSTAMP 
#           PRIORITY 
#           SUMMARY 
#
#           ...
#

sub get_fields(){
    open (VFILE,$vtask) || die ("Could not open $vtask");

    while (<VFILE>) {

        if ( $_ =~ m/^BEGIN:VTODO/) {
            #skip all values until starting of VTODO
            #analyze the tasks.ics to see why...
            $i++;
        }
        # we need to find the beginning first.... 
        next if ( $i < 1 );
        # we are sure we don't want this line...
        next if ( $_ =~ m/^END:VTODO/ );
        if ( $i > 0 ) {
            if ($_ =~ m/^DUE;/ ){
                # there are two types of Due dates
                # without time
                $_ =~ s/^DUE;.*VALUE=DATE:([0-9]{1,8}).*/$1/;
                # with time
                # this doesn't work because there is a new line character
                # and we need the next line. Only solution
                # is to remove the due time until a better solution
                # is achieved
                #$_ =~ s/^DUE;.*:.*[\s]*([0-9]*)T.*/$i/;
                # time is in the form YYYYMMDD
                $_ =~ s/(\d{1,4})(\d{1,2})(\d{1,2})/$1-$2-$3/;
                $ary[$i]->{dtdue}=$_;
            } 
            if ($_ =~ m/^DTSTART/ ){
                $_ =~ s/^DTSTART;.*VALUE=DATE:([0-9]{1,8}).*/$1/;
                $_ =~ s/(\d{1,4})(\d{1,2})(\d{1,2})/$1-$2-$3/;
                $ary[$i]->{dtstart}=$_;
            }
            if ($_ =~ m/^SUMMARY:/  ) {
                $_ =~ s/^SUMMARY://;
                $ary[$i]->{summary}=$_;
            }
            if ($_ =~ m/^PERCENT-COMPLETE:/  ) {
                $_ =~ s/^PERCENT-COMPLETE://;
                $ary[$i]->{progress}=$_;
            }
            if ($_ =~ m/^PRIORITY:/  ) {
                $_ =~ s/^PRIORITY://;
                $ary[$i]->{priority}=$_;
            }
            #if ($_ =~ m/^COMPLETED:/  && $STARTED == 1){
            #    $_ =~ s/^COMPLETED:(.*)T.*/$1/;
            #    push(@completed, $_);
            #}
            #if ($_ =~ m/^DTSTAMP:/  && $STARTED == 1) {
            #    $_ =~ s/^DTSTAMP://;
            #    push(@dstamp, $_);
            #}
        }
    } # end while
    close VFILE;
    # hold number of records.
    #return $i;
    $records = $i;
}

# print_fileds() prints content for arrays:
# @dtstart;
# @summary;
# @progress;
# @dtstamp;
# @priority;
# @completed;
# @dtdue;


sub print_fields {

    open (OFILE,"> $ohtml") || die ("Could not open output file");

    print OFILE start_html("Evolution Tasks [$user_name]",
        "$user_name","","","","","","","","","html",
        "en_US",
        "iso-8859-1"
    );

    print OFILE "<table width='100%'>\n";

    print OFILE Tr(
        {
            -align=>"CENTER",
            -valign=>"TOP",
            -bgcolor=>"#e5e5e5"},
        td("NUMBER"),
        td("START DATE"),
        td("DUE DATE"),
        td("SUMMARY"),
        td("PROGRESS"),
        td("PRIORITY"
        ));
    
    if ( $debugging == 1 ) { print "**** RECORDS: ".$records."\n" };
    
    for ($i = 1;$i <= $records;$i++) {
            print OFILE "<tr>\n";

            #number
            print OFILE td($i);
            #date start
            print OFILE td($ary[$i]->{dtstart});
            #date due
            print OFILE td($ary[$i]->{dtdue});
            #summary
            print OFILE td($ary[$i]->{summary});
            #progress
            if ( $ary[$i]->{progress} == 100 ) {
                print OFILE td("COMPLETED");
            } else {
                # print 50 hashes...
                my $hash_tmp = "";
                for ($k=0; $k <= ($ary[$i]->{progress}/2) ; $k++) {
                    $hash_tmp .= "#";
                } # end for k
                print OFILE td($hash_tmp);
            }
            #priority
            if ( $ary[$i]->{priority} <= 3 && $ary[$i]->{priority} != 0) {
                print OFILE td("HIGH");
            } elsif ($ary[$i]->{priority} >= 4 && $ary[$i]->{priority}<6) {
                print OFILE td("NORMAL");
            } elsif ($ary[$i]->{priority} >= 6 ) {
                print OFILE td("LOW");
            } else {
                print OFILE td("UNDEF");
            }
            #end table row
            print OFILE "</tr>\n";

    } # end for i

    print OFILE "</table> \n",end_html;

    close OFILE;
}

get_fields();
print_fields();

