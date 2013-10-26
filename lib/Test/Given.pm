package Test::Given;
use strict;
use warnings;
use Test::More qw();
use B::Deparse ();
use PadWalker qw(closed_over);
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(describe context Given When Then And Invariant);

use version;
our $Version = '0.02';

my @suites = ();
my $and_parent = \&Given;
our $package;
my $context_vars = {};

my @givens = ();
my @whens = ();
my @invariants = ();

sub describe {
  my ($message, $block) = @_;
  push @suites, 1;
  $block->();
  pop @suites;
  Test::More::done_testing() unless @suites;
}

sub make_given_when_block {
  my $sub = pop;
  my $name = pop;
  if ( defined $name ) {
    my $package = "${package}::";
    if ( $name =~ s/^\@// ) {
      return sub {
        define_var($package, $name, [ $sub->() ]);
      }
    }
    elsif ( $name =~ s/^\%// ) {
      return sub {
        define_var($package, $name, { $sub->() });
      }
    }
    elsif ( $name =~ s/^\&// ) {
      return sub {
        define_var($package, $name, $sub->());
      }
    }
    $name =~ s/^\$//;
    return sub {
      define_var($package, $name, \$sub->());
    }
  }
  return sub { $sub->() }
}

sub Given {
  $and_parent = \&Given;
  local ($package) = $package || (caller);
  push @givens, make_given_when_block(@_);
}

sub When {
  $and_parent = \&When;
  local ($package) = $package || (caller);
  push @whens, make_given_when_block(@_);
}

sub Invariant {
  $and_parent = \&Invariant;
  push @invariants, $_[0];
}

sub call_sub { $_[0]->() }
sub Then {
  $and_parent = \&Then;
  my ($sub) = @_;
  reset_context();
  map { call_sub($_) } @givens;
  map { call_sub($_) } @whens;
  my $passed = eval { call_sub($sub); };
  $passed = '' if $@;
  my $tb = Test::More->builder;
  $tb->level( $tb->level() + 1 );
  Test::More::ok($passed, message($sub));
  $tb->level( $tb->level() - 1 );
}

sub And {
  local ($package) = (caller);
  my $tb = Test::More->builder;
  $tb->level( $tb->level() + 1 );
  $and_parent->(@_);
  $tb->level( $tb->level() - 1 );
}

my $deparser = B::Deparse->new();
sub message {
  my ($sub) = @_;

  my $message = "Then returned false:\n";

  my @code = split( /\n/, $deparser->coderef2text($sub) );
  @code = (@code > 1) ? @code[1..$#code-1] : ();
  @code = map {
    s/\$(\$.*?)\{/$1->\{/g;
    $_;
  } grep { !/^ *(?:package|use) / } @code;

  $message .= join("\n", @code);

  local $Data::Dumper::Indent = 1;
  my (@vars) = split( /\n/, Dumper((closed_over($sub))[0]) );
  @vars = (@vars > 1) ? @vars[1..$#vars-1] : ();
  @vars = map { s/^  '(.*)' => \\/    $1 = /; $_ } @vars;
  $message .= join("\n", "\n\n Variables:", @vars);

#  $_ = $code;
#  while (my ($key) = /\$self->{'(.*?)'}/) {
#    s///;
#    my $line = '    ' . Data::Dumper->Dump([$self->{$key}], ["self->{'$key'}"]);
#    chomp($line);
#    push(@vars, $line);
#  }

  return $message;
}

sub reset_context {
  foreach my $package (keys %$context_vars) {
    no strict 'refs';
    my $sym_tab = *{$package}{HASH};
    foreach my $name (keys %{ $context_vars->{$package}}) {
      undef *{$package . $name};
    }
  }
}

sub define_var {
  my ($package, $name, $value) = @_;
  return unless $name;
  $context_vars->{$package}->{$name} = $value;
  no strict 'refs';
  *{$package . $name} = $value;
}

sub dump_symbol_table {
  my ($table) = @_;
  my %h;
  no strict 'refs';
  foreach my $key (keys %$table) {
    $h{$key} = {};
    my $v = *{ $table->{$key} }{SCALAR};
    $h{$key}->{SCALAR} = $v if defined $$v;
    map {
      my $v = *{ $table->{$key} }{$_};
      $h{$key}->{$_} = $v if defined $v;
    } qw(ARRAY HASH CODE FORMAT IO);
  }
  use strict 'refs';
  warn Data::Dumper->new([\%h])->Deepcopy(1)->Sortkeys(1)->Dump();
}

1;
