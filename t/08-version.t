#!perl
use strict;
use warnings;

# skip on windows
use Test::More tests => 1;

{
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $c = qx{ $^X scripts/perlall version };
  like( $c, qr/^perlall \d\.\d/m, "version" );
}
