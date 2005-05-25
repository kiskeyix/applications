#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: simple way to generate user info to copy+paste in a etc/passwd and etc/shadow file
# USAGE: $0 username password
# LICENSE: GPL

use strict;
$|++;

my $revision = "1.0"; # version

# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');

# Args:
my $PVERSION=0;
my $HELP=0;
my $DEBUG=0;
my $UNAME=undef;
my $PASSWD=undef;
# get options
GetOptions(
    # flags
    'v|version'         =>  \$PVERSION,
    'h|help'            =>  \$HELP,
    'D|debug'           =>  \$DEBUG,
    # strings
    #'o|option=s'       =>  \$NEW_OPTION,
    # numbers
    #'a|another-option=i'      =>  \$NEW_ANOTHER_OPTION,
) and $UNAME=shift and $PASSWD=shift;

if ( $HELP or !defined($UNAME) or !defined($PASSWD) ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file("$0",\*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }

my @uid = (0..64534); # range of all UID we allow
my $UID = int(1000 + rand(@uid)); # minimun UID allowed is 1000

print STDOUT ("===passwd file===\n");
print STDOUT ($UNAME,":x:",$UID,":100::/home/",$UNAME,":/bin/sh","\n");
print STDOUT ("===shadow file===\n");
# generates a MD5 password salted with 8 random chars
print STDOUT ($UNAME,":",crypt($PASSWD,"\$1\$".gensalt(8)."\$"),":12921:0:99999:7:::","\n");

sub gensalt {
    my $count = shift;
    my @salt = ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
    my $_salt = undef;
    for (1..$count) {
        $_salt .= (@salt)[rand(@salt)];
    }
    return $_salt;
}

__END__

=head1 NAME

adduser-passwd.pl - Luis Mondesi <lemsx1@gmail.com>

=head1 SYNOPSIS

B<adduser-passwd.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                username
                password

=head1 DESCRIPTION 

    This script generates user information for a passwd and shadow files. Password uses MD5 scheme with 8 char salt

=head1 OPTIONS

=over 8

=item -v,--version

prints version and exits

=item -D,--debug

enables debug mode

=item -h,--help

prints this help and exits

=cut

