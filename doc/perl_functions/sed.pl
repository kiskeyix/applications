#!/usr/bin/perl -w
# $Revision: 1.1 $
# $Date: 2007-05-03 20:22:45 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION:
# USAGE:
# LICENSE: ___

=pod

=head1 NAME

skeleton.pl - skeleton script for Perl

=head1 DESCRIPTION 

    This script ...

=cut

use strict;
$|++;

while(<>)
{
    eval shift;
    die $@ if $@;

    print;
}

=pod

=head1 AUTHORS

Luis Mondesi < lemsx1@gmail.com >

=cut


