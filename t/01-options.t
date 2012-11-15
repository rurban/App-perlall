#!perl
use strict;
use warnings;

use Test::More tests => 3;

{
  my $c;
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  #my $c = qx{ HARNESS_ACTIVE=1 $X script/perlall --dryrun --skip='5.12*' list };
  #like( $c, qr/perl5.15.4\@ababab\n.*?perl5.12.1-nt\n.*?perl5.8.9d$/m, "skip 5.12*" );

  $c = qx{ HARNESS_ACTIVE=1 $X script/perlall --dryrun --nogit list };
  like( $c, qr/perl5\.14\.2\n.*?perl5\.12\.1-nt\n.*?perl5\.8\.9d$/, "--nogit" );

  $c = qx{ HARNESS_ACTIVE=1 $X script/perlall --dryrun --older=5.12 list };
  like( $c, qr/perl5\.8\.9d$/, "--older" );

  $c = qx{ HARNESS_ACTIVE=1 $X script/perlall --dryrun --newer=5.12.1 list };
  like( $c, qr/perl5.15.4\@ababab\n.*?perl5\.14\.2\n.*?perl5\.12\.1-nt$/, "--older" );
}
