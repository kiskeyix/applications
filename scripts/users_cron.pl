#!/usr/bin/perl -w
# $Id: users_cron.pl,v 1.2 2002-09-25 16:10:18 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Sep-25
#
# DESCRIPTION:
#   cron script for pulling users registered to MRI website in a 24 hour
#   period. this will be tabulated and email to EMAIL_to users
#
use strict;
use DBI;
$|++;

my $EMAIL_to = "ekenberg\@mri-nyc.com,mondesi\@mri-nyc.com";    # leave blank if not email needed

my $DBI_str = "DBI:mysql:mri_flows:localhost:3306,flows,flowspython";
my $DB_USER="flows";            # username to connect to db
my $DB_PASSWD="flowspython";    # password for db
my $name = "%@%";               # like statement for mysql... we want E-Mail's

my $rows = "";                  # to display the rows we fecth

#my ($sec,$min,$hour,$mday,$mon,$year) = localtime; 
#my $ADATE=($year+=1900)."-".$mon."-".$mday;  # date of interest
my $ADATE = localtime;

# connect
my $dbh = DBI->connect($DBI_str, $DB_USER, $DB_PASSWD,
                            { RaiseError => 1, AutoCommit => 0 });
# get set
my $sth = $dbh->prepare("SELECT *,DATE_FORMAT(registerdate, \'%Y-%m-%d %T\') as ndate FROM users \
WHERE name LIKE '$name' AND UNIX_TIMESTAMP(registerdate) BETWEEN UNIX_TIMESTAMP(NOW())-86400 AND UNIX_TIMESTAMP(NOW())");

# execute the query
$sth->execute( );

# supporting variables
my ($email,$password,$role,$fname,$lname,$title,$telephone,$fax,$address,$company,$ip,$agent,$registerdate,$nvisits,$ndate);

# parse the result from the query
while ( 
    (
        $email,
        $password,
        $role,
        $fname,
        $lname,
        $title,
        $telephone,
        $fax,
        $address,
        $company,
        $ip,
        $agent,
        $registerdate,
        $nvisits,
        $ndate
    ) = $sth->fetchrow_array ) {
    # add the result to the $rows string
    #
    $rows .= "NAME: $fname $lname \n TITLE: $title \n COMPANY: $company \n ADDRESS: $address \n T: $telephone \t F: $fax \n $email \n REGISTER DATE: $ndate \n \n ";
}  

# if we have email addresses in EMAIL_to, send emails, otherwise 
# just print to STDOUT
#
if ( $EMAIL_to gt '' && $rows gt '' ) {
open(SENDMAIL, "|/usr/lib/sendmail -oi -t")
           or die "Can't fork for sendmail: $!\n";
print SENDMAIL <<"EOF";
From: MRI_FLOWS <root\@www.mri-nyc.com> 
To: $EMAIL_to
Subject: MRI FLOWS new user(s) $ADATE
        
New Users subscribed today: $ADATE

$rows 

EOF
close(SENDMAIL) or warn "sendmail didn't close nicely";  
} else {

    print STDOUT $rows;
}

# bye
# Disconect from database
$dbh->disconnect;

#eof
