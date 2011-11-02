#!perl
use strict;
use warnings;

# skip on windows
use Test::More tests => 2;

{
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $c = qx{ $^X scripts/perlall help 2>&1 };
  like( $c, qr/^Available Commands:/m, "help" );
  $c = qx{ $^X scripts/perlall -v help 2>&1 };
  like( $c, qr/CONFIGURATION/m, "-v help" );
}
