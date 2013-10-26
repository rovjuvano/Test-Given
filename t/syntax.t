package myp;
use Test::Given;
use strict;
use warnings;

our ($name, $other, @array, %hash, $result, $result2, $self);
my $a = 1;
my $b = 2;
my $c;
describe 'Subject Under Test' => sub {
  Given name => sub { 'value' };
   And other => sub { 'another value' };
   And sub { $self->{'added-given'} = 'yes' };
   And '@array' => sub { (1, 2, 3) };
   And '%hash' => sub { (a => 1, b => 2) };
   And '&func' => sub { sub { 'hi' } };
  When result => sub { 'something' };
   And '$result2' => sub { 'something2' };
   And sub { $self->{'added-when'} = 'yes' };
  Then sub { $a == 2 };
   And sub { $a == $b };
   And sub { $name eq 'value' };
   And sub { $other eq 'another value' };
   And sub { $self->{other} eq $result };
   And sub { use Data::Dumper; warn Dumper(\@array, \%hash, \&func) };
};
