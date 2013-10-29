package Test::Given::Check;
use strict;
use warnings;

use B::Deparse ();

sub new {
  my ($class, $sub) = @_;
  my $self = {
    sub => $sub,
  };
  bless $self, $class;
}

sub execute {
  my ($self, $exceptions) = @_;
  return 1 if !$self->{sub};

  my $rv = eval {
    $self->{sub}->($exceptions);
  };
  if ($@) {
    warn $@;
    $rv = '';
  }
  return $rv;
}

our $deparser = B::Deparse->new('-l');
sub name {
  my ($self) = @_;
  return '' if !$self->{sub};

  my @code = split( /\n/, $deparser->coderef2text($self->{sub}) );
  @code = (@code > 1) ? @code[1..$#code-1] : ();
  my ($line) = grep { !/^ *(?:package|use|#line) / } @code;
  $line =~ s/\$(\$.*?)\{/$1->\{/g;
  $line =~ s/^\s*|;$//g;
  return $line;
}

sub message {
  my ($self) = @_;
  return '' if !$self->{sub};

  my @code = split( /\n/, $deparser->coderef2text($self->{sub}) );
  @code = (@code > 1) ? @code[1..$#code-1] : ();
  @code = map {
    s/\$(\$.*?)\{/$1->\{/g;
    $_;
  } grep { !/^ *(?:package|use) / } @code;
  @code = ($code[0], grep { !/^#line/ } @code[1..$#code]);
  my $code = join("\n", @code);
  my $type = $self->type();
  return "$type: $code";
}

package Test::Given::Invariant;
use parent 'Test::Given::Check';
sub type { 'Invariant' }

package Test::Given::Then;
use parent 'Test::Given::Check';
sub type { 'Then' }

package Test::Given::And;
use parent 'Test::Given::Check';
sub type { 'And' }

package Test::Given::Test;

use Test::Given::Builder;
my $TEST_CLASS = 'Test::Given::Builder';

sub new {
  my ($class, $sub) = @_;
  my $self = {
    checks => [ Test::Given::Then->new($sub) ],
  };
  bless $self, $class;
}
sub add_check {
  my ($self) = shift;
  push @{ $self->{checks} }, Test::Given::And->new(@_);  
}
sub execute {
  my ($self, $context) = @_;
  $context->reset();
  $context->apply_givens();
  $context->apply_whens();
  my $exceptions = $context->exceptions();
  my @failed = $context->apply_invariants($exceptions);
  push @failed, grep { not $_->execute($exceptions) } @{ $self->{checks} };
  my $passed = not @failed;
  ok($passed, name($self->{checks}));
  diag(message(\@failed)) unless $passed;
  return $passed;
}

sub name {
  my ($checks) = @_;
  return $checks->[0]->name();
}

sub message {
  my ($failed) = @_;
  return join("\n\n", map { $_->message() } @$failed);
}

1;
