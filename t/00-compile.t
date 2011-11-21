#!perl

use strict;
use warnings;

use Test::More;

use File::Find;
use File::Temp qw{ tempdir };

my @modules;
find(
  sub {
    return if $File::Find::name !~ /\.pm\z/;
    my $found = $File::Find::name;
    $found =~ s{^lib/}{};
    $found =~ s{[/\\]}{::}g;
    $found =~ s/\.pm$//;
    # nothing to skip
    push @modules, $found;
  },
  'lib',
) if -d "lib";

sub _find_scripts {
    my $dir = shift @_;

    my @found_scripts = ();
    find(
      sub {
        return unless -f;
        return if /~$/;
        my $found = $File::Find::name;
        # nothing to skip
        open my $FH, '<', $_ or do {
          note( "Unable to open $found in ( $! ), skipping" );
          return;
        };
        my $shebang = <$FH>;
        return unless $shebang =~ /^#!.*?\bperl\b\s*$/;
        push @found_scripts, $found;
      },
      $dir,
    );

    return @found_scripts;
}

my @scripts;
do { push @scripts, _find_scripts($_) if -d $_ }
    for qw{ bin script scripts };

my $plan = scalar(@modules) + scalar(@scripts);
$plan ? (plan tests => $plan) : (plan skip_all => "no tests to run");

{
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  # fake home for cpan-testers
  # no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
  for (sort @modules) {
    my $c = -d "lib"
      ? qq( $X -Ilib -e "require $_; print '$_ ok'")
      : qq( $X -e "require $_; print '$_ ok'");
    like( qx{ $c }, qr/^\s*$_ ok/s, "$_ loaded ok" )
  }

 SKIP: {
    eval "use Test::Script 1.05; 1;";
    skip "Test::Script needed to test script compilation", scalar(@scripts) if $@;
    foreach my $file ( @scripts ) {
      my $script = $file;
      $script =~ s!.*/!!;
      script_compiles( $file, "$script script compiles" );
    }
  }
}
