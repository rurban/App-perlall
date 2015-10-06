package Devel::PatchPerl::Plugin::Compiler;
use base 'Devel::PatchPerl';

=head1 DESCRIPTION

The perl compiler modules L<B::C>, L<B::Bytecode> and L<B::CC> 
require various patches for various perl versions.

Some patches are mandatory for Windows or other strictly linked platforms (AIX), 
some are recommended to produce smaller and faster code.

You need to run C<perlall build --allpatches> or C<perlall build --patches=Compiler>
to apply these.

=head1 PATCHES

This list is complete for all perl versions 5.6 - 5.17.8, for all three threaded,
non-threaded and multiplicity variants.

    5.13.7-now:  RT#81332 revert 744aaba0 bloats the B compilers
    5.10-5.15.1: 8375c93e Export store_cop_label for the perl compiler
    5.15.2-3:    4497a11a Export DynaLoader symbols from libperl again

=head2 Devel::PatchPerl::Plugin::Compiler::patchperl($class, {version,source,patchexe})

Apply patches in Devel::PatchPerl::Plugin::Compiler depending on the 
perl version. See L<Devel::PatchPerl::Plugin>

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
  { perl => [ qr/^5\.1[456]\.\d$/ ],
    subs => [ [ \&_patch_B_BEGIN ] ],
  },
  { perl => [ qr/^5\.17\.\d$/ ], # TODO: 5.18,20,22
    subs => [ [ \&_patch_B_BEGIN_517 ] ],
  },
  { perl => [ qr/^5\.1[0-4]\.\d$/,
	      qr/^5\.15\.[01]$/ ],  # fixed in 5.15.2
    subs => [ [ \&_patch_store_cop_label] ],
  },
  { perl => [ qr/^5\.15\.[23]$/ ],
    subs => [ [ \&_patch_dl_export] ],
  },
);

sub _add_patchlevel1 {
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
  print STDERR "patch: $line\n";
  return $success;
}

sub _patch_B_BEGIN
{
  # Need to provide several versions per B version bump
  my $vers = shift;
  my $patch = <<'END';
diff -u ext/B/B.pm.orig ext/B/B.pm
--- ext/B/B.pm.orig	2012-05-23 17:40:02.167549196 -0500
+++ ext/B/B.pm	2013-01-09 13:15:10.391328942 -0600
@@ -6,26 +6,16 @@
 #      License or the Artistic License, as specified in the README file.
 #
 package B;
-use strict;
 
+require XSLoader;
 require Exporter;
 @B::ISA = qw(Exporter);
 
 # walkoptree_slow comes from B.pm (you are there),
 # walkoptree comes from B.xs
 
-BEGIN {
-    $B::VERSION = '1.34';
-    @B::EXPORT_OK = ();
-
-    # Our BOOT code needs $VERSION set, and will append to @EXPORT_OK.
-    # Want our constants loaded before the compiler meets OPf_KIDS below, as
-    # the combination of having the constant stay a Proxy Constant Subroutine
-    # and its value being inlined saves a little over .5K
-
-    require XSLoader;
-    XSLoader::load();
-}
+$B::VERSION = '1.34_01';
+@B::EXPORT_OK = ();
 
 push @B::EXPORT_OK, (qw(minus_c ppname save_BEGINs
 			class peekop cast_I32 cstring cchar hash threadsv_names
@@ -38,6 +28,9 @@
 			@specialsv_name
 		      ), $] > 5.009 && 'unitcheck_av');
 
+sub OPf_KIDS ();
+use strict;
+
 @B::SV::ISA = 'B::OBJECT';
 @B::NULL::ISA = 'B::SV';
 @B::PV::ISA = 'B::SV';
@@ -332,6 +325,8 @@
     }
 }
 
+XSLoader::load();
+
 1;
 
 __END__
END

  #; )
  # 5.14.0-3 B-1.29
  # 5.16.0   B-1.34
  # 5.16.1-2 B-1.35
  if ($vers =~ /^5\.14\./) {
      $patch =~ s/B::VERSION = '1.34/B::VERSION = '1.29/g;
  }
  elsif ($vers =~ /^5\.16\.[12]/) {
      $patch =~ s/B::VERSION = '1.34/B::VERSION = '1.35/g;
  }
  _patch($patch);

  _add_patchlevel1($vers, "RT#81332 revert 744aaba0 bloats the B compilers");
}

sub _patch_B_BEGIN_517
{
  # Need to provide several versions per B version bump
  my $vers = shift;
  my $patch = <<'END';
  _patch(<<'END');
diff -u ext/B/B.pm.orig ext/B/B.pm
--- ext/B/B.pm.orig	2012-11-28 16:28:25.376657707 -0600
+++ ext/B/B.pm	2013-01-09 13:35:28.247382145 -0600
@@ -6,26 +6,16 @@
 #      License or the Artistic License, as specified in the README file.
 #
 package B;
-use strict;
 
+require XSLoader;
 require Exporter;
 @B::ISA = qw(Exporter);
 
 # walkoptree_slow comes from B.pm (you are there),
 # walkoptree comes from B.xs
 
-BEGIN {
-    $B::VERSION = '1.41';
-    @B::EXPORT_OK = ();
-
-    # Our BOOT code needs $VERSION set, and will append to @EXPORT_OK.
-    # Want our constants loaded before the compiler meets OPf_KIDS below, as
-    # the combination of having the constant stay a Proxy Constant Subroutine
-    # and its value being inlined saves a little over .5K
-
-    require XSLoader;
-    XSLoader::load();
-}
+$B::VERSION = '1.41_01';
+@B::EXPORT_OK = ();
 
 push @B::EXPORT_OK, (qw(minus_c ppname save_BEGINs
 			class peekop cast_I32 cstring cchar hash threadsv_names
@@ -37,6 +27,9 @@
 			defstash curstash warnhook diehook inc_gv @optype
 			@specialsv_name unitcheck_av));
 
+sub OPf_KIDS ();
+use strict;
+
 @B::SV::ISA = 'B::OBJECT';
 @B::NULL::ISA = 'B::SV';
 @B::PV::ISA = 'B::SV';
@@ -330,6 +323,8 @@
     }
 }
 
+XSLoader::load();
+
 1;
 
 __END__
END

  #; )
  # 5.17.5 B-1.39
  # 5.17.6 B-1.40
  # 5.17.8 B-1.41
  if ($vers =~ /^5\.17\.5/) {
      $patch =~ s/B::VERSION = '1.41/B::VERSION = '1.39/g;
  }
  elsif ($vers =~ /^5\.17\.6/) {
      $patch =~ s/B::VERSION = '1.41/B::VERSION = '1.40/g;
  }
  elsif ($vers =~ /^5\.17\.[789]/) {
      $patch =~ s/B::VERSION = '1.41/B::VERSION = '1.41/g;
  }
  elsif ($vers =~ /^5\.18\.0/) {
      $patch =~ s/B::VERSION = '1.41/B::VERSION = '1.42/g;
  }
  elsif ($vers =~ /^5\.18\.1/) {
      $patch =~ s/B::VERSION = '1.41/B::VERSION = '1.42_01/g;
  }
  elsif ($vers =~ /^5\.18\.2/) {
      $patch =~ s/B::VERSION = '1.41/B::VERSION = '1.42_02/g;
  }
  elsif ($vers =~ /^5\.20\./) {
      $patch =~ s/B::VERSION = '1.41/B::VERSION = '1.48/g;
  }
  elsif ($vers =~ /^5\.22\./) {
      $patch =~ s/B::VERSION = '1.41/B::VERSION = '1.58/g;
  }
  _patch($patch);

  _add_patchlevel1($vers, "RT#81332 revert 744aaba0 bloats the B compilers");
}

sub _patch_store_cop_label
{
  # a70c7e2f048a735797bc368a5de5669f371e78fa Export store_cop_label for the perl compiler
  _patch(<<'END');
--- embed.fnc.old
+++ embed.fnc
@@ -2446,8 +2446,8 @@ Apon	|void	|sys_init3	|NN int* argc|NN char*** argv|NN char*** env
 Apon	|void	|sys_term
 ApoM	|const char *|fetch_cop_label|NN COP *const cop \
 		|NULLOK STRLEN *len|NULLOK U32 *flags
-: Only used  in op.c
-xpoM	|void|store_cop_label \
+: Only used  in op.c and the perl compiler
+ApoM	|void|store_cop_label \
 		|NN COP *const cop|NN const char *label|STRLEN len|U32 flags
 
 xpo	|int	|keyword_plugin_standard|NN char* keyword_ptr|STRLEN keyword_len|NN OP** op_ptr
diff --git a/ext/XS-APItest/APItest.xs b/ext/XS-APItest/APItest.xs
index 21f417d..6164bd0 100644
--- ext/XS-APItest/APItest.xs.old
+++ ext/XS-APItest/APItest.xs
@@ -2348,6 +2348,27 @@ test_cophh()
 #undef msvpvs
 #undef msviv
 
+void
+test_coplabel()
+    PREINIT:
+        COP *cop;
+        char *label;
+        int len, utf8;
+    CODE:
+        cop = &PL_compiling;
+        Perl_store_cop_label(aTHX_ cop, "foo", 3, 0);
+        label = Perl_fetch_cop_label(aTHX_ cop, &len, &utf8);
+        if (strcmp(label,"foo")) croak("fail # fetch_cop_label label");
+        if (len != 3) croak("fail # fetch_cop_label len");
+        if (utf8) croak("fail # fetch_cop_label utf8");
+        /* SMALL GERMAN UMLAUT A */
+        Perl_store_cop_label(aTHX_ cop, "foä", 4, SVf_UTF8);
+        label = Perl_fetch_cop_label(aTHX_ cop, &len, &utf8);
+        if (strcmp(label,"foä")) croak("fail # fetch_cop_label label");
+        if (len != 3) croak("fail # fetch_cop_label len");
+        if (!utf8) croak("fail # fetch_cop_label utf8");
+
+
 HV *
 example_cophh_2hv()
     PREINIT:
diff --git a/hv.c b/hv.c
index a230c16..11c5565 100644
--- hv.c.old
+++ hv.c
@@ -3286,6 +3286,15 @@ Perl_refcounted_he_inc(pTHX_ struct refcounted_he *he)
     return he;
 }
 
+/*
+=for apidoc fetch_cop_label
+
+Returns the label attached to a cop.
+The flags pointer may be set to C<SVf_UTF8> or 0.
+
+=cut
+*/
+
 /* pp_entereval is aware that labels are stored with a key ':' at the top of
    the linked list.  */
 const char *
@@ -3322,6 +3331,15 @@ Perl_fetch_cop_label(pTHX_ COP *const cop, STRLEN *len, U32 *flags) {
     return chain->refcounted_he_data + 1;
 }
 
+/*
+=for apidoc store_cop_label
+
+Save a label into a C<cop_hints_hash>. You need to set flags to C<SVf_UTF8>
+for a utf-8 label.
+
+=cut
+*/
+
 void
 Perl_store_cop_label(pTHX_ COP *const cop, const char *label, STRLEN len,
 		     U32 flags)
END

  _add_patchlevel1(@_, "a70c7e2f Export store_cop_label for the perl compiler");
}

sub _patch_dl_export
{
  # 5.15.2-3:    4497a11a Export DynaLoader symbols from libperl again
  _patch(<<'END');
diff --git a/ext/DynaLoader/dlutils.c b/ext/DynaLoader/dlutils.c
index 1ba9a61..574ccad 100644
--- ext/DynaLoader/dlutils.c.old
+++ ext/DynaLoader/dlutils.c
@@ -8,6 +8,7 @@
  *                      files when the interpreter exits
  */
 
+#define PERL_EUPXS_ALWAYS_EXPORT
 #ifndef START_MY_CXT /* Some IDEs try compiling this standalone. */
 #   include "EXTERN.h"
 #   include "perl.h"
END

  _add_patchlevel1(@_, "4497a11a Export DynaLoader symbols from libperl again");
}

1;
