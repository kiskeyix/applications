#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Oct-24
# 
# $Id: rcopy.pl,v 1.6 2002-12-09 00:46:11 luigi Exp $
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
# BUGS: 
# 1. when updating long .xml config files, the update_config
#    becomes annoying!
# 

my $DBUG = 0;       # use 1 for true

use strict;         
$|++;               # disable buffering on standard output
      
use XML::Simple;
use Config;

if ( $DBUG != 0 ) { use Data::Dumper; }

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

# progress
my $total_tasks = 0;
my $task_num = 0;
my $progress_status = 0.0; # number between 0.0 and 1.0

# hate to see warnings, therefore:
while ( $_ = ( $ARGV[0] ) ? $ARGV[0] : "" , /^-/) {
    shift;
    last if /^--$/;
    
    if (/^-+f(.*)/) { $xmlconfig="$1"; }
    elsif (/^-+n(.*)/) { create_config(); exit(0); }
    elsif (/^-+d(.*)/) { $DAEMON=1; } 
    elsif (/^-+u(.*)/ ) { update_config(); exit(0); }
    elsif (/^-+ex(.*)/) { create_example(); exit(0); }
    elsif (/^-+gui/) { init_config_gui(); exit(0); }
    elsif (/^-+h(.*)/) { 
        print "USAGE: rcopy [option] \n 
                \t -f\"file\" \t\t use this XML file as the config file \n
                \t \t\t i.e -f\"/path/to/file.xml\" \n
                \t -n,-new \t create new config file \n
                \t -u,-update \t updates config \n
                \t -d,-daemon \t non interactive (no /dev/tty) \n
                \t -example \t creates an example config file \n\n";
    exit(0); }
}

##
# All code comes down to this few lines!!
##
sub do_sync {
    # reset progress status
    $total_tasks = 0;
    $task_num = 0;
    $progress_status = 0.0; # number between 0.0 and 1.0

    my ($lxmlconfig,$pbar) = @_;

    # user passed a different config file?
    $xmlconfig = ( -f $lxmlconfig ) ? $lxmlconfig : $xmlconfig;
    
    # Create lock
    open (LOCKFILE,"> $rcopylock") or die ("Could not create file $rcopylock \n");

    # re-read config file
    if ( -f $xmlconfig ) {
        $config = XMLin($xmlconfig,forcearray=>1);
    } else {
        print STDERR "File '$xmlconfig' cannot be open";
        unlink $rcopylock;
        exit(1);
    }
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
    my $ADATE=($year+=1900)."-$mon-$mday $hour:$min:$sec";
    print LOCKFILE "Lock File on $rcopylock created on $ADATE \n";
 
    if ( $pbar ) {
        # count number of servers and its files
        for ( @{$config->{server}}) {
            $total_tasks++;
            for ( @{$_->{file}} ) {
                $total_tasks++;
            }
        }
    }
    for ( @{$config->{server}} ){

        $user = $_->{ruser}->[0];
        $address = $_->{address}->[0];
        
        if ( $pbar ) {
                # update progress
                $task_num++;
        }

        for ( @{$_->{file}} ){
            if ( $pbar ) {
                # update progress
                $task_num++;
                $progress_status = $task_num / $total_tasks;
            
                # gui is running and progress bar
                # was passed to us... update with
                # server information

                print STDERR "num: $task_num \t progress: $progress_status \n";
                update_pbar($pbar,$progress_status);
            }
            print("\n Executing: $RSYNC $_->{arg} $user\@$address:$_->{remote} $_->{local}\n");
            system("$RSYNC $_->{arg} $user\@$address:$_->{remote} $_->{local} ");
        }
    }
    
    if ( $DBUG !=0 ) {
        print STDERR Dumper($config);
    }
    
    print ("\n\n");
    # Remove lock
    unlink($rcopylock);
}

########################################
# Definition for functions/subroutines #
########################################

sub create_config {
    # creates a config file without using a GUI
    
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

    if ( $DBUG !=0  ) { print Dumper(%rcopy); }
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

sub do_exit {
    Gtk->exit(0);
}
#
# use this function to update the progress bar
# arguments: progress_bar_widget
# percentage is a number from 0.0 to 1.0
#
# update progress bar
# by adding increments of .2 to it
# 
sub update_pbar { 
    my ($pbar,$new_val) = @_;
    
    #my $val = $pbar->get_current_percentage; 
    
    #my $new_val = $val + 0.2;
    
    if ($new_val > 1.01)  {
        $new_val = 1.0;
        return 0;
    }
    
    $pbar->update($new_val); 
    return 1 
} 

#sub create_menu {
#    
#    my @buffer = @_;
#    
#    # menu widget
#    my $menu = new Gtk::Menu;
#
#    my $menuitem = undef;
#    
#    foreach my $i (@buffer) {
#        $menuitem = new Gtk::MenuItem("$i");
#        $menu->append($menuitem);
#        $menuitem->show;
#    }
#    
#    return $menu;
#}
sub destroy_window {
    my($widget, $windowref, $w2) = @_;
    $$windowref = undef;
    $w2 = undef if defined $w2;
    0;      
}

sub create_help_window {
    
    my $help_window = new Gtk::Window("toplevel");
    
    $help_window->set_title("Rcopy Gtk GUI: Help");
    $help_window->set_uposition(20, 20);
    $help_window->set_usize(400, 400);
    
    $help_window->signal_connect("destroy" => \&destroy_window,\$help_window);
    $help_window->signal_connect("delete_event" => \&destroy_window,\$help_window);
    
    my $box1 = new Gtk::VBox(0, 0);
    $help_window->add($box1);
    $box1->show;
   
    my $readme="";
    
    if ( -f "README" ) {
        open (README,"README") or print STDERR ("Could not open file README \n");
        # read to variable
        $readme = "";
        while (<README>){
            $readme .= $_;
        }
        close(README);
    } else {
        $readme = "Could not find README file in current directory $ENV{PWD}";
    }
    
    my $label = new Gtk::Label "README";
    $label->set_usize(20, 20);
    $label->set_alignment(0.5, 0.5);
    $box1->pack_start($label, 0, 0, 0);
    $label->show;
    
    my $scw = new Gtk::ScrolledWindow(undef, undef);
    $scw->set_policy('automatic', 'automatic');
    $scw->show;
    $scw->set_border_width(10);
    
    $box1->pack_start($scw, 1, 1, 0); 
    
    # holds the readme
    my $box2 = new Gtk::VBox(0, 0);
    $box2->show;
    $box2->set_border_width(10);
    $scw->add_with_viewport($box2);
    
    my $label2 = new Gtk::Label "$readme";
    $box2->pack_start($label2, 0, 0, 0);
    $label2->set_alignment(0.0, 0.5);
    $label2->show;
    
    my $separator = new Gtk::HSeparator;
    $box1->pack_start($separator, 0, 1, 0);
    $separator->show;
    
    # holds the close button
    my $box3 = new Gtk::VBox(0, 10);
    $box3->border_width(10);
    $box1->pack_start($box3, 0, 1, 0);
    $box3->show;
    
    my $button = new Gtk::Button "close";
    
    $button->signal_connect( clicked => sub {destroy $help_window});
    $box3->pack_start($button, 1, 1, 0);
    $button->can_default(1);
    $button->grab_default();
    $button->show;
    $help_window->show;
    
}
#
# commands for itemfactory...
# 
sub item_factory_cb {
    my ($widget, $action, @data) = @_;

    if ($action == 30){
        # help
        create_help_window;
    } elsif ($action == 13) {
        do_exit;
    }
    # debug
    if ( $DBUG != 0 ) { 
        print "ItemFactory: activated ", $widget->item_factory_path(), " -> ", $action, "\n";
    }
}

sub init_config_gui {

    # check for the config file and load that
    # if it exist, if it doesn't, then create a sample
    # and parse that
    if (!-f $xmlconfig) { 
        print STDERR ("No config file found \n"); 
        create_example();
    }
    
    # load the Gtk module
    use Gtk;
    use Gtk::Atoms;

    # load the settings from the config file
    my $config = XMLin($xmlconfig,forcearray=>1);

    init Gtk;

    my $window = new Gtk::Window('toplevel');
    $window->set_title("Rcopy Gtk GUI");
    $window->set_uposition(20, 20);
    $window->set_usize(400, 400);

    $window->signal_connect("destroy" => \&Gtk::main_quit);
    $window->signal_connect("delete_event" => \&Gtk::false);
    
    # a most efficient way to do it:
    my @item_factory_entries = (
        ["/_File",              undef,          0,      "<Branch>"],
        #["/File/tearoff1",      undef,          0,      "<Tearoff>"],
        ["/File/_New",          "<control>N",   1,      "<Item>"],
        ["/File/_Open",         "<control>O",   2,      "<Item>"],
        ["/File/_Save",         "<control>S",   3,      "<Item>"],
        ["/File/Save _As...",   undef,          4,      "<Item>"],
        ["/File/sep1",          undef,          0,      "<Separator>"],
        ["/File/S_ync",         "<control>Y",   5,      "<Item>"],
        ["/File/sep1",          undef,          0,      "<Separator>"],
        ["/File/S_ettings",     "<control>E",   6,      "<Item>"],
        ["/File/sep1",          undef,          0,      "<Separator>"],
        ["/File/_Quit",        "<control>Q",   13,      "<Item>"],
        ["/_Edit",              undef,          0,      "<Branch>"],
        ["/Edit/_Copy",         "<control>C",   10,     "<Item>"],
        ["/Edit/C_ut",          "<control>X",   11,     "<Item>"],
        ["/Edit/_Paste",        "<control>V",   12,     "<Item>"],
        ["/_Help",              undef,          0,      "<LastBranch>"],
        ["/Help/_About",        undef,          30,     "<Item>"]
    );
    my ($accel_group, $item_factory, $box1, $label, $label3, $box2, $pbar);
    my ($separator, $button, $dummy);

    $accel_group = new Gtk::AccelGroup;
    $item_factory = new Gtk::ItemFactory('Gtk::MenuBar', "<main>", $accel_group);

    $accel_group->attach($window);
    
    foreach (@item_factory_entries) {
	$item_factory->create_item($_, \&item_factory_cb);
    }
    
    $box1 = new Gtk::VBox(0, 0);
    $window->add($box1);
    $box1->pack_start($item_factory->get_widget('<main>'), 0, 0, 0);

    $label = new Gtk::Label "Drop file/directory here to start";

    $label->set_usize(200, 200);
    $label->set_alignment(0.5, 0.5);
    $box1->pack_start($label, 1, 1, 0);

    $separator = new Gtk::HSeparator;
    $box1->pack_start($separator, 0, 1, 0);

    $box2 = new Gtk::VBox(0, 10);
    $box2->set_border_width(10);
    $box1->pack_start($box2, 0, 1, 0);
    
    $label3 = new Gtk::Label "Total Progress:";
    $label3->set_usize(20, 20);
    $label3->set_alignment(0.5, 0.5);
    $box2->pack_start($label3, 1, 1, 0);

    $pbar = new Gtk::ProgressBar;
    $pbar->set_usize(200,20);
    $box2->pack_start($pbar,1,1,0);
    $pbar->show;

    # init progress bar
    $pbar->update(0.0);

    $button = new Gtk::Button("Sync");
    $button->signal_connect('clicked', sub{ do_sync($xmlconfig,$pbar); });
        #sub{update_pbar($pbar)});
        # sub {$window->destroy;});
    $box2->pack_start($button, 1, 1, 0);
    $button->can_default(1);
    $button->grab_default;

    # show all
    if (!visible $window) {
        $window->show_all;
    } else {
        $window->destroy;
    }

    main Gtk;
}

# by default try to sync
do_sync $xmlconfig;

