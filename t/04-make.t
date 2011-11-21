#!perl
use strict;
use warnings;

use Test::More tests => 3;

{
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  my $c = qx{ $X scripts/perlall -d -v --dryrun make "perl5.14.2*" -Mblib -e'my \$a=0' };
  like( $c, qr/^\[debug\]   executing 'make'/m, "cmd=make" );
  like( $c, qr/received options: -d -v --dryrun/m, "options" );
 TODO: {
    local $TODO = "need to keep quotes in params";
    like( $c, qr/received parameters: perl5.14.2\* -Mblib -e'my \$a=0'/m,
	  "keep quotes in params" );
  }
}
