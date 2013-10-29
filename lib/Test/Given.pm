package Test::Given;
use strict;
use warnings;

use Test::Given::Context;
use Test::Given::Builder;

BEGIN {
  require Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(describe context Given When Then And Invariant onDone has_failed);
}

use version;
our $Version = '0.03';

my $context = Test::Given::Context->new('** TOPLEVEL **');
sub describe {
  my ($description, $sub) = @_;
  $context = $context->add_context($description);
  $sub->();
  $context = $context->parent();
}
*context = \&describe;

sub Given     { $context->add_given(@_) }
sub When      { $context->add_when(@_) }
sub Invariant { $context->add_invariant(@_) }
sub Then      { $context->add_then(@_) }
sub onDone    { $context->add_done(@_) }
sub And       { $context->add_and(@_) }

sub has_failed {
  my ($exceptions, $re) = @_;
  return '' unless $exceptions and $re;
  grep { $_ =~ $re } @$exceptions;
}

END {
  plan(tests => $context->test_count());
  $context->run_tests();
}

1;
