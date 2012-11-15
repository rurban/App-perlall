#!perl
use strict;
use warnings;

use Test::More tests => 1;

{
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $c = qx{ $X script/perlall version };
  like( $c, qr/^perlall \d\.\d/m, "version" );
}
