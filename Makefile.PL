use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Test with all perls",
  "AUTHOR" => "Reini Urban <rurban\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-perlall",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "App::perlall",
  "PREREQ_PM" =>  {
		   App::Rad => "1.04",
		   Pod::Usage => 0,
		   File::Basename => 0,
		   File::Slurp => 0,
		   Cwd => 0,
		   Devel::PatchPerl => "0.46",
		   File::Path => "2.07",
		   Getopt::Long => "2.36",
  },
  VERSION_FROM => "scripts/perlall.pl",
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
