#!perl
use strict;
use warnings;

use Test::More tests => 3;

{
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $c = qx{ $^X scripts/perlall -d -v --dryrun build 5.15.4 blead };
  like( $c, qr/^\[debug\]   executing 'build'/m, "cmd=build" );
  like( $c, qr/received options: -d -v --dryrun/m, "options" );
  like( $c, qr/received parameters: 5.15.4 blead/m, "params" );
  # if $perl-git/.git exists check more
}
