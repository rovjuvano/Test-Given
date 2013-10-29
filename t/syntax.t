package myp;
use Test::Given;
use strict;
use warnings;

use Data::Dumper;

our ($name, $other, @array, %hash, $subject, $result, $result2, $self);
my $a = 1;
my $b = 2;
my $c;
Given 'result' => sub { 'subject' };
When 'subject' => sub { 'result' };
Invariant sub { exists $self->{'added-given'} };
Then sub { $result eq $subject };
describe 'Subject Under Test' => sub {
  Given name => sub { 'value' };
  Given other => sub { 'another value' };
  And sub { $self->{'added-given'} = 'yes' };
  context 'Outer1' => sub {
    Given name => sub { 'outer value' };
    When result => sub { 'outer ' . $result };
    Then sub { $name eq 'outer value' };
    And sub { $result eq 'outer something' };
    And sub { $name eq 'outer1' };
  };
  Given '@array' => sub { (1, 2, 3) };
  Given '%hash' => sub { (a => 1, b => 2) };
  Given '&func' => sub { sub { 'hi' } };
  When result => sub { 'something' };
  When '$result2' => sub { 'something2' };
  context 'Outer2' => sub {
    Given name => sub { 'outer value' };
    When result => sub { 'outer ' . $result };
    context 'Inner' => sub {
      Given name => sub { 'inner value' };
      When result => sub { 'inner ' . $result };
      Then sub { $name eq 'inner value' };
      And sub { $result eq 'inner something' };
      And sub { $name eq 'inner' };
    };
    Then sub { $name eq 'outer value' };
    And sub { $result eq 'outer something' };
    And sub { $name eq 'outer2' };
  };
  And sub { $self->{'added-when'} = 'yes' };
  Invariant sub { $a == 2 };
  And sub { $a == $b };
  Then sub { $name eq 'value' };
  And sub { $other eq 'another value' };
  context 'Outer3' => sub {
    Given name => sub { 'outer value' };
    When result => sub { 'outer ' . $result };
    Then sub { $name eq 'outer value' };
    And sub { $result eq 'outer something' };
    And sub { $name eq 'outer3' };
  };
  And sub { not exists $self->{other} };
  onDone sub { print '-'x80, "\n" };
  onDone sub { warn Dumper(\@array, \%hash, \&func) };
};
describe 'Another Under Test' => sub {
  Given name => sub { 'another value' };
  When result => sub { 'another ' . $result };
  Then sub {
    my $a = "multi-line test";
    $result eq 'another ';
  };
  And sub { $name eq 'another' };
  Then sub { $name eq 'another value' };
  And sub { $result eq 'another yowza' };
  onDone sub { print '-'x80, "\n" };
};
describe 'Exceptions' => sub {
  When die_hard => sub { die 'hard' };
  Then sub { has_failed(shift, qr/hard/) };
  And sub { has_failed(shift, qr/easy/) };

  context 'Sequel' => sub {
    When vengeance => sub { die 'with a vengeance' };
    Then sub { has_failed(shift, qr/hard/) };
    And  sub { has_failed(shift, qr/vengeance/) };
  };
  onDone sub { print '-'x80, "\n" };
};
describe 'Then-less', sub {
  context 'Outer Then-less', sub {
    Given subject => sub { 'subject' };
    Invariant sub { $subject eq 'subject' };
    Then sub { $subject eq 'result' };
    context 'Inner Then-less', sub {};
  };
  onDone sub { print '-'x80, "\n" };
};
describe 'Locals' => sub {
  Then sub { "self is still defined" };
};
onDone sub { print "That's all folks\n" };
