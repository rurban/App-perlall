use strict;
use warnings;

use ExtUtils::MakeMaker 6.17; # perl-5.6.2
use Config;

die "unsupported OS $^O" # fixes welcome
  if $^O =~ /^vms|dos|bsdos$/;
die "$^O not yet fully supported\n" # fixes welcome
  if $^O =~ /^MSWin32|msys/;
die "Empty SHELL\n" # fail cpantesters
  unless $ENV{SHELL};

my %WriteMakefileArgs =
  (
   "NAME" => "App::perlall",
   "VERSION_FROM" => "script/perlall",
   "ABSTRACT" => "Build, test and do with all perls",
   "AUTHOR" => "Reini Urban <rurban\@cpanel.net>",
   "LICENSE" => "perl",
   'EXE_FILES'  => ['script/perlall'],
   "PREREQ_PM" =>  {
		    'App::Rad'     => "1.04",
		    'Devel::Platform::Info' => '0',
		    'Devel::PatchPerl' => "0.46",
		    'IO::Scalar'   => '0',
		    # in core:
		    'IPC::Cmd'     => '0.46', # in core since 5.10
		    'IPC::Open3'   => '0',
		    'Pod::Usage'   => "1.33",
		    'File::Basename' => "2.74",
		    'Cwd'          => "3.30",
		    'File::Path'   => "1.08",
		    'Getopt::Long' => "2.36",
		   },
   "SIGN" => 1,
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  =>
     {
      recommends =>
      {
       'File::Slurp' => "9999.13", # with B::C only
      },
      no_index =>
      {
	package     => 'B',
      },
      resources =>
      {
	license     => 'http://dev.perl.org/licenses/',
	bugtracker  => 'RT',
	repository  => 'git://github.com/rurban/App-perlall.git',
      }}) : ()),
  );

WriteMakefile(%WriteMakefileArgs);

if (! -f "$ENV{HOME}/.perlall") {
    my $cp = $Config{cp};
    system($cp, ".perlall", "$ENV{HOME}/.perlall");
    print <<INSTRUCTION;
Configuration in shell-syntax at ~/.perlall

You might want to add this to the end of your ~/.profile for
handy 'p', 'pm', 'mt', 'perl-git' and more aliases:

test -f ~/.perlall && . ~/.perlall
INSTRUCTION
}

package MY;
sub test {
    my $s = shift->SUPER::test(@_);
    # root can not run the tests on unix platforms
    $s =~ s/^(test_dynamic :: pure_all\n\t)(.+)$/$1if test `id -u` -gt 0; then $2; else echo skipped for root; true; fi/m
      if $^O =~ /^linux|freebsd|darwin|solaris|openbsd$/;
    $s;
}


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
