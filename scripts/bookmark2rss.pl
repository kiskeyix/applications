#!/usr/bin/perl -w
# 2004-09-22 21:57 EDT $Revision: 1.1 $ 
# Luis Mondesi <lemsx1@hotmail.com> 
# Converts a bookmarks.html(firefox/mozilla/netscape) file 
# to bookmarks.rss (1.0)
#
# There is no need to edit anything below. To run simply do:
#
# bookmark2rss.pl /path/to/bookmarks.html 
#
# The resulting output will be printed to STDOUT

use strict;
$|++;
# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');
# non-standard modules
use HTML::Parser 3.00 ();
use XML::RSS;
# create XML::RSS object
my $rss = new XML::RSS (version => '1.0');

my $SITE = ""; # --site
my $DESC = "My Bookmarks";
my $DATE = ""; # TODO get date()
my $SUBJECT = "bookmarks";
my $CREATOR = ""; # --creator
my $PUBLISHER = "$CREATOR";
my $COPYRIGHT = "";
my $LOCALE = "en-us"; # --language
my $UPDATED = "daily"; # --update-period
my $FREQ = "1"; # --update-frequency
my $UPDATEBASE = "1901-01-01T00:00+00:00";
my $OUTPUT="";

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

sub a_start_handler
{
    my($self, $tag, $attr) = @_;
    return unless $tag eq "a";
    return unless exists $attr->{"href"};
    
    my $url = $attr->{"href"};
    #print "A $url\n";
    # TODO get text as title for this link
    #$bookmarks{$url}{"url"} = $url;
    $rss->add_item( title => "$url",  link => "$url" );

    $self->handler(text  => [], '@{dtext}' );
    $self->handler(start => \&img_handler);
    $self->handler(end   => \&a_end_handler, "self,tagname", $url);
}
sub img_handler
{
    my($self, $tag, $attr) = @_;
    return unless $tag eq "img";
    push(@{$self->handler("text")}, $attr->{alt} || "[IMG]");
}
sub a_end_handler
{
    my($self, $tag) = @_;
    my $text = join("", @{$self->handler("text")});
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    $text =~ s/\s+/ /g;
    #print "T $text\n";
    
    $self->handler("text", undef);
    $self->handler("start", \&a_start_handler);
    $self->handler("end", undef);
}
sub add_items
{
    #foreach my $url ( keys %bookmarks )
    #{
     #   my $text = $bookmarks{$url}{"text"};
#   $rss->add_item(
#   title       => "$url",  
#   link        => "$url",
#   description => "$text",
#   dc => {
#     subject  => "Bookmark",
#     creator  => "Created by",
#   },
# );
    #}
}
sub usage_die
{
    print STDERR "Usage: $0 bookmarks.html\n";
    exit(1);
}
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

# create a HTML::Parser object
my $p = HTML::Parser->new(api_version => 3,
        start_h => [\&a_start_handler, "self,tagname,attr"],
        report_tags => [qw(a img)],
    );
$p->parse_file(shift || usage_die) || usage_die($!);

# print RSS
if ( $OUTPUT ne "" )
{
    ## It seems that this is buggy, it prints:
    ## Wide character in print at /usr/share/perl5/XML/RSS.pm line 1606.
    # $rss->save("$OUTPUT");
    open (OUTPUT,">:utf8","$OUTPUT") || die $!;
    print OUTPUT $rss->as_string;
    close(OUTPUT);
} else {
    print STDOUT $rss->as_string;
}
