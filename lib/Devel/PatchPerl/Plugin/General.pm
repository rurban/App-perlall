package Devel::PatchPerl::Plugin::General;
use base 'Devel::PatchPerl';

=head1 DESCRIPTION

Plugin for Devel::PatchPerl for general build patches which should
be provided by Devel::PatchPerl, but are not yet.

=head1 PATCHES

This list is complete:

    5.19.3-: Compress::Raw::Zlib -g3 final link failed: Memory exhausted

=head2 Devel::PatchPerl::Plugin::General::patchperl($class, {version,source,patchexe})

Apply patches in Devel::PatchPerl::Plugin::General depending on the
perl version. See L<Devel::PatchPerl::Plugin>.

Every patch is recorded in patchlevel.h, visible in myconfig.
If a patch fails the script dies.

=cut

sub patchperl {
  my $class = shift;
  my %args = @_;
  my ($vers, $source, $patch_exe) = @args{qw(version source patchexe)};
  for my $p ( grep { Devel::PatchPerl::_is( $_->{perl}, $vers ) } @Devel::PatchPerl::patch ) {
    for my $s (@{$p->{subs}}) {
      my ($sub, @args) = @$s;
      push @args, $vers unless scalar @args;
      $sub->(@args);
    }
  }
}


package
  Devel::PatchPerl;

use File::Copy;
use vars '@patch';

@patch = (
  {
    perl => [ qr/^5\.19\.[3456789]$/ ],
    subs => [ [ \&_patch_CompressRawZlib] ],
  },
);

sub _add_patchlevel {
  my $vers = shift;
  my $line = shift;
  my $success;
  File::Copy::cp("patchlevel.h", "patchlevel.h.orig");
  open my $in, "<", "patchlevel.h.orig" or return;
  open my $out, ">", "patchlevel.h" or return;
  $line =~ s/"/\"/g;
  my $qr = $] > 5.010 ? /^\s+PERL_GIT_UNPUSHED_COMMITS/
                      : /^\tNULL$/;
  while (my $s = <$in>) {
    print $out $s;
    if ($s =~ $qr) {
      $success++;
      print $out "\t,\"".$line."\"\n";
    }
  }
  close $in;
  close $out;
  print STDERR "patched: $line\n";
  return $success;
}

sub _patch_CompressRawZlib
{
#From 82876fa94f7e69a7dc706d083a03f26b43d0cb4c Mon Sep 17 00:00:00 2001
#From: Reini Urban <rurban@x-ray.at>
#Date: Wed, 23 Oct 2013 10:38:28 -0500
#Subject: [PATCH] [CPAN #88936] Compress-Raw-Zlib -g3: final link failed:
# Memory exhausted
#
#---
# cpan/Compress-Raw-Zlib/Makefile.PL | 8 +++++++-
# 1 file changed, 7 insertions(+), 1 deletion(-)
  _patch(<<'END');
diff cpan/Compress-Raw-Zlib/Makefile.PL~ cpan/Compress-Raw-Zlib/Makefile.PL
index d8c060d..aba7abc 100644
--- cpan/Compress-Raw-Zlib/Makefile.PL~
+++ cpan/Compress-Raw-Zlib/Makefile.PL
@@ -6,6 +6,7 @@ require 5.006 ;
 use private::MakeUtil;
 use ExtUtils::MakeMaker 5.16 ;
 use ExtUtils::Install (); # only needed to check for version
+use Config;
 
 my $ZLIB_LIB ;
 my $ZLIB_INCLUDE ;
@@ -14,6 +15,10 @@ my $OLD_ZLIB = '' ;
 my $WALL = '' ;
 my $GZIP_OS_CODE = -1 ;
 my $USE_PPPORT_H = ($ENV{PERL_CORE}) ? '' : '-DUSE_PPPORT_H';
+my $OPTIMIZE = $Config{'optimize'};
+if ($Config{'gccversion'} and $OPTIMIZE =~ /-g3/) {
+  $OPTIMIZE =~ s/-g3/-g/; # [88936] out of memory with -g3 since 2.062
+}
 
 #$WALL = ' -pedantic ' if $Config{'cc'} =~ /gcc/ ;
 #$WALL = ' -Wall -Wno-comment ' if $Config{'cc'} =~ /gcc/ ;
@@ -81,7 +86,8 @@ WriteMakefile(
         ? zlib_files($ZLIB_LIB)
         : (LIBS => [ "-L$ZLIB_LIB -lz " ])
     ),
-      
+    OPTIMIZE => $OPTIMIZE,
+
     INSTALLDIRS => ($] >= 5.009 && $] < 5.011 ? 'perl' : 'site'),
 
     META_MERGE => {
-- 
1.8.4.rc3

END

  _add_patchlevel(@_, "CPAN #88936 Compress-Raw-Zlib -g3: final link failed: Memory exhausted");
}

1;
