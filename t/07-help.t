#!perl
use strict;
use warnings;

use Test::More tests => 4;

SKIP: {
  skip "no simple 2>&1 on $^O", 3 if $^O eq 'MSWin32';

  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  my $redir = '2>&1' if $^O ne 'MSWin32';

  my $c = qx{ $X script/perlall help $redir };
  like( $c, qr/^Available Commands:/m, "help" );

  $c = qx{ $X script/perlall --help $redir };
  like( $c, qr/^Available Commands:/m, "--help" );

 TODO: {
    local $TODO = 'Pod::Usage fails to page on some debian boxes' if $^O eq 'linux';
    $c = qx{ $X script/perlall -v help $redir };
    like( $c, qr/This is shell-script syntax with ENV vars/m, "-v help" );
    $c = qx{ $X script/perlall -v --help $redir };
    like( $c, qr/This is shell-script syntax with ENV vars/m, "-v --help" );
  }
}
