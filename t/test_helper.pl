use IPC::Open3;
use strict;
use warnings;

sub run_spec {
  my ($filename) = @_;
  local $? = 0;
  my $pid = open3(\*IN, \*OUT, \*OUT, qw(prove -v --lib), $filename);
  close(IN);
  my @lines = <OUT>;
  close(OUT);
  waitpid($pid, 0);
  return \@lines;
}

sub contains {
  my ($lines, $re, $name) = @_;
  !!grep { $_ =~ $re } @$lines;
}
1;
