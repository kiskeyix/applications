#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Oct-03
# 
# $Id: rcopy.pl,v 1.5 2002-10-04 02:54:30 luigi Exp $
# 
# VERSION: 0.9
#
# LICENSE:
# GPL
# http://www.gnu.org/licenses/gpl.html
#
# DESCRIPTION: 
# To put it in short this script uses Perl and
# rsync to synchronize two servers or remote computers. 
# When run for the first time it creates
# a .XML file with all the config needed
# After that, it will use that file for 
# synchronization. 
# 
# USAGE: 
#        rcopy -n           creates a new config file
#        rcopy -u           updates an existing file
#                           Both are interactive commands, follow
#                           onscreen prompts.
#        
#        rcopy -d           TO BE TESTED: run in non-interactive 
#                           (daemon-like)
#                           Means not to attach to the current terminal
#                           (/dev/tty)
#
#        rcopy -example     makes a sample config
#                           that you can edit by hand ...
#                           
#        rcopy -gui         Edit the .rcopy config file with a GUI 
#                           (graphical user interface)
#
# REQUIREMENTS: perl, XML::Simple
# 
# TODO: 
# 1. implement local to remote sync'ing
# 2. modularized code (repeated code should be in subroutines)
# 
#
# BUGS: 
# 1. when updating long .xml config files, the update_config
#    becomes annoying!
# 
# CHANGELOG:
# 2002-09-15 15:08  * fixed a bug when the default config
#                     file didn't exist XMLin wasn't working
#                     in Perl 5.8.x
#
# 2002-07-27 11:09  * finished with update_config, script
#                     is ready for prime time!
#                     also did some necessary cleanups
#                     
# 2002-07-23 17:28  * added ./.rcopy.xml; now if there is a
#                     .rcopy.xml file in the current directory
#                     this file will be used instead of the default
#                     $HOME/.rcopy.xml file
#
# 2002-07-21 17:29  * added a $HOME/.rcopy.lock file. This allows
#                     only one copy of rcopy.pl to run at one
#                     given time

my $DBUG = 0;       # use 1 for true

use strict;         
$|++;               # disable buffering on standard output
      
use XML::Simple;
use Config;

if ( $DBUG == 1 ) { use Data::Dumper; }

# You must customize these variables:
#
# xmlconfig has the default path for .rcopy.xml config file
my $xmlconfig=(-f "./.rcopy.xml") ? "./.rcopy.xml":"$ENV{HOME}/.rcopy.xml";
# Lock file is used to determine whether we should
# run another copy of rcopy.pl or not
my $rcopylock="$ENV{HOME}/.rcopy.lock";

# rsync is the command used for syncing servers
# feel free to change this if you like.
# Default rsync command and arguments:
# -e ssh                uses ssh
# -P                    print progress
# -a                    archive mode
# -u                    update
# -v                    verbose
# --exclude=*.pid       exclude PID files
my $RSYNC = "rsync -e ssh -Pauv --exclude=*.pid "; 

# The XML tag contains extra arguments like:
# < file arg="--delete" local="/local/" remote="/local/test" />
# See the manual for 'rsync' to know more arguments
# and include those when prompted for arguments by this script
# examples:
# --delete --exclude=.* --exclude=*.swp 

# ---------------------------------------------------------------
# NO NEED TO CHANGE ANYTHING BELOW THIS LINE
# UNLESS YOU KNOW WHAT YOU'RE DOING OF COURSE...
# ---------------------------------------------------------------

use strict qw(vars);

# Before doing anything, make sure lock file doesn't exist 
if ( -f $rcopylock ) {
    print ("Lock file exists.\n $rcopylock \n Please remove before continuing");
    exit(1);
}
# Check to see whether a configuration file already exists
# if not, create it and exit
# to give the user time to review the file
# if needed
if ( !-f $xmlconfig ) {

    create_config();
    exit (0);

}

my $config = XMLin($xmlconfig,forcearray=>1);

my $user="";
my $address="";
my $local="";
my $remote="";
my $DAEMON=0; # non-interactive

# hate to see warnings, therefore:
while ( $_ = ( $ARGV[0] ) ? $ARGV[0] : "" , /^-/) {
    shift;
    last if /^--$/;
    if (/^-+n(.*)/) { create_config(); exit(0); }
    elsif (/^-+d(.*)/) { $DAEMON=1; } 
    elsif (/^-+u(.*)/ ) { update_config(); exit(0); }
    elsif (/^-+ex(.*)/) { create_example(); exit(0); }
    elsif (/^-+gui/) { edit_config_gui(); exit(0); }
    elsif (/^-+h(.*)/) { 
        print "USAGE: rcopy [option] \n 
                \t -n,-new \t create new config file 
                \n \t -u,-update \t updates config 
                \n \t -d,-daemon \t non interactive (no /dev/tty)
                \n \t -example \t creates an example config file that can be edited by hand (for the impatient \n\n";
    exit(0); }
}

##
# All code comes down to this few lines!!
##

# Create lock
open (LOCKFILE,"> $rcopylock") or die ("Could not create file $rcopylock \n");

my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
my $ADATE=($year+=1900)."-$mon-$mday $hour:$min:$sec";
print LOCKFILE "Lock File on $rcopylock created on $ADATE \n";

for ( @{$config->{server}} ){
    $user = $_->{ruser}->[0];
    $address = $_->{address}->[0];
    
    for ( @{$_->{file}} ){
        print("Executing: ");
        print("$RSYNC $_->{arg} $user\@$address:$_->{remote} $_->{local}\n");
        system("$RSYNC $_->{arg} $user\@$address:$_->{remote} $_->{local}\n");
    }
}
#print Dumper($config);
print ("\n\n");
# Remove lock
unlink($rcopylock);


########################################
# Definition for functions/subroutines #
########################################

sub create_config {
    
    my %rcopy=();   # originally this was to be used by XMLout()
                    # but the output of XMLout() is too ugly :-)
    my $response="";
    
    open (FILE,"> $xmlconfig") or die ("Could not create file $xmlconfig \n");
    print("Config File on $xmlconfig created \n");
    
    my $i=0;
    my $j=0;
    
    print FILE "<rcopy>\n";
    while ( $response ne 'q' ) {
        
        $rcopy{server}[$i]{address}[0] = prompt($i.". Enter server name or IP: ");
        print FILE "\t<server>\n";
        print FILE "\t\t<address>".$rcopy{server}[$i]{address}[0]."</address>\n";
        
        $rcopy{server}[$i]{ruser}[0] = prompt($i .". Enter remote username: ");
        
        print FILE "\t\t<ruser>".$rcopy{server}[$i]{ruser}[0]."</ruser>\n";
        
        # Now get the arguments for this given server:
        # LOCAL PATH
        # REMOTE PATH
        # ARGUMENTS
        #
        while ( 1 ) {
            $rcopy{server}[$i]{local}[$j] = prompt($i . "." . $j .". Enter local directory for this computer [/path/]: ");

            $rcopy{server}[$i]{remote}[$j] = prompt($i . "." . $j .". Enter remote directory for server ". $rcopy{server}[$i]{address}[0]." [/path/to]: ");
            
            $rcopy{server}[$i]{arg}[$j] = prompt($i . "." . $j .". Enter extra arguments [i.e. --delete [or --rsync_argument]]: ");
            
            print FILE "\t\t<file arg=\"$rcopy{server}[$i]{arg}[$j]\" local=\"$rcopy{server}[$i]{local}[$j]\" remote=\"$rcopy{server}[$i]{remote}[$j]\" />\n";

            $j++;
            
            $response = prompt("Enter a new file/dir [y/N]: ");
            
            # another way to get out of this loop is:
            if ($response ne 'y') { 
                last; 
            }
        } 

        $j=0; # reset $j
        $i++; # increase server counter
        
        print FILE "\t</server>\n";
        
        $response = prompt("Enter q to end: ");
            
        #if ($response eq 'q') { 
            #    last; 
            #}
    } 
    
    print FILE "</rcopy>\n";
    #print FILE $ref;
    close (FILE);

} # ends create_config

# This subroutine updates a configuration file
# it loops thru all servers and it's files/arguments
# at the end, it gives you the choice to add more
# servers.
# 
# Very annoying if you have a long list of servers.
# 
# Future fix:
# This needs to present a list of servers and
# gives users choices to:
# Edit | Delete | Add
#
sub update_config {
    
    if (!-f $xmlconfig) { 
        print STDERR ("No config file found \n"); 
        create_config();
        exit(1); 
    }

    print("Using config file $xmlconfig\n");

    print("Parsing $xmlconfig \n");
    
    # Object with XML file:
    my $config = XMLin($xmlconfig,forcearray=>1);

    my %rcopy=(); # originally this was to be used by XMLout()
                    # but the output of XMLout() is too ugly :-)
    my $response="";
    
    open (FILE,"> $xmlconfig.tmp") or die ("Could not create file $xmlconfig.tmp \n");
    
    my $i=0;
    my $j=0;
     
    #$config->XMLout($rcopy);
    
    # Some needed variables
    my $nuser;
    my $naddress;
    my $arg;
    my $narg;
    my $local;
    my $nlocal;
    my $remote;
    my $nremote;
    
    print FILE "<rcopy>\n";
    
    for ( @{$config->{server}} ){
        # Old user/address values:
        $user = $_->{ruser}->[0];
        $address = $_->{address}->[0];

        # Prompt for new address:
        $_->{address}->[0] = prompt("$i. Enter new Server IP/Hostname[$address]:");
       
        # make sure the user actually changed this, or
        # else use original value
        $_->{address}->[0]  = ( $_->{address}->[0] ne "" ) ? $_->{address}->[0] : $address;

        # Prompt for new user
        $_->{ruser}->[0] = prompt("$i. Enter Username[$user] for server ".$_->{address}->[0].":");

        $_->{ruser}->[0] = (  $_->{ruser}->[0] ne "" ) ? $_->{ruser}->[0] : $user;
         
        # Print address/user to file:
        print FILE "\t<server>\n";
        print FILE "\t\t<address>".$_->{address}->[0]."</address>\n";
        print FILE "\t\t<ruser>".$_->{ruser}->[0]."</ruser>\n";
            
        for ( @{$_->{file}} ){
            # loop thru e/a server's file line. They look like:
            # < file arg = "" local = "" remote = "" />
            $arg = $_->{arg};
            $_->{arg} = prompt("$i.$j. Enter new arguments[$arg]: ");
            $_->{arg} = ( $_->{arg} ne "" ) ? $_->{arg} : $arg;

            $remote = $_->{remote};
            $_->{remote} = prompt("$i.$j. Enter new remote path[$remote]: ");
            $_->{remote} = ( $_->{remote} ne "" ) ? $_->{remote} : $remote;


            $local = $_->{local};
            $_->{local} = prompt("$i.$j. Enter new local path[$local]:");
            $_->{local} = ( $_->{local} ne "" ) ? $_->{local} : $local;

            print FILE "\t\t<file arg=\"$_->{arg}\" local=\"$_->{local}\" remote=\"$_->{remote}\" />\n";
            $j++;
        } # end for $_-file
       
        # User may want to add a new file to this server
       
        # no need to reset counter here.
        # let the next entry be a unique one
        #$j=0; # resets counter
         
        while ( $response eq 'y' ) {
            $response = prompt("Enter new file/dir [ $config->{server}->{address}->[0] ][y/N]: ");
            
            # another way to get out of this loop is:
            if ($response ne 'y') { 
                last; 
            }
            $rcopy{server}[$i]{local}[$j] = prompt($i . "." . $j .". Enter local directory for this computer [/path/]: ");

            $rcopy{server}[$i]{remote}[$j] = prompt($i . "." . $j .". Enter remote directory for server ". $rcopy{server}[$i]{address}[0]." [/path/to]: ");
            
            $rcopy{server}[$i]{arg}[$j] = prompt($i . "." . $j .". Enter extra arguments [i.e. --delete [or --rsync_argument]]: ");
            
            print FILE "\t\t<file arg=\"$rcopy{server}[$i]{arg}[$j]\" local=\"$rcopy{server}[$i]{local}[$j]\" remote=\"$rcopy{server}[$i]{remote}[$j]\" />\n";

            $j++;
            
        } # end while response ne y
        
        # close this server
        print FILE "\t</server>\n";
        
        $j=0; # reset counter    
        $i++; # increase server counter
    } # end for e/a config->server
    
    # if user wants to add more servers, then
    # lets help him/her:
    
    $response = prompt("Want to add a new server[y/N]:\n");
   
    $response = ( $response eq 'y' ) ? $response : "q";
    
    while ( $response ne 'q' ) { # if user just hit enter before
                                 # we will not even enter this
                                 # loop
        
        $rcopy{server}[$i]{address}[0] = prompt($i.". Enter server name or IP: ");
        print FILE "\t<server>\n";
        print FILE "\t\t<address>".$rcopy{server}[$i]{address}[0]."</address>\n";
        
        $rcopy{server}[$i]{ruser}[0] = prompt($i .". Enter remote username: ");
        
        print FILE "\t\t<ruser>".$rcopy{server}[$i]{ruser}[0]."</ruser>\n";
        # Now get the arguments for this given server:
        # LOCAL PATH
        # REMOTE PATH
        # ARGUMENTS
        #
        while ( 1 ) {
            $rcopy{server}[$i]{local}[$j] = prompt($i . "." . $j .". Enter local directory for this computer [/path/]: ");

            $rcopy{server}[$i]{remote}[$j] = prompt($i . "." . $j .". Enter remote directory for server ". $rcopy{server}[$i]{address}[0]." [/path/to]: ");
            
            $rcopy{server}[$i]{arg}[$j] = prompt($i . "." . $j .". Enter extra arguments [i.e. --delete [or --rsync_argument]]: ");
            
            print FILE "\t\t<file arg=\"$rcopy{server}[$i]{arg}[$j]\" local=\"$rcopy{server}[$i]{local}[$j]\" remote=\"$rcopy{server}[$i]{remote}[$j]\" />\n";

            $j++;
            
            $response = prompt("Enter a new file/dir [y/N]: ");
            
            # another way to get out of this loop is:
            if ($response ne 'y') { 
                last; 
            }
        } 

        $j=0; # reset $j
        $i++; # increase server counter
        
        print FILE "\t</server>\n";
        
        $response = prompt("Enter q to end: ");
            
        #if ($response eq 'q') { 
            #    last; 
            #}
    } # end while
    
    print FILE "</rcopy>\n";
    close (FILE);

    # successfully edited, now delete the old
    # config file and then rename the new one
    unlink $xmlconfig;
    rename "$xmlconfig.tmp","$xmlconfig";

    #if ( $DBUG ==1 ) { print Dumper($rcopy); }
} # ends update_config


# This subroutine creates an example .xml config file
sub create_example {

    my $sample = "<rcopy>
    <server>
        <address>www.server.com</address>
        <ruser>myuser</ruser>
        <file arg=\"\" local=\"/tmp/\" remote=\"/tmp/test\" />
    </server>
</rcopy>"; 
    open (FILE,"> $xmlconfig");
    print FILE $sample;
    close(FILE);

} # ends create_example

# This subroutine prompts a user for a response
# which is then returned to the original caller
# my $var = prompt("string");
sub prompt {
    # promt user and return input 
    my($string) = shift;
    my($input) = "";
    
    print ($string."\n");
    chomp($input = <STDIN>);
        # chomp is the same as:
        # $input =~ s/\n//g; # remove lineend
    return $input;
} # ends prompt

sub edit_config_gui {

    # check for the config file and load that
    # if it exist, if it doesnt, then create a sample
    # and parse that
    if (!-f $xmlconfig) { 
        print STDERR ("No config file found \n"); 
        create_example();
        #exit(1); 
    }
    
    # load the Tk module
    use Tk;
    # load the settings from the config file
    my $config = XMLin($xmlconfig,forcearray=>1);
    
    my $Main = MainWindow->new();

    my $box1 = $Main->Label(-text => "$xmlconfig", -borderwidth => 1, -relief => "raised");
    $box1->form(-top => '%0', -left => '%0', -right => '%100');
    
    MainLoop;
    #__END__
    

}
