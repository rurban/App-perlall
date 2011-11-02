use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = 
  (
   "NAME" => "App::perlall",
   "VERSION_FROM" => "scripts/perlall.pl",
   "ABSTRACT" => "Test with all perls",
   "AUTHOR" => "Reini Urban <rurban\@cpan.org>",
   "EXE_FILES" => [qw(script/perlall)],
   "LICENSE" => "perl",
   "PREREQ_PM" =>  {
		    'App::Rad' => "1.04",
		    'Pod::Usage' => "1.36",
		    'File::Basename' => "2.77",
		    'File::Slurp' => "9999.13",
		    'Cwd' => "3.33",
		    'File::Path' => "2.07",
		    'Getopt::Long' => "2.36",
		    # 'Devel::PatchPerl' => "0.46",
		   },
   "SIGN" => 1,
  );

# XXX copy .perlall to $HOME

WriteMakefile(%WriteMakefileArgs);

package MY;


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
