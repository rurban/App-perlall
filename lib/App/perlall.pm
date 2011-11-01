package App::perlall;
# ABSTRACT: Test with all perls
use App::Cmd::Setup -app;

=method build  [ perl<version><suffix> [ from ]]

=method install  [ perl<version><suffix> [ from ]]

alias to build

=cut

sub App::perlall::Command::build {
  my ($self, $opts, $args) = @_;
  warn "perlall build @$opts @$args";
}
*App::perlall::Command::install = *App::perlall::Command::build;

=method do commands

=cut

sub App::perlall::Command::do {
  my ($self, $opts, $args) = @_;
  warn "perlall build @$opts @$args";
}

=method init perl<version><suffix> [ modules ]

=cut

sub App::perlall::Command::init {
  my ($self, $opts, $args) = @_;
  warn "perlall init @$opts @$args";
}

=method make [ commands ]

=cut

sub App::perlall::Command::make {
  my ($self, $opts, $args) = @_;
  warn "perlall make @$opts @$args";
}

=method maketest

=cut

sub App::perlall::Command::maketest {
  my ($self, $opts, $args) = @_;
  warn "perlall maketest @$opts @$args";
}

=method makeinstall

=cut

sub App::perlall::Command::makeinstall {
  my ($self, $opts, $args) = @_;
  warn "perlall makeinstall @$opts @$args";
}

=method cpan modules...

=cut

sub App::perlall::Command::cpan {
  my ($self, $opts, $args) = @_;
  warn "perlall cpan @$opts @$args";
}

=method selfupgrade

=cut

sub App::perlall::Command::selfupgrade {
  my ($self, $opts, $args) = @_;
  warn "perlall selfupgrade @$opts @$args";
}

=method upgrade [ blead ]

=cut

sub App::perlall::Command::upgrade {   # blead
  my ($self, $opts, $args) = @_;
  warn "perlall upgrade @$opts @$args";
}

=option help

=cut

sub App::perlall::Option::help {
  my ($self, $opts, $args) = @_;
  #Pod::Usage->();
  warn "perlall --help @$opts @$args";
}

=option version

=cut

sub App::perlall::Option::version {
  die "perlapp $App::perlall::VERSION\n";
}

sub usage_desc { "perlall <command> [version...]" }

sub opt_spec {
  return (
	  [ "skip",     "skip versions (glob-style)" ],
	  [ "newer",    "only newer versions (glob-style)" ],
	  [ "older",    "only older versions (glob-style)" ],
	  [ "as=s",     "install perl under given name" ],
	  [ "force|f",  "force install" ],
	  [ "j=d",      "parallel make" ],
	  [ "D=s",      "./configure option" ],
	  [ "A=s",      "./configure option" ],
	  [ "U=s",      "./configure option" ],
	  [ "notest|n",  "skip the test suite on build and makeinstall" ],
	  [ "quiet|q",   "Make perlall command quieter" ],
	  [ "verbose|v", "Make perlall command say more" ],
	  [ "nolog",     "skip writing to the log file" ],
	  [ "help|h",    "commands and options" ],
	  [ "version" ],
	 );
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  # we need at least one argument beyond the options; die with that message
  # and the complete "usage" text describing switches, etc
  $self->usage_error("missing command") unless @$args;
}

1;
__END__

#!/bin/bash
# Test a module in cwd with all available local perls. 
# symlink to system perls with our versioned naming scheme
# d   DEBUGGING
# -nt non-threaded
# -m  multi
if [ -z "$perlall" ]; then
  perlall=$(ls /usr/local/bin/perl5*|sed 's,/usr/local/bin/perl,,')
#else
#  export perlall=${perlall:-"5.14.2-nt 5.12.3-m 5.10.1-m 5.8.8-nt 5.8.9 5.15.4d-nt 5.6.2d-nt 5.8.4d-nt 5.8.5d-nt 5.8.9d 5.10.1d-nt 5.14.0d-m 5.14.1-nt 5.14.1d-nt 5.14.2d 5.15.3-nt"}
fi
platform=$(perl -MDevel::Platform::Info -e'$d=Devel::Platform::Info->new->get_info();$s=$d->{oslabel}.$d->{osvers};$s=~s/\s//g;print lc($s)')
if [ -z $platform ]; then platform=$(uname | tr A-Z a-z); fi
base=$(basename $0)

if [ -f $base.lock ]; then
    echo "$base.lock exists. Probably $base already running"
    pgrep -fl $base
    exit
fi
echo $$ > $base.lock
trap "rm $base.lock; exit 255" SIGINT SIGTERM

__print() {
    echo -e "\033[1;32m$@\033[0;0m";
}
__print1() {
    echo -e "\033[1;39m$@\033[0;0m";
}

logpre=log.test-$platform
if [ -n "$1" -a "$base" != "perlall-do" -a "$base" != "perlall-make" -a "$base" != "perlall-cpan" ]
then 
    perlall="$*"
fi
sudo=sudo
if [ -w blib ]; then unset sudo; sudo=; fi
if [ -d blib ]; then $sudo rm -rf blib; fi
#test -f lib/B/Asmdata.pm && rm -f lib/B/Asmdata.pm

for p in $perlall
do
  if [ "$base" = "perlall-do" ]
  then
    alias p=perl$p
    export p
    echo perl$p $@
    perl$p $@ && ok="$ok $p"
  else
  if [ "$base" = "perlall-cpan" ]
  then
    echo perl$p -S cpan $@
    perl$p -S cpan $@
  else
    log=$logpre-$p
    test -f $log && mv $log $log.bak
    test -d t/.svn && svn info t | grep Revision >> $log
    test -d .git && git log --oneline HEAD^1..HEAD >> $log
    test -f Build && (./Build realclean; $sudo rm -rf blib _Build Build)
    test -d blib && $sudo make -s clean
    echo "alias p=perl$p" > ~/.alias-perl
    export p
    __print1 perl$p Makefile.PL
    if perl$p Makefile.PL
    then
      ( 
	  DL_NOWARN=1
          if [ "$base" = "perlall-make" ]
          then
	      log=log.make-$platform-$p
              __print1 make -s 
              make -s >/dev/null
              __print1 perl$p $@
	      echo perl$p $@ >> $log 2>&1
              (perl$p $@  | tee -a $log 2>&1) && ok="$ok $p"
          fi
          if [ "$base" = "perlall-maketest" -o "$base" = "perlall-maketest-m" ]
          then
              __print1 make test TEST_VERBOSE=1
              make && (make test TEST_VERBOSE=1 | tee -a $log 2>&1)
          fi
          if [ "$base" = "perlall-makeinstall" ]
          then
              __print1 "make test && $sudo make install"
              make &&  (make test TEST_VERBOSE=1 | tee -a $log 2>&1) && sudo make install
          fi
	  # B::C only: test with modules
	  if [ "$base" = "perlall-maketest-m" -a -d ".git" -a $(basename $PWD) = "B-C" ]
	  then
              __print1 "perl$p -Mblib t/modules.t t/top100 -log"
	      perl$p -Mblib t/modules.t t/top100 -log >> $log
              echo "----" >> $log
	  fi
          ( echo >> $log
            echo "----" >> $log
            echo >> $log
            test -d t/.svn && svn info . | grep Revision >> $log && svn diff -x -w t/ lib/B/ >> $log
            test -d .git && (git log -1 >> $log; git diff >> $log)
            perl$p -V >> $log)
      )
      # make -s clean
      # pskill a
    else
      perl$p Makefile.PL 2>&1 | tee -a $log
    fi
  fi
  fi
done

if [ "$base" = "perlall-do" ]
then
  echo ok=$ok
fi

rm $base.lock 2>/dev/null
test -f lib/B/C.pm && (rm -f rename && rmdir POSIX 2>/dev/null)
test -f ./store_rpt && ./store_rpt
exit 0
