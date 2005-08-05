#!/usr/bin/perl -w
# $Revision: 1.2 $
# $Date: 2005-08-05 16:50:09 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A simple script to run tripwire interactively, and email the tripwire file and md5sum to a given email when done
# USAGE: $0
# LICENSE: GPL

use strict;
$|++;

my $revision = "1.0"; # version

# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');
use POSIX;                  # cwd() ... man POSIX
use File::Spec::Functions;  # abs2rel() and other dir/filename specific
use File::Copy;
use File::Find;     # find();
use File::Basename; # basename() && dirname()
use FileHandle;     # for progressbar

#eval "use My::Module";
#if ($@) 
#{
#    print STDERR "\nERROR: Could not load the Image::Magick module.\n" .
#    "       To install this module use:\n".
#    "       Use: perl -e shell -MCPAN to install it.\n".
#    "       On Debian just: apt-get install perlmagic \n\n".
#    "       FALLING BACK to 'convert'\n\n";
#    print STDERR "$@\n";
#    exit 1;
#}

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;
my $SKIP_TRIPWIRE=0; # should we skip running tripwire and just email the db
my $_EMAIL=undef;
# get options
GetOptions(
    # flags
    'v|version'         =>  \$PVERSION,
    'h|help'            =>  \$HELP,
    'D|debug'           =>  \$DEBUG,
    's|skip'            =>  \$SKIP_TRIPWIRE,
    # strings
    'e|email=s'         =>  \$_EMAIL,
    # numbers
    #'a|another-option=i'      =>  \$NEW_ANOTHER_OPTION,
);

if ( $HELP ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file($0,\*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }
# sanity checks
my $UID = $<;
die ( "You must run this as root\n" ) if ( $UID != 0 );

# globals
my $config = undef;
if ( -r "$ENV{'HOME'}/.signaturerc" )
{
    my @files = ("$ENV{'HOME'}/.signaturerc"); 
    $config = parse_ini(\@files);
}

my $HOSTNAME = qx/hostname/;

chomp($HOSTNAME);
chomp($UID);

my $TRIPWIRE = "tripwire --check -I"; # interactive check
my $TRIPWIREDB = "/var/lib/tripwire/$HOSTNAME.twd";
my $HASH = "md5sum";
my $SUBJECT = "$HASH: $HOSTNAME triwire";
my $MUA = "mutt";
my $EMAIL = undef;
if ( defined($_EMAIL) )
{
    $EMAIL=$_EMAIL;
} elsif ( defined($config) and exists($config->{'default'}{'EMAIL'}) ) {
    $EMAIL=$config->{'default'}{'EMAIL'};
    $EMAIL=~s/("|')//g; # sanity check
} else {
    $EMAIL="lemsx1\@gmail.com";
}

system($TRIPWIRE) unless ( $SKIP_TRIPWIRE ); # TODO is command in our path and we can execute it?
# Note, it seems that tripwire doesn't return 0 when successfully done,
# causing the following check to fail. I'm commenting it out - lemsx1
#if ( $? == 0 )
#{
    print STDERR "$HASH '$TRIPWIREDB' | $MUA -a '$TRIPWIREDB' -s '$SUBJECT' $EMAIL\n" 
        if ( $DEBUG );
    system("$HASH '$TRIPWIREDB' | $MUA -a '$TRIPWIREDB' -s '$SUBJECT' $EMAIL");
    if ( $? == 0 )
    {
        print STDOUT ( "$HASH and '$TRIPWIREDB' emailed successfully to $EMAIL\n" );
    }
#} else {
#    print STDERR ("$TRIPWIRE failed! No emails were sent\n");
#}

=pod

=item write_ini()

@desc a simple function to write a hash of hashes to a text file in DOS INI format:

$_->{"foo"}{"bar"} = $value;

becomes

[foo]

bar = $value

@param $file file name to write 

@param $hashref hash of hashes containing what to write

@param $truncate whether we want to truncate existing files or not

@return

=cut 

sub write_ini
{
    my $file = shift;
    my $hashref = shift;
    my $truncate = shift;
    die("DNC::write_ini failed!\n Make sure that the file we are trying to write doesn't exist") 
    if ( (defined ($file) and -f $file) and (defined ($truncate) and $truncate != 1) );
    open(INI, "> $file") || die "Could not write $file. Check permissions? $!\n";
    foreach my $key ( keys %{$hashref} ) {
        print INI ("[$key]\n");
        foreach my $subkey ( keys %{$hashref->{$key}} ) {
            print INI
            ("$subkey=" . $hashref->{$key}{$subkey}."\n");
        }
    }
    close(INI);
} # end write_config

=pod

=item parse_ini()

@desc parses an INI file in the form:

[SECTION]

VAR = VALUE

FOO = BAR

@param $files arrayref of config files to parse

@return hashref of hash of hashes in the form $_->{$SECTION}{$VAR} = $VALUE

=cut

sub parse_ini {
    my $files = shift;

    # default section is "default"
    my $section="default";
    my %config=();
    my $line=undef;

    die ( "No INI file to parse\n" ) if ( not defined ($files) );

    foreach my $file ( @$files )
    {
        $section="default"; # reset section name for e/a file
        if ( -f $file )
        {
            open(CONFIG, "<$file");
            # suppress warnings for now... 
            no warnings; 
            while ( defined($line = <CONFIG>) ) {
                next if ( $line =~ m/^\s*#/ or $line =~ m/^\s*$/ ); # skip comments and blank lines
                chomp $line;
                #chop off comments after strings
                $line =~ s/#.*//g;

                # attempts to be forgiven about backslashes
                # to break lines that continues over
                # multiple lines
                if ($line =~ s/\\$//) {
                    $line .= <CONFIG>;
                    redo unless eof(CONFIG);
                }
                # get section name if we find one
                if ( $line =~ m/\[([0-9a-zA-Z]+)\]/i )
                {
                    $section = $1;
                }
                $line =~ s/\s*=\s*/=/g; # remove spaces before and after the = sign
                $config{$section}{$1} = $2 if ( $line =~ m,^\s*([^=]+)=(.+), );
                $config{$section}{$1} =~ s/["']//g; # get rid of quotes
            }
            close(CONFIG);
        } 
    } # ends foreach
    if ( $DEBUG )
    {
        use Data::Dumper;
        print Dumper(\%config);
    }
    return \%config;
} # end init_config

__END__

=head1 NAME

tripwire.pl - tripwire script for Perl

=head1 SYNOPSIS

B<tripwire.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                [-s,--skip]
                [-e,--email]

=head1 DESCRIPTION 

    This script runs tripwire interactively. Then emails the md5sum of the tripwire database along with a copy of the database to an external email address.

=head1 OPTIONS

=over 8

=item -v,--version

prints version and exits

=item -D,--debug

enables debug mode

=item -h,--help

prints this help and exits

=item -s,--skip

skip tripwire checks and simply email the database and hash to our email address

=item -e,--email

E-Mail address to send the files to. If not passed from the command line, it will be read from ~/.signaturerc or default to lemsx1@gmail.com otherwise. 

The format of .signaturerc is the same as the one of my bashrc.tar.bz2 package. Read ~/.bashrc and ~/.bash_profile for more.

EMAIL=lemsx1@gmail.com

=back

=head1 AUTHOR

Luis Mondesi <lemsx1@gmail.com>

=cut

