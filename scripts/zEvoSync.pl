#!/usr/bin/perl -w
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Nov-16
# 
# $Revision: 1.1 $
# 
# VERSION: 0.1
#
# LICENSE:
# GPL
# http://www.gnu.org/licenses/gpl.html
#
# DESCRIPTION: 
# 
# USAGE: 
#
# REQUIREMENTS: perl
#
# BUGS: 
# 

my $DBUG = 0;       # use 1 for true

use strict;         
$|++;               # disable buffering on standard output
      
########################################
# Definition for functions/subroutines #
########################################

sub do_sync {
    # main function
    print STDERR "hello world";
}

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
    use Gtk;
    use Gtk::Atoms;
    
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
    
    $label = new Gtk::Label "Sample Text";
    
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
    $button->signal_connect('clicked', sub{ do_sync(); });
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
