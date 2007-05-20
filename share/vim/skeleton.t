#!/usr/bin/perl -w
# $Revision: 1.2 $
# my_name < email@example.com >
#
# DESCRIPTION: A simple test script
# Use this to test skeleton.pm API
# USAGE: ./skeleton.t
# LICENSE: GPL

#use lib '.';
use Test::More no_plan;

use skeleton qw(:all);

my $obj = skeleton->new('dummy' => 'dummy_value');
ok(defined $obj, 'skeleton->new()');

# test default value for skeleton key
is($obj->get_option('skeleton'), 1, 'default value for skeleton worked');

# create a new hash key
is($obj->{'dummy'}, 'dummy_value', "dummy == dummy_value");

# test wrappers for config API
ok($obj->set_option('skeleton', 2), 'setter worked');
is($obj->get_option('skeleton'), 2, 'getter worked');

# test without wrapper
is($obj->skeleton_option('skeleton', 3), 3, 'setter/getter worked');

is($obj->foo(), undef, 'foo() returns undef');
ok($obj->foo("Hello World!\n"), 'foo() prints "Hello World!"');
