#!/usr/bin/perl -w
# Last modified: 2002-Mar-26
# Luis Mondesi < lemsx1@hotmail.com >
# backup latinomixed.com every night
#
use strict;
my $thisFile='';
my $x=0;
my @ls=();
my $myPATH="$ENV{HOME}/bak";
opendir( DIR,"$myPATH" ) || die("could not open dir $myPATH");
while (defined($thisFile = readdir(DIR))) {
    next if (-d "$thisFile");
    next if ($thisFile !~ /\w/);
    next if ($thisFile !~ m/\.(bz|bz2|gz|tar)/i);
    $ls[$x] = $thisFile;
    #print($ls[$x]."\n");
    $x+=1;
}
close(DIR);
#system("tar -cjvf ~/bak/latinomixed-`date -I`.tar.bz2 /usr/var/www/html/latinomixed.com /var/lib/mysql/latinomixeddb /var/lib/mysql/phpgroupwaredb /var/lib/mysql/webstats");
