#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: A simple package that exports ...
# CONVENTIONS:
#               - functions starting with underscores (_) are local,
#                 private to this module
#               - functions starting with c_ at like setters/getters
#                 for our configurable properties
# LICENSE: GPL

=pod

=head1 NAME

skeleton.pm - skeleton module 

=head1 SYNOPSIS

use skeleton;
my $foo = skeleton->new('skeleton' => 1, 'debug' => 0);

$foo->foo("hello world");

=head1 DESCRIPTION 

This module ...

=head1 FUNCTIONS

=over 8

=cut

package skeleton;
require Exporter;
use Carp;    # croak() cluck() carp()

@ISA    = qw(Exporter);
@EXPORT = qw($skeleton foo);

# Allows variables to be exporter one level up. they will be treated
# as "globals"
sub import
{
    $skeleton = 0;
    skeleton->export_to_level(1, @_);
}

=pod

=item new()

@desc allows new objects to be created and blessed. this allows for inheritance

@arg anonymous hash. Possible values:
     
     skeleton => "" # optional

@return blessed object

=cut

sub new
{
    my $self   = shift;
    my $class  = ref($self) || $self;    # works for Objects or class name
    my $object = {@_};                   # remaining args are attributes
    bless $object, $class;

    $object->_define();                  # initialize internal variables

    return $object;
}

=pod

=item _define() [PRIVATE]

@desc internal function to setup our anonymous hash

@arg object/hash with values to initialize private hash with defaults

=cut

sub _define
{
    my $self = shift;
    unless (exists $self->{'skeleton'})
    {
        $self->{'skeleton'} = 1;
    }
    $skeleton = $self->{'skeleton'};
    
    # here we should call _define() from e/a of the classes we imported @ISA
    for my $class ( @ISA )
    {
        my $meth = $class."::_define";
        $self->$meth(@_) if $class->can("_define");
    }
}

=pod

=item c_skeleton_option()

@desc setter/getter for our configuration option skeleton. configuration function to set hash variables or get their current value

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current table

=cut

sub c_skeleton_option
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    return undef if (not ref $self or not defined $key);

    $self->{$key} = $value if (defined($value) and $value !~ /^\s*$/);

    # we return the current value of our variable regardless
    # of whether we changed it or not
    return $self->{$key};
}

=pod 

=item foo()

@desc a simple function to print a string

@param $str string to print

@return undef if argument is missing

=cut

sub foo
{
    my $self = shift;
    my $str  = shift;
    return undef if (not ref $self);
    print STDOUT $str;
}

=pod

=back

=head1 AUTHOR

Luis Mondesi <lemsx1@gmail.com>

=cut

1;
