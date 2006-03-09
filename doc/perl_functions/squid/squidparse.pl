#!/usr/bin/perl

use strict;

use DBI;
use Time::ParseDate;

my $t0 = time;
my (%conf, $dbh);
my $proxyname = `hostname`;
my $pid = "/tmp/squidparse.pid";

opendir(PROC, "/proc") || die "Cannot open the proc dir for reading !$\n";
my @proc_pids = grep { /\d/ } readdir(PROC);

# check for already running script and exit if found
if (open(PID,"$pid")) {
    my $last_pid=<PID>;
    if (grep(/^$last_pid$/, @proc_pids)) { print "exitting "; exit 0; } ;
    close PID;
}

open(PID,">$pid"); print PID $$; close PID;# write new pid file

open (CONF, "< /usr/local/squidalyser/squidalyser.conf") or die $!;
while (my $line = <CONF>) {
	chomp($line);
	$line =~ /^\#/ and next;
	$line =~ /^$/ and next;
	my ($varname, $varvalue) = split(/\s+/, $line);
	$conf{$varname} = $varvalue;
}
close CONF;

my $now = localtime();
print qq|
Running $0 at $now

DB Name:	$conf{dbname}
DB Host:	$conf{dbhost}
DB User:	$conf{dbuser}
Squidlog:	$conf{squidlog}
Proxy Name:     $proxyname
|;

dbconnect($conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpass});

my $query = "SELECT MAX(time) FROM logfile where proxyname = '$proxyname'"; 
my $sth = $dbh->prepare($query);
$sth->execute;
my $lastrun = $sth->fetchrow;
$sth->finish;

$query = qq|
	INSERT INTO logfile (proxyname,remotehost,rfc931,authuser,request,status,bytes,time)
	VALUES ( ? , ? , ? , ? , ? , ?, ? , ? )
|;
$sth = $dbh->prepare($query);

my $count;
open (LOG, "< $conf{squidlog}") or die $!;
while (my $line = <LOG>) {
	my $seconds;
	if ($line =~ /\s+\[(\d{2,2}.*?)\]\s+/) {
		$seconds = parsedate($1);
	} else {
		$line =~ /^(\d{10,10})\.\d{3,3}/;
		$seconds = $1;
	}
	if ($seconds >= $lastrun) {
		my ($remhost, $rfc931, $date, $request, $status, $bytes) = parseline($line);
		#print "insertinlog($proxyname, $remhost, $rfc931, $date, $request, $status, $bytes, $line)\n";
		insertinlog($proxyname, $remhost, $rfc931, $date, $request, $status, $bytes, $line);
		$lastrun = $seconds;
		$count++;
	}
}

&expire_db;

&dbdisconnect;
my $t1 = time;
my $elapsed = $t1 - $t0;
print qq|Took $elapsed seconds to process $count records.\n|;

exit 0;

sub insertinlog {
	my ($proxyname, $remhost, $rfc931, $date, $request, $status, $bytes, $line) = @_;
	$bytes = 0 unless ($bytes =~ /\d+/);
	$status = 0 unless ($status =~ /\d+/);
	my $req_domain = "";

	#lets chop the $request
	#split request on /, to display just the domain.
	my @tarr_request = split(/\//, $request);
	#sometimes they dont seem to type http:// but hopefully there is never a second request without the http://
	#requests that have a file stucture should always have an http:// eg. http://www.www.com/hi/there/index.html
	if ( ($tarr_request[0] eq "http:") || ($tarr_request[0] eq "ftp:") ) {
	    $req_domain = $tarr_request[2];
	} else {
	    $req_domain = $tarr_request[0];
	}
	
	$request = $req_domain;
	
	#print "execute($proxyname,$remhost,$rfc931,'-',$request,$status,$bytes,$date)\n";
	$sth->execute($proxyname,$remhost,$rfc931,'-',$request,$status,$bytes,$date) or do {
		print $line;
		print $query;
		die $!;
	};
	$sth->finish;
	return;
}

sub parseline {
	my $line = shift or return;
	my @f = split(/\s+/, $line);
	if ($line =~ /^(\d{10,}\.\d{3,3})/) {
		# squid logfile format
		my $sec = $1;
		my $sta = $1 if ($line =~ /TCP.*?\/(\d{3,3})/);

		# If we're using NTLM authentication, we have username in DOMAIN\User format,
		# so split domain and user (authuser) at \ and store username back in $f[7].
		# Patch submitted by Neil M. and hacked a bit by me :) I don't use NTLM so if
		# you spot an error with this one let me know.
		if ($f[7] =~ /\\/) {
			my ($domain, $user) = split(/\\/,$f[7]);
			$f[7] = $user;
		}

		return ($f[2], $f[7], $sec, $f[6], $sta, $f[4]);

	} else {
		# http logfile format
		my $date = "$f[3] $f[4]";
		$date =~ s/\[|\]//g;
		my $sec = parsedate($date);
		$f[6] =~ s/"//g;
		print $f[0];
		print $f[1];
		
		return ($f[0], $f[1], $sec, $f[6], $f[8], $f[9]);
	}
}

sub expire_db {
	my ($exp_val, $exp_unit) = split(/\_/, $conf{expire});
	unless ($exp_val > 0) {
		print qq|Error in config file: `expire $conf{expire}'.\nNo records expired from database.|;
		return;
	}
	if ($exp_unit eq 'h') {
		$conf{factor} = 3600;
	} elsif ($exp_unit eq 'd') {
		$conf{factor} = 86400
	} elsif ($exp_unit eq 'w') {
		$conf{factor} = 604800;
	}
	my $nowsec = parsedate($now);
	my $expire_before = $nowsec - ($conf{factor} * $exp_val);
	my $query = qq|DELETE FROM logfile WHERE time < $expire_before|;
	my $sth = $dbh->prepare($query);
	$sth->execute or do {
		print $query;
		die $!;
	};
	my $rows = $sth->rows;
	print qq|\nExpired $rows records from the database.\n|;
}

sub dbconnect {
	my ($dbhost, $dbname, $dbuser, $dbpass) = @_;
        #   $connectionInfo="DBI:mysql:database=$db;$host:$port";
	$dbh = DBI->connect("DBI:mysql:database=$dbname;$dbhost:3306",$dbuser,$dbpass) or die (DBI::errstr);

}

sub dbdisconnect {
	$sth and $sth->finish;
	($dbh and $dbh->disconnect) or die (DBI::errstr);
}
