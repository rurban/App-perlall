#!perl
use strict;
use warnings;

use Test::More tests => 3;

{
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  unlink 'perlall-make' if -e 'perlall-make';
  system(qw(ln -s script/perlall perlall-make));
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $c = qx{ HARNESS_ACTIVE=1 $X perlall-make -d -v --dryrun '5.14.2*' };
  like( $c, qr/^\[debug\]   executing 'make'/m, "cmd=make" );
  like( $c, qr/received options: -d -v --dryrun/m, "options" );
  # be sure that it is not "make 5.14.2*"
  like( $c, qr/received parameters: 5\.14\.2\*/m, "params" );
  unlink 'perlall-make';
}
