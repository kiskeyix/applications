#!/usr/bin/perl -w
# rss2html - converts an RSS file to HTML
# It take one argument, either a file on the local system,
# or an HTTP URL like http://slashdot.org/slashdot.rdf
# by Jonathan Eisenzopf. v1.0 19990901
# See http://www.webreference.com/perl for more information

# 2003-06-30 02:16 EDT 
# modified by Luis Mondesi for the Zaurus. Now it has couple
# of features:
# 
# DESC
# 
# 1 - Output is saved to a file at  $HOME/rss2html.html
# 2 - Links are taken from a file $HOME/.rss2htmlrc. You can
#     have multiple links separated by new lines ( \n ). You
#     can also use hashes to comment out lines ( # )
# You will need to call this from the command line as:
# rss2html.pl config
#
# TODO
# * A .desktop will be included later so that Zaurus users can
#   just click on it... 
# * A way to parse files which end in .html (not rss or rdf)
#   so that users can put links to sites that don't provide
#   nice rss/rdf channels ... (nytimes?)
# 
# NOTE
# A convenient thing is to just make your $HOME/rss2html.html 
# file your home page for your browser in the Zaurus :-)
#

# INCLUDES
use strict;
use XML::RSS;
use LWP::Simple;

# Declare variables
my $content;
my $file;
# luis 2003-06-29 13:47
# Let's get our links from this file:
# this file is composed of a link per line
# like:
# http://www.server.com/rdf.rdf
# http://www.otherserver.com/rss.rss
# # this is a comment
# 
my $config_file = $ENV{'HOME'}."/.rss2htmlrc";
# information will be outputted to this file
my $output_file = $ENV{'HOME'}."/rss2html.html";

# MAIN
# check for command-line argument
die "Usage: rss2html.pl (<RSS file> | <URL> | config )\n" unless @ARGV == 1;

# get the command-line argument
my $arg = shift;

# create new instance of XML::RSS
my $rss = new XML::RSS;

# argument is a URL
if ($arg=~ /http:/i) {
    $content = get($arg);
    die "Could not retrieve $arg" unless $content;
    # parse the RSS content
    $rss->parse($content);
    
    # clear up output file
    open(HTMLF, "> $output_file");
    close(HTMLF);
    
    # print the HTML channel
    &print_html($rss);

# parse a configuration file
} elsif ($arg eq "config") {
    # config file is just a list of URLs, therefore 
    if (open(CONFIG, "< $config_file")){
        # possibly a bug, but, this is the best places to
        # clean up this file:
        # clear up output file
        open(HTMLF, "> $output_file");
        close(HTMLF);

        while (<CONFIG>) {
            # comments are allowed in the configuration file
            next if /^\s*#/;
            chomp;
            if ($_ =~ /http:/i) {
                $content = get($_);
                die "Could not retrieve $_" unless $content;
                # parse the RSS content
                $rss->parse($content);

                # print (append) the HTML channel
                &print_html($rss);

            } #end if http
        } #end while
        
        close(CONFIG);

    } #end if
# argument is a file
} else {
    $file = $arg;
    die "File \"$file\" does't exist.\n" unless -e $file;
    # parse the RSS file
    $rss->parsefile($file);
    # clear up output file
    open(HTMLF, "> $output_file");
    close(HTMLF);

    # print the HTML channel
    &print_html($rss);

}

# SUBROUTINES
sub print_html {
    my $rss = shift;

    if (open(HTMLF, ">> $output_file")) {

        print HTMLF <<HTML;
<HTML>
<head>
    <title>RSS Feeds Parser:</title>
</head>
<body bgcolor="white">
<table bgcolor="#000000" border="0" width="200"><tr><td>
<TABLE CELLSPACING="1" CELLPADDING="4" BGCOLOR="#FFFFFF" BORDER=0 width="100%">
  <tr>
  <td valign="middle" align="center" bgcolor="#EEEEEE"><font color="#000000" face="Arial,Helvetica"><B><a href="$rss->{'channel'}->{'link'}">$rss->{'channel'}->{'title'}</a></B></font></td></tr>
<tr><td>
HTML

        # print channel image
        if ($rss->{'image'}->{'link'}) {
            print HTMLF <<HTML;
<center>
<p><a href="$rss->{'image'}->{'link'}">
<img src="$rss->{'image'}->{'url'}" alt="$rss->{'image'}->{'title'}" border="0"
HTML
            print HTMLF " width=\"$rss->{'image'}->{'width'}\""
            if $rss->{'image'}->{'width'};
            print HTMLF " height=\"$rss->{'image'}->{'height'}\""
            if $rss->{'image'}->{'height'};
            print HTMLF "></a></center><p>\n";
        } #end if rss

        # print the channel items
        foreach my $item (@{$rss->{'items'}}) {
            next unless defined($item->{'title'}) && defined($item->{'link'});
            print HTMLF "<li><a href=\"$item->{'link'}\">$item->{'title'}</a><BR>\n";
            # luis 2003-06-29 13:37 
            # in addition, I care about the actual text
            print HTMLF "$item->{'description'}</li><BR>\n" if defined ($item->{'description'});
        } # end foreach

        # if there's a textinput element
        if ($rss->{'textinput'}->{'title'}) {
            print HTMLF <<HTML;
<form method="get" action="$rss->{'textinput'}->{'link'}">
$rss->{'textinput'}->{'description'}<BR> 
<input type="text" name="$rss->{'textinput'}->{'name'}"><BR>
<input type="submit" value="$rss->{'textinput'}->{'title'}">
</form>
HTML
        } #end if rss

        # if there's a copyright element
        if ($rss->{'channel'}->{'copyright'}) {
            print HTMLF <<HTML;
<p><sub>$rss->{'channel'}->{'copyright'}</sub></p>
HTML
        } # end if rss

    print HTMLF <<HTML;
</td>
</TR>
</TABLE>
</td></tr></table>
</body></html>
HTML
    } #end if open
} #end function


