#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'release candidate testing only');
  }
}

use Test::More;

eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;

all_pod_files_ok(all_pod_files( 'scripts' ));
