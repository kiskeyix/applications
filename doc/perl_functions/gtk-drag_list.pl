#!/usr/bin/perl -w
# $Id: gtk-drag_list.pl,v 1.1 2002-09-26 19:46:49 luigi Exp $
# Last modified: 2002-Sep-26
# 
# Luis Mondesi < lemsx1@hotmail.com >
#
# This script uses GTK to create a GUI to allow users to drop files
# on top of them and rsync's them over SSH to a remote server.
#
use strict;
$|++;

#use 5.6.0;
use warnings;
use Gtk;

my $target = { target => "text/plain", flags => 0, info => 0 };

sub drag_begin($$) {
    my ($widget, $drag_context) = @_;

    my $window = Gtk::Window->new("popup");
    $window->add(Gtk::Label->new("$widget drag"));

    $window->signal_connect("event", sub {
            my (undef, $event) = @_;
            print("event: ", $event->{type}, "\n");
            return(0);
        });
    $window->show_all();
    $drag_context->set_icon_widget($window, -20, 0);
    return(1);
}

Gtk->set_locale();
Gtk->init();

my $w1 = Gtk::Window->new("toplevel");
my $h1 = Gtk::HBox->new();
my $t1 = Gtk::Tree->new();
my $l1 = Gtk::CList->new_with_titles(qw(Name));

$h1->pack_start($t1, 1, 1, 0);
$h1->pack_start($l1, 1, 1, 0);
$w1->add($h1);

foreach my $f (qw(one two three)) { $t1->append(Gtk::TreeItem->new($f)); }
$t1->drag_source_set(["button1_mask", "button3_mask"], ["copy", "ask"], $target);
$t1->signal_connect("drag_begin", \&drag_begin);

foreach my $f (qw(four five six)) { $l1->append("$f"); }
$l1->drag_source_set(["button1_mask", "button3_mask"], ["copy", "ask"], $target);
$l1->signal_connect("drag_begin", \&drag_begin);

if ($l1->get('use_drag_icons')) {
      $l1->set('use_drag_icons', 0);
}

$w1->signal_connect("delete_event", sub { Gtk->exit(0); });
$w1->show_all();
Gtk->main();

