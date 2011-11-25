use strict;
use warnings;

use ExtUtils::MakeMaker 6.17; # perl-5.6.2
use Config;

my %WriteMakefileArgs = 
  (
   "NAME" => "App::perlall",
   "VERSION_FROM" => "scripts/perlall",
   "ABSTRACT" => "Create perls and test with all perls",
   "AUTHOR" => "Reini Urban <rurban\@cpan.org>",
   "LICENSE" => "perl",
   "PREREQ_PM" =>  {
		    'App::Rad' => "1.04",
		    'Devel::Platform::Info' => '0',
		    'Devel::PatchPerl' => "0.46",
		    'IO::Scalar' => '0',
		    # in core:
		    'IPC::Cmd' => '0.54', # in core since 5.10
		    'IPC::Open3' => '0',
		    'Pod::Usage' => "1.33",
		    'File::Basename' => "2.74",
		    'Cwd' => "3.33",
		    'File::Path' => "1.08",
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

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
