#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Nov-16
# 
# $Revision: 1.3 $
# 
# VERSION: 0.1
#
# LICENSE:
#       GPL http://www.gnu.org/licenses/gpl.html
#
# DESCRIPTION: 
#       Using a different approach to sync the Zaurus
#       XML-based addressbook and the evolution DB-based
#       addressbook.
# 
# RESOURCES:
#       * vCard description: http://www.ietf.org/rfc/rfc2739.txt
#
# USAGE: 
#       ** NO SWITCHES **
#
# REQUIREMENTS: 
#       * perl
#       * GTK module
#       * DB_File
#       * XML::Parser
#
# BUGS: 
#
# TODO:
#       * sync the calendar
#       * add switches to make life simpler (no need for gui)

my $DBUG = 0;       # use 1 for true

use strict;         
$|++;               # disable buffering on standard output

use Gtk;
use Gtk::Atoms;
#use XML::Simple; 

#--------------------------------------#
#            Configuration             #
#--------------------------------------#

# db to xml file for evo addressbook
my $temp_file = "$ENV{HOME}/evolution/.tmp-file.xml";
my %DBFILE = ();

#--------------------------------------#
# Definition for functions/subroutines #
#--------------------------------------#

sub do_zau_sync {
    # main function
    print STDERR "hello world";
}

#
# borrowed from evolution-db-dump.pl v 0.02
# gets the addressbook.db file from Evolution
# and prints it's content in a format that 
# the Zaurus can use.
sub do_evo_sync {

    use DB_File;
  
    my $key = "";
    my $line = "";
    my $item = "";
    my $data = "";
    my $field = "";
    my @list = ();

    dbmopen(%DBFILE,"$ENV{HOME}/evolution/local/Contacts/addressbook.db", 0400) || die "cant open db -->: $!\n";

    open(FILE, "> $temp_file") || die "Couldn't write file --> $!\n";

    print FILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE Addressbook><AddressBook>\n";
    print FILE "<Contacts>\n";
 
    # this line temporarily turns off warnings
    no warnings;
   
    foreach $key (keys(%DBFILE)){
        $line = $DBFILE{$key};
    
        next if $line !~ m/.*:.*/; 
    
        @list = split /\r\n/, $line;
        my %dbhash;
        foreach $item ( @list ) {
            if ( $item =~ m/^$/ ) {     
                next;
            }
            if ( $item =~ m/^\x00$/ ) {     
                next;
            }
            chomp $item;
            ($field, $data) = split /:/, $item, 2;
            
            if ($field =~ m/TEL.*WORK.*FAX.*/){
                $field = "TEL;WORK;FAX";
            } elsif ($field =~ m/TEL.*WORK.*/){
                $field = "TEL;WORK;VOICE";
            } elsif ($field =~ m/TEL.*VOICE.*/) {
                $field = "TEL;HOME";
            } elsif ($field =~ m/TEL.*HOME.*/) {
                $field = "TEL;HOME";
            } elsif ($field =~ m/TEL.*CELL.*/) {
                $field = "TEL;CELL";
            } elsif ($field =~ m/TEL.*PAGER.*/) {
                $field = "TEL;PAGER";
            } elsif ($field =~ m/ADR.*WORK/) {
                $field = "ADR;WORK";
            } elsif ($field =~ m/ADR.*/) {
                $field = "ADR;HOME";
            }

            #print " data = $data -- field = $field\n";
            $dbhash{$field} = $data;

        } # end foreach
        # parse vcard:
        my ($lastname, $firstname, $middle, $rest) = split /;/, $dbhash{N}, 4;
        my ($pobox, $address2, $address1, $city, $state, $zip, $country) = split /;/, $dbhash{'ADR;WORK'};
        my ($hpobox, $haddress2, $haddress1, $hcity, $hstate, $hzip, $hcountry) = split /;/, $dbhash{'ADR;HOME'};
        my ($company, $dept) = split /;/, $dbhash{ORG};
        # print e/a contact
        print FILE "<Contact FirstName=\"$firstname\"".
        " MiddleName=\"$middle\" LastName=\"$lastname\" ".
        "FileAs=\"$dbhash{'X-EVOLUTION-FILE-AS'}\" ".
        "DefaultEmail=\"$dbhash{'EMAIL;INTERNET'}\" ".
        "Emails=\"$dbhash{'EMAIL;INTERNET'}\" ".
        "HomeStreet=\"$hpobox $haddress1 $haddress2\" ".
        "HomeCity=\"$hcity\" HomeState=\"$hstate\" ".
        "HomeZip=\"$hzip\" HomeCountry=\"$hcountry\" ".
        "HomePhone=\"$dbhash{'TEL;HOME'}\" ".
        "Company=\"$company\" ".
        "BusinessStreet=\"$pobox $address1 $address2\" ".
        "BusinessCity=\"$city\" BusinessState=\"$state\" ".
        "BusinessZip=\"$zip\" BusinessCountry=\"$country\" ".
        "BusinessWebPage=\"$dbhash{URL}\" ".
        "JobTitle=\"$dbhash{ROLE}\" Department=\"$dept\" ".
        "BusinessPhone=\"$dbhash{'TEL;WORK;VOICE'}\" ".
        "BusinessFax=\"$dbhash{'TEL;WORK;FAX'}\" ".
        "BusinessMobile=\"$dbhash{'TEL;CELL'}\" ".
        "BusinessPager=\"$dbhash{'TEL;PAGER'}\" ".
        "Spouse=\"$dbhash{'X-EVOLUTION-SPOUSE'}\" ".
        "Nickname=\"$dbhash{NICKNAME}\" ".
        "Notes=\"$dbhash{'NOTE;QUOTED-PRINTABLE'}\"/>\n";
    }

    print FILE "</Contacts>\n</AddressBook>\n";
    dbmclose(%DBFILE);

    close($temp_file);
}

# sample printVcard function
# borrowed from: http://www.heise.de/ix/artikel/1999/05/161/01.shtml
sub printVcard {
    my (%hash) = @_;
    print "begin:vcard\n";
    print "n:$hash{nachname};$hash{vorname}\n";
    print "fn: $hash{vorname} $hash{nachname}\n";
    if (exists $hash{strasse} && exists $hash{plz? &&
        exists $hash{ort}) {
        print "adr:;;$hash{strasse};$hash{ort};;$hash{plz};Germany\n";
    }
    print "tel;work:$hash{telgesch}\n" if (exists $hash{telgesch});
    print "tel;fax;work:$hash{faxgesch}\n" if (exists $hash{faxgesch});
    print "email;internet:$hash{mail}\n" if (exists $hash{mail});
    print "end:vcard\n";
}



#
# GUI
# 
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

sub destroy_window {
    my($widget, $windowref, $w2) = @_;
    $$windowref = undef;
    $w2 = undef if defined $w2;
    0;      
}

sub create_help_window {
    
    my $help_window = new Gtk::Window("toplevel");
    
    $help_window->set_title("Zaurus Evolution Sync Help");
    $help_window->set_uposition(20, 20);
    $help_window->set_usize(400, 400);
    
    $help_window->signal_connect("destroy" => \&destroy_window,\$help_window);
    $help_window->signal_connect("delete_event" => \&destroy_window,\$help_window);
    
    my $box1 = new Gtk::VBox(0, 0);
    $help_window->add($box1);
    $box1->show;
   
    my $readme=" This is all the help you need for now... ditto! \n http://www.latinomixed.com";
    
#    if ( -f "README" ) {
#        open (README,"README") or print STDERR ("Could not open file README \n");
#        # read to variable
#        $readme = "";
#        while (<README>){
#            $readme .= $_;
#        }
#        close(README);
#    } else {
#        $readme = "Could not find README file in current directory $ENV{PWD}";
#    }
    
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
    
    # load the Gtk module
   
    init Gtk;

    my $window = new Gtk::Window('toplevel');
    $window->set_title("Zaurus Evolution Sync");
    $window->set_uposition(20, 20);
    $window->set_usize(400, 400);

    $window->signal_connect("destroy" => \&Gtk::main_quit);
    $window->signal_connect("delete_event" => \&Gtk::false);
    
    # a most efficient way to do it:
    my @item_factory_entries = (
        ["/_File",              undef,          0,      "<Branch>"],
        #["/File/tearoff1",      undef,          0,      "<Tearoff>"],
#        ["/File/_New",          "<control>N",   1,      "<Item>"],
#        ["/File/_Open",         "<control>O",   2,      "<Item>"],
#        ["/File/_Save",         "<control>S",   3,      "<Item>"],
#        ["/File/Save _As...",   undef,          4,      "<Item>"],
#        ["/File/sep1",          undef,          0,      "<Separator>"],
        ["/File/S_ync",         "<control>Y",   5,      "<Item>"],
#        ["/File/sep1",          undef,          0,      "<Separator>"],
        ["/File/S_ettings",     "<control>E",   6,      "<Item>"],
#        ["/File/sep1",          undef,          0,      "<Separator>"],
        ["/File/_Quit",        "<control>Q",   13,      "<Item>"],
        ["/_Edit",              undef,          0,      "<Branch>"],
        ["/Edit/_Copy",         "<control>C",   10,     "<Item>"],
        ["/Edit/C_ut",          "<control>X",   11,     "<Item>"],
        ["/Edit/_Paste",        "<control>V",   12,     "<Item>"],
        ["/_Help",              undef,          0,      "<LastBranch>"],
        ["/Help/_About",        undef,          30,     "<Item>"]
    );
    my ($accel_group, $item_factory, $box1, $label, $label3, $box2, $pbar);
    my ($separator, $button, $bget_evo_db, $dummy);

    $accel_group = new Gtk::AccelGroup;
    $item_factory = new Gtk::ItemFactory('Gtk::MenuBar', "<main>", $accel_group);

    $accel_group->attach($window);
    
    foreach (@item_factory_entries) {
	$item_factory->create_item($_, \&item_factory_cb);
    }
    
    $box1 = new Gtk::VBox(0, 0);
    $window->add($box1);
    $box1->pack_start($item_factory->get_widget('<main>'), 0, 0, 0);
    
    $label = new Gtk::Label "Backup your files first!";
    
    $label->set_usize(200, 200);
    $label->set_alignment(0.5, 0.5);
    $box1->pack_start($label, 1, 1, 0);

    # TODO display a log file here
    # and update this after whatever the user chooses todo

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

    $bget_evo_db = new Gtk::Button("Evolution --> Zaurus");
    $bget_evo_db->signal_connect('clicked', sub{ do_evo_sync(); });
    $box2->pack_start($bget_evo_db, 1, 1, 0);
    
    $button = new Gtk::Button("Zaurus --> Evolution");
    $button->signal_connect('clicked', sub{ do_zau_sync(); });
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

# devel mode: for now init gui
init_config_gui
