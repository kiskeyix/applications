#!/usr/bin/perl -w
# vi: wm=79:tw=79 :
# 2004-09-22 21:57 EDT $Revision: 1.5 $ 
# Luis Mondesi <lemsx1@hotmail.com> 
# Converts a bookmarks.html(firefox/mozilla/netscape) file 
# to bookmarks.rss (1.0)
#
# There is no need to edit anything below. To run simply do:
#
# bookmark2rss.pl /path/to/bookmarks.html   # will print to STDOUT use -o
#                                           # file.rss to specify where to output
#
# or 
#
# bookmarks2rss.pl  # which assumes firefox's bookmarks are in: 
#                   # ~/.mozilla/firefox/*default*/bookmarks.html. Will output
#                   # to STDOUT
#
# The resulting output will be printed to STDOUT unless --output= is given
#
# TODO
#   - should live bookmarks be included? hint: instead of "href" look for FEEDURL attribute
#
# CHANGELOG:
#   - 2004-11-22 14:02 EST  Added support for finding mozilla's bookmarks.html
#                           files automatically. More cleanups
#   - 2004-11-22 13:24 EST  Added better support for HTML::Parser, now XML::RSS 
#                           can include better things, like nice Text names
#   - 2004-11-22 13:23 EST  Perl 5.8.x fixed utf8 problems. ton of cleanups

package Bookmarks2rss;
use vars qw(@ISA);
@ISA = qw(HTML::Parser);

use strict;
use utf8;
$|++;

# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');
# non-standard modules
require HTML::Parser;
use XML::RSS;
use POSIX qw(setlocale ctime);

# create XML::RSS object
my $rss = new XML::RSS (version => '1.0');
# create HTML::Parser object:
my $p = new Bookmarks2rss;

# some defaults (to customize from command line)
my $SITE = ""; # --site
my $DESC = "My Firefox Bookmarks";
my $DATE = "";
my $SUBJECT = "bookmarks";
my $CREATOR = ""; # --creator
my $PUBLISHER = "$CREATOR"; # --publisher
my $COPYRIGHT = "";
my $LOCALE = ""; # --language
my $UPDATED = "daily"; # --update-period
my $FREQ = "1"; # --update-frequency
my $UPDATEBASE = "1901-01-01T00:00+00:00";
my $OUTPUT="";

# command line arguments:
GetOptions(
    # flags
    # strings
    's|site=s'      =>  \$SITE,
    'd|desc=s'      => \$DESC,
    'subject=s'     => \$SUBJECT,
    'creator=s'     => \$CREATOR, # email?
    'publisher=s'   => \$PUBLISHER,
    'copyright=s'   => \$COPYRIGHT,
    'l|language=s'  => \$LOCALE,
    'updated=s'     => \$UPDATED,
    'update-frequency=s'    => $FREQ,
    'update-base'   => \$UPDATEBASE,
    'o|output=s'    => \$OUTPUT,
    # numbers
);

# supporting functions:
sub start
{
   my($self,$tag,$attr,$attrseq,$orig) = @_;
   if ( $tag eq 'a')
     {
        if ($self->{cur_url} = $attr->{href})
          {
            $self->{got_href}++;
          }
     }
}

sub end
{
  my ($self,$tag) = @_;

  $self->{got_href}-- if ($tag eq 'a' && $self->{got_href} )
}

sub text
{
  my ($self,$text ) = @_;

  if ($self->{got_href} )
    {
      # $self->{URLS}{$self->{cur_url}} .= $text; 
    
      # Add item:
      $rss->add_item( title => "$text",  link => $self->{cur_url} );
    }
}

sub find_bookmarks
{
    my $file = shift;
    my @out = ();
    if ( defined($file) && -f "$file" )
    {
        push(@out,$file);
        return @out;
    } else {
       @out = glob ($ENV{HOME}."/.mozilla/firefox/*default*/bookmarks.html"); 
       return @out;
    }
    return undef; # failed?
}

sub usage_die
{
    print STDERR "Usage: $0 [/path/to/bookmarks.html]\n";
    exit(1);
}

# Parse away!
#
# First, setup our RDF "channel"

# some defaults:
$CREATOR = $PUBLISHER if ( $CREATOR eq "" ); # not too smart but works :-)
$PUBLISHER = $CREATOR if ( $PUBLISHER eq "" );
$SITE = "public" if ( $SITE eq "" ); # hostname --long might be leaking too much info
$LOCALE = $ENV{LANGUAGE} if ( $LOCALE eq "" ); 
$LOCALE = $ENV{LANG} if ( $LOCALE eq "" );  # fallback in case $LANGUAGE was not set

POSIX::setlocale( &POSIX::LC_ALL, $LOCALE );
$DATE = ctime(time) if ($DATE eq ""); # ctime format: Sat Nov 19 21:05:57 1994

$rss->channel(
    title        => "$SITE",
    link         => "http://$SITE",
    description  => "$DESC",
    dc => {
        date       => "$DATE",
        subject    => "$SUBJECT",
        creator    => "$CREATOR",
        publisher  => "$PUBLISHER",
        rights     => "$COPYRIGHT",
        language   => "$LOCALE",
    },
    syn => {
        updatePeriod     => "$UPDATED",
        updateFrequency  => "$FREQ",
        updateBase       => "$UPDATEBASE",
    },
);

# find all bookmark files and parse all:
my @ifile = find_bookmarks(shift);# || usage_die($!);

foreach my $f (@ifile)
{
    if ( -f "$f" ) # redundant? you bet!
    {
        $p->parse_file($f); # TODO if two or more bookmark files are found, 
                            # the last one would override the content of the 
                            # first parse file. perhaps this should be reported to STDERR?
    } else {
        print STDERR "$f is not a file!\n";
    }
}

# print RSS to file or STDOUT
if ( $OUTPUT ne "" )
{
    open (OUTPUT,">:utf8","$OUTPUT") || die $!;
    print OUTPUT $rss->as_string;
    close(OUTPUT);
} else {
    ## FIXME Perl gives "wide character" warning for UTF-8 locales
    print STDOUT $rss->as_string;
}
