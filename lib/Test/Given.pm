package Test::Given;
use strict;
use warnings;
use Test::More;
use B::Deparse;
use Data::Dumper;
use PadWalker qw(set_closed_over closed_over);
#use Storable qw(dclone);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(describe context Given When Then And Invariant *self);

use version;
our $Version = '0.01';

our $self;
my @suites = ();
my $and_parent = \&Given;

my @givens = ();
my @whens = ();
my @invariants = ();

sub describe {
  my ($message, $block) = @_;
  push @suites, 1;
  $block->();
  pop @suites;
  done_testing() unless @suites;
}

sub make_given_when_block {
  my $sub = pop;
  my $name = pop;
  return sub {
    my $value = $sub->();
    $self->{$name} = $value if $name;
  };
}

sub Given {
  $and_parent = \&Given;
  push @givens, make_given_when_block(@_);
}

sub When {
  $and_parent = \&When;
  push @whens, make_given_when_block(@_);
}

sub Invariant {
  $and_parent = \&Invariant;
  push @invariants, $_[0];
}

sub Then {
  $and_parent = \&Then;
  my ($sub) = @_;
  my $tb = Test::More->builder;
  $tb->level( $tb->level() + 1 );
  my $passed = sub {
    $self = {};
    map { $_->() } @givens;
    map { $_->() } @whens;
    $sub->();
  }->();
  ok($passed, message($sub));
  $tb->level( $tb->level() - 1 );
}

sub And {
  my $tb = Test::More->builder;
  $tb->level( $tb->level() + 1 );
  $and_parent->(@_);
  $tb->level( $tb->level() - 1 );
}

my $deparser = B::Deparse->new();
sub message {
  my ($sub) = @_;

  my ($code) = $deparser->coderef2text($sub);
  $code =~ s/^\{|\n\}$//g;
  $code =~ s/\$(\$.*?)\{/$1->\{/g;

  local $Data::Dumper::Indent = 1;
  my (@vars) = split( /\n/, Dumper((closed_over($sub))[0]) );
  @vars = (@vars > 1) ? @vars[1..$#vars-1] : ();
  @vars = map { s/^  '(.*)' => \\/    $1 = /; $_ } @vars;

  $_ = $code;
  while (my ($key) = /\$self->{'(.*?)'}/) {
    s///;
    my $line = '    ' . Data::Dumper->Dump([$self->{$key}], ["self->{'$key'}"]);
    chomp($line);
    push(@vars, $line);
  }
  
  join("\n", "Then returned false:$code", "\n  Variables:", @vars, "\n  ");
}

1;
