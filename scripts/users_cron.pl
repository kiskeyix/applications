#!/usr/bin/perl -w
# $Id: users_cron.pl,v 1.1 2002-09-25 14:12:28 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Sep-25
#
use strict;
use DBI;
$|++;

my $DBI_str = "DBI:mysql:mri_flows:localhost:3306,flows,flowspython";
my $DB_USER="flows";            # username to connect to db
my $DB_PASSWD="flowspython";    # password for db
my $name = "%@%";               # like statement for mysql... we want E-Mail's

my @row = "";                   # array to display rows we fecth

my ($sec,$min,$hour,$mday,$mon,$year) = localtime; 
my $ADATE=($year+=1900).$mon.$mday;  # date of interest

# connect
my $dbh = DBI->connect($DBI_str, $DB_USER, $DB_PASSWD,
                            { RaiseError => 1, AutoCommit => 0 });
# get set
my $sth = $dbh->prepare("SELECT *,DATE_FORMAT(registerdate, \'%Y-%m-%d %T\') as ndate FROM users \
WHERE name LIKE '$name' AND UNIX_TIMESTAMP(registerdate) BETWEEN UNIX_TIMESTAMP(NOW())-86400 AND UNIX_TIMESTAMP(NOW())");
$sth->execute( );
my ($email,$password,$role,$fname,$lname,$title,$telephone,$fax,$address,$company,$ip,$agent,$registerdate,$nvisits,$ndate);

# go
while ( ($email,$password,$role,$fname,$lname,$title,$telephone,$fax,$address,$company,$ip,$agent,$registerdate,$nvisits,$ndate) = $sth->fetchrow_array ) {

    print STDOUT "NAME: $fname $lname \n TITLE: $title \n COMPANY: $company \n ADDRESS: $address \n T: $telephone \t F: $fax \n $email \n REGISTER DATE: $ndate \n \n ";
}  

# bye
$dbh->disconnect;
