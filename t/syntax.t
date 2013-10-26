use Test::Given;

my $a = 1;
my $b = 2;
my $c;
describe 'Subject Under Test' => sub {
  Given 'name' => sub { 'value' };
   And 'other' => sub { 'another value' };
   And sub { $self->{'added-given'} = 'yes' };
  When 'result' => sub { 'result' };
   And 'result2' => sub { 'result2' };
   And sub { $self->{'added-when'} = 'yes' };
  Then sub { $a == 2 };
   And sub { $a == $b };
   And sub { $self->{name} eq $b };
   And sub { $self->{other} eq 'value' };
   And sub { $self->{other} eq $self->{result} };
   And sub { use Data::Dumper; warn Dumper($self) };
};
