#!/usr/bin/perl

#
# Roger Leardi roger@rogernet.com
#

# v0.05

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See 
# the GNU General Public License for more details.

#*****************************************************************************
# Note:  evolution has its own pcs ( personal calendar server ) called wombat. 
# It starts when you fire up evolution but... it dosn't shut down. 
# So you need to kill the wombat before syncing 
# or it will happly overwrite you calendar.ics file with whatever it had before. 
# 
# kill `ps -eaf | grep wombat | awk '{print $2}'`
#
#  ..... you have been warned.
#*****************************************************************************

# BACKUP YOUR FILES BEFORE RUNNING THIS.  THIS IS ALPHA CODE AT BEST. 

# 
#
# to run this script -- make sure the zaurus is connected. 
# make sure you can reach it via the network. make sure the script is executable.
# run it !  If it dosen't work for you drop me a mail and I'll see what I can do.
#  

# This script will ( hopefully ) sync your zaurus datebook with evolution. 

# What it can do ( or can't)

#
# Sync your date book (sort of)...
# All catigories are Business 
# You need to have a datebook.xml file on the zaurus.
# Both datebook on the zaurus and evolution need to be shut down
# while syncing ( you also need to kill wombat ) 
#
# If you hard reset your zaurus ( resetting the datebook ) you need to remove ~/.evsync/evctl.data 
# or the script will think that you removed all of the appointments from the zaurus and erase them 
# from evolution as well. ( This is probibly not what you want ! )
#
 
# The future .....
# fix this script .. 
# add todo list, contact list etc.

# network sync daemon that integrates w/ wombat 
# gui interface for desktop and pda.
# be able to initiate sync from pda or desktop over the network.  

# Changes

# 2002-01-14 repeat rules now work. 
# Bugs fixed.

# 2002-01-17 Alarms now work ! With some limitations.
# The zaurus has a limit of 180 minutes prior to event for alarms.
# If you set an alarm longer that that in evolution it will get set to 180 min.
# on the zaurus.. and if you edit the event on the zaurus the evolution alarm
# will be set to the value of the zaurus alarm.
#
# more Bugs squished !

# 2002-01-25       Michael Kropfberger <michael.kropfberger@gmx.net>
# - parametrization of handheld IP and ical calender file
# - added support for off-day events (eg. used in korganizer for birthdays)
# - up- and download from handheld might also use scp (or as usual ftp)
# - maybe bad idea: removed security check if we should really use this calendar.ics file
#   but on the long run, more convenient....
# - when writing out ical file, dont write needlessly empty lines

# 2002-04-04  Roger Leardi roger@rogernet.com
# New Versions of the Zaurus rom allow for multi - line XML records 
# wich corrupted the data. This has been fixed


use Net::FTP;
use Time::Local;

######### CONFIGURATION ##########
#
#
##########
# how can we reach the handheld?
#
$handheld_ip="192.168.2.211";

##########
# what ical compatible file do you want to sync?
#
$ical_file="$ENV{HOME}/evolution/local/Calendar/calendar.ics";
#$ical_file="$ENV{HOME}/.kde2/share/apps/korganizer/mike.ics";

##########
# make shure to choose the upload protocol between ftp and scp below!
#
#$proto="ftp";
$proto="scp";


####### END OF CONFIGURATION SECTION ##########



$home = join "/", $ENV{HOME}, '.evsync';

if ( &check_file($home) == 1 ) {
	
	mkdir ( $home, 0700 ) or die "Couldn't create $home :$!\n";
} ;	

chdir $home or die "Couldn't change into $home :$!\n";

&load_control();

#choose either ftp or scp
if ($proto =~ "^ftp") {
  &get_zaurus_file_ftp();
} elsif ($proto =~ "^scp") {
  &get_xml_file_scp();
} else {
  die "ERROR: wrong transfer protocol $!\n";
}

&load_zaurus_file();
&load_evolution();
&erase_lists();
&sort_em();
&write_zaurus();
&write_evolution();

#choose either ftp or scp
if ($proto =~ "^ftp") {
  &put_zaurus_file_ftp();
} elsif ($proto =~ "^scp") {
  &put_xml_file_scp();
} else {
  die "ERROR: wrong transfer protocol $!\n";
}



print "\n\nSYNC DONE!\n";




sub load_control {

# This sub loads the control file stored in the .evsync directory
# It stores previous sequence number in a hash keyed by sync id.
# The control file is used to generate the erased lists. 
	
	$evolution_ctl = 'evctl.data';
	
	if ( open(EVOLUTION_CTL, "<$evolution_ctl")) {
		while (defined (my $input = <EVOLUTION_CTL>)) {
			(my $sid, my $data) = split "::", $input;
			$CONTROL{$sid} = $data;
		};
	
	} else {
		warn  "Could not open control file  Ill do my best!\n";
	};
}		


sub get_xml_file_scp {

# This sub secure copies retrives our datebook.xml from the handheld

	## TODO ****  Add in error control 
	
	my $ip = "$handheld_ip";
	my $username = "root";
	my $password = "";
	print "getting file\n";
	system "scp $username\@$ip:/home/root/Applications/datebook/datebook.xml $home";
}

sub get_zaurus_file_ftp {

# This sub ftps to the Zaurus and retrives our datebook.xml	

	## TODO ****  Add in error control 
	
	my $ip = "$handheld_ip";
	my $username = "root";
	my $password = "";
	print "getting file\n";
	$ftp_zaurus = Net::FTP->new("$ip", Debug=>0, Port=>4242 );
	$ftp_zaurus->login("$username","$password");
	$ftp_zaurus->cwd("/home/root/Applications/datebook");
	$ftp_zaurus->get("datebook.xml");
	$ftp_zaurus->quit;
}



sub load_zaurus_file {

# This sub parses the xml file retrived from the zaurus 
# and loads the data into a hash keyed by SYNC ID	
	
	my $input;
	my $theresmore = 0;
	my $frontpeice = "";
	my $UID;
	
	if ( &check_file("./datebook.xml") == 0 ) { # Make sure we have read / write access
		my $datebook = "./datebook.xml";
		open(DATEBOOK_FILE, "< $datebook") or die "Could not open file !:$!";
		my $linecheck = 0;
		my $linebuf = "";
		while (defined($input = <DATEBOOK_FILE>)) {
			chomp $input;

			# This block of code makes sure that the input line is a full XML record if not it keeps reading lines
			# until it can build a full record before passing to the next block.
			
			if ( $input !~ m/.*>$/ ) { # This is not a full line
				if ( $linecheck == 1 ) {
					$linebuf = join " ", $linebuf, $input;
					$linecheck = 1;
					next;
				} else {
					$linebuf = $input;
					$linecheck = 1;
					next;
				}
			} else { 
				if ( $linecheck == 1 ) {
					$input = join " ", $linebuf, $input;
					$linebuf = "";
					$linecheck = 0;
				} else {
					$linebuf = "";
					$linecheck = 0;
				}
			};	
			
			next if ( $input =~ m/^<events>$/);
			if ( "$input" !~ m/^<event.*/i ) {
				push @datebook_header, $input;	# save anything thats not an appointment 
				next;				# for later		
			} else {
				@inputline = split " ", $input; # Split up the lines 
			
				while (defined($peice = ( shift @inputline))) {  # and sort out the peices
					next if ( $peice =~ m/^\\>$/);	
					next if ( $peice =~ m/^<event$/);	
					if ( $theresmore == 1 )	{ 
						my $bigpeice = join " ", $front_peice, $peice;
						$peice = $bigpeice;
					};
					if ( $peice !~ m/.*[^\\]"$/) { 
					 	$front_peice = $peice ;
						$theresmore = 1;
						next;
					} else {
						(my $key, my $data) = split /=/, $peice, 2 ;	
						$data =~ s/"(.*)"/$1/;
						$data =~ s/&quot;/"/g;
						$data =~ s/&amp;/&/g;
						$ZEVENT{$key} = $data;
						$theresmore = 0;
					};
				};
				
				# Now load all of the peices into a hash keyed by SYNC ID		
							
				if ( $ZEVENT{syncid} !~ m/^X-EVOLUTION-SYNC.*/ ) {
					$ZEVENT{syncid} = join ("-", 'X-EVOLUTION-SYNC', ( rand 10000 ), time() );
				}; 
				$UID = $ZEVENT{syncid};
	
				foreach my $key (keys(%ZEVENT)) { 
					$zaurus_vevent{$UID}{$key} = $ZEVENT{$key};
					$ZEVENT{$key} = "";
				};	
			};

		};

	} else {

		print "Error opening up the handhelds datebook.xml file ! Exiting ... \n";
		exit 1;

	};

}		
		



sub put_zaurus_file_ftp {

# This sub puts our newly built xml file back on the zaurus.

	## TODO **** Add in error control.
	
	my $ip = "$handheld_ip";
	my $username = "root";
	my $password = "";

	$ftp_zaurus = Net::FTP->new("$ip", Debug=>0, Port=>4242 );
	$ftp_zaurus->login("$username","$password");
	$ftp_zaurus->cwd("/home/root/Applications/datebook");
	$ftp_zaurus->put("newdatebook.xml", "datebook.xml");
	$ftp_zaurus->quit;
}
	
sub put_xml_file_scp {

# This sub secure copies stores the new datebook.xml to the handheld

	## TODO ****  Add in error control 
	
	my $ip = "$handheld_ip";
	my $username = "root";
	my $password = "";
	print "storing file\n";
	system "scp  $home/newdatebook.xml $username\@$ip:/home/root/Applications/datebook/datebook.xml";
}


sub load_evolution {

# This sub loads in our evolution calendar file.
# It parses the iCal format and loads all data into a 
# hash keyed by SYNC ID.	
	
	my $item =  0;
	my $event = 0;

	my $found = 0;
	my $nextline = "";
	my $buffer = 0;
	my $alarm = 0;


	$evolution_input = &find_ev_file();
	open(EVOLUTION_FILE, "< $evolution_input") or die "Could not open file !:$!";

	while (defined($input = <EVOLUTION_FILE>)) {
		chomp $input;
		if ( $buffer == 0 ) {         	# While checking input you need to check the next line of input 
			$nextline = $input;   	# before processing the current line 
			$buffer = 1;		
			next;
		}

		if ( $input =~ m/^\x20.*$/ ) {    	# This is a continuation of the previous line.
			$input =~ s/\x20(.*)/$1/; 	# Strip off the extra leading white space.
			my $temp = join ("", $nextline, $input);
			$nextline = $temp;
			next; 
		} else {
			$line = $nextline;	# If it's not a continuation of the previous line we need to 
			$nextline = $input;	# save it for our next run through
		};

		# we need to find the start of the vCal file
		if ($found == 0 ) {
	
			if  ($line !~ m/BEGIN:VCALENDAR/i) { 
				push @evolution_header, $line; 	# Save all the header info for later
				next;	
			} else {		
				push @evolution_header, $line;
				$found = 1;
				next;	
			};
		};

		# Now were looking for cal events or todo info 
	
		if ( $event == 0) {
			if ( $line !~ m/BEGIN:VEVENT|BEGIN:VTODO/i) {

				push @evolution_header, $line;
				next;	
				
			} else 	{
				
				$event = 1;
				if ( $line =~ m/BEGIN:VEVENT.*/i) {
					$item = 1; # Set item to 1 for VEVENT
				} else {
					$item = 2; # Set item to 2 for VTODO
				};
				next;

			};
		};

		if ( $item == 1	) { 	# We have a VEVENT

			# Load all the lines of the VEVENT into a hash 
								
			if  ( $line =~ m/END:VEVENT/i) { 	# if this is the end 
				$event = 0;			# of the event process it
				&process_vevent ();
				next;
			} elsif ( $alarm == 1) {		# if were in the middle of an alarm
				$alarm = ( &process_ev_alarm($line)); # keep processing it
				next;
			} elsif ( $line =~ m/BEGIN:VALARM/i ) { # if this is a start of an alarm
				$alarm = 1;       		# start processing it
				next;	
			} else { 
				($key, $data) = split /:/, $line, 2;
				$VEVENT{$key} = $data;		# else keep loading the hash
				next;
			};
			
		} elsif ( $item == 2 ) {	# We have a VTODO
			
			# Load all the lines of the VTODO into a hash 
			
			if  ( $line =~ m/END:VTODO.*/i) {
				$event = 0;
				&process_vtodo ();
				next;
			} elsif ( $alarm == 1) {
				$alarm = (&process_ev_alarm($line));
				next;
			} elsif ( $line =~ m/BEGIN:VALARM/i ) {
				$alarm = 1;
				next;	
			} else { 
				($key, $data) = split /:/, $line, 2;
				$VTODO{$key} = $data;
				next;
			};
		
		};

		next; # We must have missed somthing if it gets here ! 
	};
	close EVOLUTION_FILE;
}


sub process_ev_alarm {    

# This sub wil process the alarms for evoluton.
	
	
	my $line = shift;
	my $key;
	my $data;
	my $time;
	
	if ( $line =~ m/END:VALARM/i ) {
		$data = join( ";-;", $VALARM{'TRIGGER'}, $VALARM{'ACTION'}, $VALARM{'UID'}, $VALARM{'DESCRIPTION'});
		push @{$VEVENT{ALARM}}, $data;
		%VALARM = ();
		return 0;
	} elsif ( $line =~ m/X-EVOLUTION-ALARM-UID.*/) {
		($key, $data) = split /:/, $line, 2;		
		$VALARM{'UID'}  = $data;
		return 1;
	} elsif ( $line =~ m/ACTION.*/ ){
		($key, $data) = split /:/, $line, 2;		
		$VALARM{'ACTION'}  = $data;
		return 1;
	} elsif ( $line =~ m/TRIGGER.*/) {
		($key, $data) = split /:/, $line, 2;		
		$VALARM{'TRIGGER'}  = $data;
		return 1;
	} elsif ( $line =~ m/DESCRIPTION.*/ ){
		($key, $data) = split /:/, $line, 2;		
		$VALARM{'DESC'}  = $data;
		return 1;
	};
	
	return 1;  	# If we get here we don't know what the line is but 
			# its still in the Valarm 
}	
	
sub process_vevent {

# This sub processes our VEVENTS.
# load every Vevent into a hash keyd by SYNC ID 

	my $UID; # Lets get our SYNC ID... or make one up if we don't have one
		
	if ( $VEVENT{'X-SID'} !~ m/^X-EVOLUTION-SYNC.*/ ) {
		$VEVENT{'X-SID'} = join ("-", 'X-EVOLUTION-SYNC', ( rand 10000 ), time()); 
	}; 
	$UID = $VEVENT{'X-SID'};


	foreach my $key (keys(%VEVENT)) { 
		if ( $key eq "ALARM" ) {
			@{$evolution_vevent{$UID}{$key}} = @{$VEVENT{$key}};
			@{$VEVENT{$key}} = (); 
		} else {	
			$evolution_vevent{$UID}{$key} = $VEVENT{$key};
		};
	};	
	%VEVENT = ();
}
	
sub process_vtodo {

# This sub processes our VTODO
# load every Vtodo into a hash keyd by SYNC ID 

	my $UID;
	if ( $VTODO{UID} == "" ) {
		$UID = join ("-", X-EVOLUTION-SYNC, ( rand 10000 ), time() );
	} else {
		$UID = $VTODO{UID};
	};
	
	foreach my $key (keys(%VTODO)) { 
		if ( $key eq "ALARM" ) {
			@{$evolution_vtodo{$UID}{$key}} = @{$VTODO{$key}};
			@{$VTODO{$key}} = (); 
		} else {	
			$evolution_vtodo{$UID}{$key} = $VTODO{$key};
		};
	};	
	%VTODO = ();
}


sub find_ev_file {
		
	# We need to find the evolution calendar.ics file
	# Should be in ~/evolution/local/Calendar/calendar.ics
	
	my $got_file = 0;
	my $evolution_file ="";

	print "Looking for your calendar file\n";

	if ( &check_file("$ical_file") == 0 ) {
		$evolution_file = "$ical_file";
		print "Found: $evolution_file\n";
#		print "Is this the file you want to use ? (y/n) :";
		
#		if (<STDIN> =~ /^y/i) {
		return $evolution_file;
#		};
	};

	until ( $got_file == 1 ){

		print "Couldn't find your calendar.ics file.\n";
		print "Please enter the location of your calendar.ics file. or Q to quit.\n";
		my $input = (<STDIN>);
		chomp $input;

		if ( $input =~ m/q/i ) {
			exit;
		};
		$ret_val = &check_file($input);	
		
		if ( $ret_val == 0) {
			$got_file = 1;
			$evolution_file = $input;
			print "OK using $evolution_file\n";
			return $evolution_file;
		};	
	};
}


sub check_file {
	my $file = pop @_ ;	
	print "Checking: $file\n";
	if ( -e $file ) {
		if ( -T $file  && -w $file && -r $file ) {
			return 0;	
		};
	} else {
		return 1;
	};
}

sub erase_lists { 	# If we saw the sync id last time and now its gone
			# must mean we erased it.  -- unless your on the zaurus 
	my $key;	# if you modify a record there it erases the syncid and sets the uid to 0

	foreach $key (keys(%CONTROL)) {
		$ev_erlist{$key} = 1  unless $evolution_vevent{$key};
		$za_erlist{$key} = 1  unless $zaurus_vevent{$key};
	};
}	


sub sort_em {

	my $key;
	my @idlist;
	my $item;
	my %seen = ();
	my $winner;

	foreach $key (keys(%evolution_vevent)) {		# Generate one long list of all the
		push (@idlist, $key) unless $seen{$key}++;	# Sync ID's from both sources.
	};

	foreach $key (keys(%zaurus_vevent)) {
		push (@idlist, $key) unless $seen{$key}++;
	};
	

	# now process the list 
	
	# If the sync id was in the evolution file use it. 
	# unless its on the erased list.
	# If the sync id is on both ...  use evolution 
	# a) It stores all the same data as the zaurus plus more.
	# b) It may be modified. If the zaurus data is modified it 
	# erases the SYNC ID and looks like you erased one event and 
	# created a new one.
	# The only time you should use the zaurus as the master data is
	# if it has the only copy of a SYNC ID and its not on the erase list.
	
	
	foreach $item (@idlist) {
		if ( $evolution_vevent{$item} ) {  
			&evolution_master($item)  unless ( $za_erlist{$item} );
			
		} else {
			&zaurus_master($item) unless ( $ev_erlist{$item} );
		};
	};
}	

sub evolution_master {

# Load the data from the evolution hash into a master hash that 
# we will use to write both files with later.
	
	my $key;
	my $id = pop @_;
	unless ( $erased_list{$id} ) {
		foreach $key (keys (%{$evolution_vevent{$id}})) {
			if ( $key =~ m/SUMMARY/ ) {
				$master_list{$id}{'DISCRP'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/LOCATION/i ) {
				$master_list{$id}{'LOC'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/DTSTAMP/ ) {
				$master_list{$id}{'TSTAMP'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/X-SID/ ) {
				$master_list{$id}{'SID'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/UID/ ) {
				$master_list{$id}{'UID'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/DESCRIPTION/i ) {
				$master_list{$id}{'NOTE'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/TRANSP/ ) {
				$master_list{$id}{'TRANSP'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/SEQUENCE/ ) {
				$master_list{$id}{'SEQ'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/CLASS/ ) {
				$master_list{$id}{'CLASS'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/CATEGORIES/ ) {
				$master_list{$id}{'CATEGORIES'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/DTSTART/ ) {
				$master_list{$id}{'START'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/DTEND/ ) {
				$master_list{$id}{'END'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/RRULE/ ) {
				$master_list{$id}{'REPEAT'} = $evolution_vevent{$id}{$key};
			} elsif ( $key =~ m/ALARM/ ) {
				@{$master_list{$id}{'ALARM'}} = @{$evolution_vevent{$id}{$key}};
			};	
			
		}; 
	};
}


sub zaurus_master {

	
	my $key;
	my $rtype = "NA";
	my $rpos = "NA";
	my $rfreq = "NA";
	my $enddt = "NA";
	my $rweek = "NA";
	my $id = pop @_;
	unless ( $erased_list{$id} ) {
		foreach $key (keys (%{$zaurus_vevent{$id}})) {
		  	#print "Key is -->$key<-- data is -->$zaurus_vevent{$id}{$key}<--\n";
			if ( $key =~ m/description/ ) {
				$master_list{$id}{'DISCRP'} = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/location/i ) {
				$master_list{$id}{'LOC'} = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/created/ ) {
				$master_list{$id}{'TSTAMP'} = &zaurus_time_to_vcal($zaurus_vevent{$id}{$key});
			} elsif ( $key =~ m/syncid/ ) {
				$master_list{$id}{'SID'} = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/uid/ ) {
				$master_list{$id}{'UID'} = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/note/i ) {
				$master_list{$id}{'NOTE'} = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/categories/ ) {
				$master_list{$id}{'CATEGORIES'} = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/start/ ) {
				$master_list{$id}{'START'} = &zaurus_time_to_vcal($zaurus_vevent{$id}{$key});
			} elsif ( $key =~ m/^end$/ ) {
				$master_list{$id}{'END'} = &zaurus_time_to_vcal($zaurus_vevent{$id}{$key});
			} elsif ( $key =~ m/rtype/ ) {
					$rtype = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/rposition/ ) {
					$rpos = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/rfreq/ ) {
					$rfreq = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/enddt/ ) {
					$enddt = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/rweekdays/ ) {
					$rweek = $zaurus_vevent{$id}{$key};
			} elsif ( $key =~ m/alarm/ ) {
				my $time = $zaurus_vevent{$id}{$key};
				$time =~ s/(.*)/-PT$1M/;
				my $alarm = join( ";-;", $time, "DISPLAY", "ID1234", "DISC");
				push @{$master_list{$id}{'ALARM'}}, $alarm;  
			};	
		};
			
		if ( $rtype !~ m/NA|^$/ ) {
		my @rrule;
		my @wkdays;
		my $weekdays;
		my $thisday;		
		my $nopos = 0;
			if ( $rtype =~ m/Daily/ ) {
				$rtype = "FREQ=DAILY";
			} elsif ( $rtype =~ m/Weekly/ ) {
				$rtype = "FREQ=WEEKLY";
			} elsif ( $rtype =~ m/MonthlyDate/ ) {
				$thisday = ((localtime($zaurus_vevent{$id}{'start'})))[3];
				$thisday = "BYMONTHDAY=" . $thisday;
				$nopos = 1;
				$rtype = "FREQ=MONTHLY";
			} elsif ( $rtype =~ m/MonthlyDay/ ) {
				$thisday = (SU,MO,TU,WE,TH,FR,SA)[((localtime($zaurus_vevent{$id}{'start'})))[6]];
				$thisday = "BYDAY=" . $thisday;
				$rtype = "FREQ=MONTHLY";
			} elsif ( $rtype =~ m/Yearly/ ) {
				$rtype = "FREQ=YEARLY";
			};
			push @rrule, $rtype;
			
			if ( $rfreq !~ m/NA|^$/ ){
				$rfreq = join "=", "INTERVAL", $rfreq;
				push  @rrule, $rfreq;
			};
 
			if ( $rweek !~ m/NA|^$/ ) {
				if ( $rweek >= 64 ) {
					push @wkdays, "SU";
					$rweek -= 64;
				};
				if ( $rweek >= 32 ) {
					push @wkdays, "SA";
					$rweek -= 32;
				};
				if ( $rweek >= 16 ) {
					push @wkdays, "FR";
					$rweek -= 16;
				};
				if ( $rweek >= 8 ) {
					push @wkdays, "TH";
					$rweek -= 8;
				};
				if ( $rweek >= 4 ) {
					push @wkdays, "WE";
					$rweek -= 4;
				};
				if ( $rweek >= 2 ) {
					push @wkdays, "TU";
					$rweek -= 2;
				};
				if ( $rweek >= 1 ) {
					push @wkdays, "MO";
					$rweek -= 1;
				};
				
				my $daylist = join ",", @wkdays;
				$weekdays = join "=", "BYDAY", $daylist;
				push @rrule, $weekdays;
			};
		
			if ( $enddt !~ m/NA|^$/ ) {
			
				$enddt = &zaurus_time_to_vcal($enddt);
				$enddt =~ s/(\d*)T\d*/$1/;
				$enddt = "UNTIL=" . $enddt;
				push @rrule, $enddt;
			};	

			if ( $rpos !~ m/NA|^$/ ){
				$rpos = join "=", "BYSETPOS", $rpos;
				push  @rrule, $rpos unless ( $nopos == 1 );
			};

			push @rrule, $thisday if ($thisday);	
										
			my $list = join ";", @rrule;
				
			$master_list{$id}{'REPEAT'} = $list;

		};
	}; 
}



sub write_zaurus {

	my $key;
	my $line;
	my $alarm = 0;
	
	# First lets open a file to write to.
	# Let's call it newdatebook.xml and lets stick it in the CWD.

	open NEWDATEBOOK, ">newdatebook.xml" or die "Couldent create newdatebook.xml in cwd: $!\n";


	# Next lets put back all the stuff from the top of the file. 
	# But make sure not to put in the final </events> or </DATEBOOK>
	foreach $line ( @datebook_header ) {
		print NEWDATEBOOK "$line\n" unless (( $line =~ m/<\/events>/ )|| ($line =~ m/<\/DATEBOOK>/));
	};
	print NEWDATEBOOK "<events>\n";

	foreach $key (keys (%master_list)) {
		my $rtype;
		my $rpos;
		my $rfreq;
		my $enddate;
		my $rweek;
		my $moweek;
		my $rpt = 0;
		if ($master_list{$key}{'REPEAT'}) {
			my @repeat = &zaurus_rpt( $key ) ;
			$enddate = $repeat[5];
			$rpos = $repeat[4];
			$moweek = $repeat[3];
			$rweek = $repeat[2];
			$rfreq = $repeat[1];
			$rtype = $repeat[0];
			$rpt = 1;
		};

		my $starttime = &vcal_time_to_zaurus($master_list{$key}{'START'}) if ($master_list{$key}{'START'});
		my $endtime = &vcal_time_to_zaurus($master_list{$key}{'END'}) if ($master_list{$key}{'END'});
		my $timestamp = &vcal_time_to_zaurus($master_list{$key}{'TSTAMP'}) if ($master_list{$key}{'TSTAMP'});
		my $alm_trigger;
		my $alm_action;
		my $tmp1;
		my @tmp1;

		@tmp1 = @{$master_list{$key}{'ALARM'}}; # We need to save the data for the 
							# evolution file.
		
		while (defined( $tmp1 = pop  ( @{$master_list{$key}{'ALARM'}} ))) {
			
			($alm_trigger, $alm_action, $crap ) = split /;-;/, $tmp1, 3;
			
			$alm_trigger =~ s/[-A-Z]*(\d*)(.*)/$1-$2/;
			( my $alm_time, my $alm_unit ) = split "-", $alm_trigger;
			if ( $alm_unit eq "H" ) {
				$alm_trigger = $alm_time * 60;
			} elsif ( $alm_unit eq "D" ) {
				$alm_time = 0;
				$alm_trigger = 0;
				$alm_action = "none";
			} else {
				$alm_trigger = $alm_time;
			}
			
			last if ( $alm_action eq "DISPLAY" );
		};	

		@{$master_list{$key}{'ALARM'}} = @tmp1; 
		
		print NEWDATEBOOK "<event ";
		print NEWDATEBOOK "description=\"$master_list{$key}{'DISCRP'}\" ";
		print NEWDATEBOOK "location=\"$master_list{$key}{'LOC'}\" ";
		print NEWDATEBOOK "categories=\"Business\"  ";	#$master_list{$key}{'CATEGORIES'}\"\n";
		print NEWDATEBOOK "uid=\"$master_list{$key}{'UID'}\" ";
		print NEWDATEBOOK "syncid=\"$master_list{$key}{'SID'}\" ";

		if ( $rpt == 1 ) {
			print NEWDATEBOOK "rtype=\"$rtype\" " if ( $rtype !~ m/NA/) ;
			print NEWDATEBOOK "rposition=\"$rpos\" " if ( $rpos !~ m/NA/) ;
			print NEWDATEBOOK "rfreq=\"$rfreq\" " if ( $rfreq !~ m/NA/) ;
			print NEWDATEBOOK "enddt=\"$enddate\" " if ( $enddate !~ m/NA/) ;
			if ( $enddate !~ m/NA/) {
				print NEWDATEBOOK "rhasenddate=\"1\" " ;
			} else {		 
				print NEWDATEBOOK "rhasenddate=\"0\" " ;
			};
			print NEWDATEBOOK "rweekdays=\"$rweek\" " if ( $rweek !~ m/0/) ;
			print NEWDATEBOOK "rpositon=\"$moweek\" " if ( $moweek !~ m/NA/) ;
		};
		
		if ( $alm_action eq "DISPLAY" ) {
			print NEWDATEBOOK "alarm=\"$alm_trigger\"\n";
			print NEWDATEBOOK "sound=\"loud\"\n";
		};
		
		print NEWDATEBOOK "created=\"$timestamp\" ";
		print NEWDATEBOOK "start=\"$starttime\" ";
		print NEWDATEBOOK "end=\"$endtime\" ";
		print NEWDATEBOOK "note=\"$master_list{$key}{'NOTE'}\" ";	
		print NEWDATEBOOK "/>\n";
	};	 
	print NEWDATEBOOK "</events>\n";
	print NEWDATEBOOK "</DATEBOOK>\n";
	
	close NEWDATEBOOK;
}

sub zaurus_rpt {
	my $input = shift;
	my $next;
	my $freq = "NA";
	my $days = "NA";
	my $modays = "NA";
	my $moweek = "NA";
	my $enddate = "NA";
	my $interval = "NA";
	my $bindays = 0;

	my @data;
 
	my @elements = split ";", $master_list{$input}{REPEAT};
	while (defined($next = (shift @elements))) {
		my $data;
		my $key;
		( $key, $data ) = split /=/, $next;
		if ( $key =~ m/FREQ/ ) {
			$freq = $data;
		} elsif  ( $key =~ m/UNTIL/ ) {
			$enddate = $data;
		} elsif  ( $key =~ m/INTERVAL/ ) {
			$interval = $data;
		} elsif  ( $key =~ m/BYDAY/ ) {
			$days = $data;
		} elsif  ( $key =~ m/BYMONTHDAY/ ) {
			$modays = $data;
		} elsif  ( $key =~ m/BYSETPOS/ ) {
			$moweek = $data;
		} else {
			next; 
		};
	};
	
	if ( $enddate !~ m/NA/ )  {
		$enddate .= "T000000";
		$enddate = &vcal_time_to_zaurus($enddate);
	};

	if ( $freq =~ m/DAILY/ ) {
		$freq = "Daily";
	} elsif ( $freq =~ m/WEEKLY/ ) {
		$freq = "Weekly";
	} elsif ( $freq =~ m/MONTHLY/ ) {
		if  ( $moweek !~ m/NA/ ) {
			$freq = "MonthlyDay";
		} else {
			$freq = "MonthlyDate";
		};
	} elsif ( $freq =~ m/YEARLY/ ) {
		$freq = "Yearly";
	};
	
	# The datebook on the zaurus stores repeat days as a single 
	# byte unsigned int. Mon is LSB and Sun is 7th bit
	# Mon = 1, Tuse = 2, Wed = 4, Thurs = 8, Fri = 16, Sat = 32, and Sun = 64
		
	if ( $days !~ "NA" ) {
		my @days = split /,/, $days;
		while (defined(my $tmp = (pop @days))) {
			if ( $tmp =~ m/SU/ ) {
				$bindays += 64;
			} elsif ( $tmp =~ m/MO/) {
				$bindays += 1;
			} elsif ( $tmp =~ m/TU/) {
				$bindays += 2;
			} elsif ( $tmp =~ m/WE/) {
				$bindays += 4;
			} elsif ( $tmp =~ m/TH/) {
				$bindays += 8;
			} elsif ( $tmp =~ m/FR/) {
				$bindays += 16;
			} elsif ( $tmp =~ m/SA/) {
				$bindays += 32;
			};
		};
	};
	push (@data, $freq, $interval, $bindays, $modays, $moweek, $enddate);
	return @data;
						
}
		

sub write_evolution {
	my $alarm=0;
	
	open(EVOLUTION_FILE, ">$evolution_input") or die "Could not open file !:$!";
	open(EVOLUTION_CTL, ">$evolution_ctl") or die "Could not open file !:$!";
		

	# Next lets put back all the stuff from the top of the file. 
	# But make sure not to put in the final </events> or </DATEBOOK>
	
	foreach $line ( @evolution_header ) {
	  if ($line !~ "^~" ) {
		print EVOLUTION_FILE "$line\n";
	      }
	};
	foreach $key (keys (%master_list)) {
		my $seq = 1;
		
		$seq = $master_list{$key}{SEQUENCE} if ( $master_list{$key}{SEQUENCE} ); 

		my $bakline = join "::", $master_list{$key}{SID}, $seq;

		print EVOLUTION_CTL "$bakline\n";
	
		print EVOLUTION_FILE "BEGIN:VEVENT\n";
		print EVOLUTION_FILE "SUMMARY:$master_list{$key}{'DISCRP'}\n"   if ($master_list{$key}{'DISCRP'});
		print EVOLUTION_FILE "LOCATION:$master_list{$key}{'LOC'}\n"  if ($master_list{$key}{'LOC'});
		print EVOLUTION_FILE "CATEGORIES:Business\n";	#$master_list{$key}{'CATEGORIES'}\"\n";
		print EVOLUTION_FILE "UID:$master_list{$key}{'UID'}\n"  if ($master_list{$key}{'UID'});
		print EVOLUTION_FILE "X-SID:$master_list{$key}{'SID'}\n"  if ($master_list{$key}{'SID'});
			#  NEED TO ADD ALARM HERE !!!!!!
		while (defined( my $tmp1 = pop  ( @{$master_list{$key}{'ALARM'}} ))) {
			my $alm_trigger;
			my $alm_action;
			my $alm_uid;
			my $alm_desc;

			($alm_trigger, $alm_action, $alm_uid, $alm_desc ) = split /;-;/, $tmp1, 4;
			
			
			print EVOLUTION_FILE "BEGIN:VALARM\n";
			print EVOLUTION_FILE "TRIGGER;VALUE=DURATION;RELATED=START:$alm_trigger\n";
			print EVOLUTION_FILE "ACTION:$alm_action\n";
			print EVOLUTION_FILE "X-EVOLUTION-ALARM-UID:$alm_uid\n";
			print EVOLUTION_FILE "DESCRIPTION:$alm_desc\n";
			print EVOLUTION_FILE "END:VALARM\n";

		};
		print EVOLUTION_FILE "DTSTAMP:$master_list{$key}{'TSTAMP'}\n"  if ($master_list{$key}{'TSTAMP'});	
		print EVOLUTION_FILE "DTSTART:$master_list{$key}{'START'}\n"  if ($master_list{$key}{'START'});	
		print EVOLUTION_FILE "DTEND:$master_list{$key}{'END'}\n"  if ($master_list{$key}{'END'});	
		print EVOLUTION_FILE "TRANSP:$master_list{$key}{'TRANSP'}\n"  if ($master_list{$key}{'TRANSP'});	
		print EVOLUTION_FILE "SEQUENCE:$master_list{$key}{'SEQ'}\n"  if ($master_list{$key}{'SEQ'});	
		print EVOLUTION_FILE "CLASS:$master_list{$key}{'CLASS'}\n"  if ($master_list{$key}{'CLASS'});	
		print EVOLUTION_FILE "RRULE:$master_list{$key}{'REPEAT'}\n"  if ($master_list{$key}{'REPEAT'});	
		print EVOLUTION_FILE "DESCRIPTION:$master_list{$key}{'NOTE'}\n"  if ($master_list{$key}{'NOTE'});	
		print EVOLUTION_FILE "END:VEVENT\n";
	};	 
	print EVOLUTION_FILE "END:VCALENDAR\n";
	
	close EVOLUTION_FILE;
	close EVOLUTION_CTL;
}

sub vcal_time_to_zaurus {
	my $year;
	my $month;
	my $day;
	my $hour;
	my $min;
	my $sec;
	my $tz = 0;
	
	my $vcaltime = pop @_;
	if ($vcaltime =~ /.*T.*/) {
	$vcaltime =~ s/(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)([a-zA-Z])*/$1:$2:$3:$4:$5:$6/;
	} else {
	  # off-day date without explicit time
	  $vcaltime =~ s/(\d\d\d\d)(\d\d)(\d\d)([a-zA-Z])*/$1:$2:$3:00:00:00/;
	}
	($year, $month, $mday, $hour, $min, $sec) = split /:/, $vcaltime;
	if ( $tz =~ m/z/i ) {
 		$time = timegm($sec,$min,$hour,$mday,$month,$year);
		return $time;
	} else  {
 		$time = timelocal($sec,$min,$hour,$mday,( $month - 1) ,$year);
		return $time;
	};
}

sub zaurus_time_to_vcal {
	
	my $year;
	my $month;
	my $day;
	my $hour;
	my $min;
	my $sec;
	my $wday;
	my $yday;
	my $isdst;	 
	my $zaurus_time = pop @_;
	my $time;
	
	$zaurus_time =~ s/"(\d*)"/$1/;

	($sec,$min,$hour,$day,$month,$year,$wday,$yday,$isdst) = localtime($zaurus_time);

	$sec =~ s/(\d)/0$1/ if ( $sec =~ m/^\d$/);
	$sec =~ "00" if ( $sec =~ m/^$/);
	$min =~ s/(\d)/0$1/ if ( $min =~ m/^\d$/);
	$min =~ "00" if ( $min =~ m/^$/);
	$hour =~ s/(\d)/0$1/ if ( $hour =~ m/^\d$/);
	$hour =~ "00" if ( $hour =~ m/^$/);
	$day =~ s/(\d)/0$1/ if ( $day =~ m/^\d$/);
	$day =~ "00" if ( $day =~ m/^$/);
	$month++;
	$month =~ s/(\d)/0$1/ if ( $month =~ m/^\d$/);
	$month =~ "01" if ( $month =~ m/^$/);

	$time =  join "", ( $year + 1900 ), $month, $day, "T", $hour, $min, $sec;
	return $time;
}

