#!perl
use strict;
use warnings;

use Test::More tests => 3;

{
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  my $c = qx{ $X script/perlall -d -v --dryrun init perl5.15.4 };
  like( $c, qr/^\[debug\]   executing 'init'/m, "cmd=init" );
  like( $c, qr/received options: -d -v --dryrun/m, "options" );
  like( $c, qr/received parameters: perl5.15.4/m, "params" );
}
