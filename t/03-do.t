#!perl
use strict;
use warnings;

use Test::More tests => 4;

{
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  my $c = qx{ $X scripts/perlall -d -v --dryrun do -Mstrict -e1};
  like( $c, qr/^\[debug\]   executing 'do'/m, "cmd=do" );
  like( $c, qr/received options: -d -v --dryrun/m, "options" );
  like( $c, qr/received parameters: -Mstrict -e1/m, "params" );
 TODO: {
    local $TODO = "need to keep quotes in params";
    $c = qx{ $X scripts/perlall -d -v --dryrun do "perl5.14.2*" -Mblib -e'my \$a=0' };
    like( $c, qr/received parameters: perl5.14.2\* -Mblib -e'my \$a=0'/m,
	  "keep quotes in params" );
  }
}
