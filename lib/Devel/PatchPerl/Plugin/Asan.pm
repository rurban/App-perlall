package Devel::PatchPerl::Plugin::Asan;
use base 'Devel::PatchPerl';

=head1 SECURITY FIXES

AddressSanitizer dies on buffer-overflows
and most perl security releases do not fix them.

=head2 Devel::PatchPerl::Plugin::Asan::patchperl()

Plugin for Devel::PatchPerl to fix several buffer overflows in production perls
which prevent compilations with C<clang AddressSanitizer>, aka I<asan>.

Note that F<buildperl.pl> from L<Devel::PPPerl> and L<Devel::PatchPerl> do
not provide such security patches, only configure and make patches.

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

push @patch, (
  {
    perl => [ qr/^5\.1[01]\.\d$/ ],
    # fixed in 5.16.0
    subs => [ [ \&_patch_sdbm] ],
  },
  {
    perl => [ qr/^5\.12\.[0-5]$/,
              qr/^5\.1[35]\.\d$/,
              qr/^5\.14\.[0-3]$/,
            ],
    subs => [ [ \&_patch_listutil_boot ], [ \&_patch_sdbm] ],
  },
  {
    perl => [ qr/^5\.16\.0$/ ],
    # fixed in 5.16.1
    subs => [ [ \&_patch_listutil_boot ] ],
  },
  {
    perl => [ qr/^5\.15\.[4-9]$/,
              qr/^5\.17\.[0-6]$/ ],
    # fixed in 5.17.6
    subs => [ [ \&_patch_to_utf8_case_memcpy ] ],
  },
  {
    perl => [ qr/^5\.[6-9].\d$/,
	      qr/^5\.1[0-5].\d$/,
              qr/^5\.16\.0$/ ],
    # fixed in 5.16.1
    subs => [ [ \&_patch_socket_un ] ],
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
  return $success;
}

sub _patch_listutil_boot
{
  # RT#72700 Fix off-by-two on string literal length
  _patch(<<'END');
--- cpan/List-Util/ListUtil.xs.orig	2012-11-12 10:41:07.000000000 -0600
+++ cpan/List-Util/ListUtil.xs	2012-11-12 10:47:52.943198199 -0600
@@ -600,7 +600,7 @@
     varav = GvAVn(vargv);
 #endif
     if (SvTYPE(rmcgv) != SVt_PVGV)
-	gv_init(rmcgv, lu_stash, "List::Util", 12, TRUE);
+	gv_init(rmcgv, lu_stash, "List::Util", 10, TRUE);
     rmcsv = GvSVn(rmcgv);
 #ifndef SvWEAKREF
     av_push(varav, newSVpv("weaken",6));
END

  _add_patchlevel(@_, "RT#72700 List::Util boot Fix off-by-two on string literal length");
}

sub _patch_sdbm
{
  # acdbe25bd91bf897e0cf373b9
  # RT#111586 sdbm.c off-by-one access to global .dir
  _patch(<<'END');
--- ext/SDBM_File/sdbm/sdbm.c.orig	2012-11-12 10:53:26.000000000 -0600
+++ ext/SDBM_File/sdbm/sdbm.c		2012-11-12 10:56:02.790350262 -0600
@@ -78,8 +78,8 @@ sdbm_open(register char *file, register int flags, register int mode)
 	register char *dirname;
 	register char *pagname;
 	size_t filelen;
-	const size_t dirfext_len = sizeof(DIRFEXT "");
-	const size_t pagfext_len = sizeof(PAGFEXT "");
+	const size_t dirfext_size = sizeof(DIRFEXT "");
+	const size_t pagfext_size = sizeof(PAGFEXT "");
 
 	if (file == NULL || !*file)
 		return errno = EINVAL, (DBM *) NULL;
@@ -88,17 +88,17 @@ sdbm_open(register char *file, register int flags, register int mode)
  */
 	filelen = strlen(file);
 
-	if ((dirname = (char *) malloc(filelen + dirfext_len + 1
-				       + filelen + pagfext_len + 1)) == NULL)
+	if ((dirname = (char *) malloc(filelen + dirfext_size
+				       + filelen + pagfext_size)) == NULL)
 		return errno = ENOMEM, (DBM *) NULL;
 /*
  * build the file names
  */
 	memcpy(dirname, file, filelen);
-	memcpy(dirname + filelen, DIRFEXT, dirfext_len + 1);
-	pagname = dirname + filelen + dirfext_len + 1;
+	memcpy(dirname + filelen, DIRFEXT, dirfext_size);
+	pagname = dirname + filelen + dirfext_size;
 	memcpy(pagname, file, filelen);
-	memcpy(pagname + filelen, PAGFEXT, pagfext_len + 1);
+	memcpy(pagname + filelen, PAGFEXT, pagfext_size);
 
 	db = sdbm_prep(dirname, pagname, flags, mode);
 	free((char *) dirname);
END

  _add_patchlevel(@_, "RT#111586 sdbm.c off-by-one access to global .dir");
}

sub _patch_to_utf8_case_memcpy
{
  _patch(<<'END');
--- utf8.c
+++ utf8.c
@@ -2366,7 +2366,9 @@ Perl_to_utf8_case(pTHX_ const U8 *p, U8* ustrp, STRLEN *lenp,
     /* Here, there was no mapping defined, which means that the code point maps
      * to itself.  Return the inputs */
     len = UTF8SKIP(p);
-    Copy(p, ustrp, len, U8);
+    if (p != ustrp) {   /* RT#115702 Don't copy onto itself */
+        Copy(p, ustrp, len, U8);
+    }
 
     if (lenp)
         *lenp = len;
END

  _add_patchlevel(@_, "RT#115702 overlapping memcpy in to_utf8_case");
}

sub _patch_socket_un
{
  my $vers = shift;
  my $patch = <<'END';
--- ext/Socket/Socket.xs
+++ ext/Socket/Socket.xs
@@ -565,10 +565,16 @@ unpack_sockaddr_un(sun_sv)
 			"Socket::unpack_sockaddr_un",
 			sockaddrlen, sizeof(addr));
 	}
+#   else
+	if (sockaddrlen < sizeof(addr)) { /* RT #111594 */
+           Copy(sun_ad, &addr, sockaddrlen, char);
+           Zero(&addr+sockaddrlen, sizeof(addr)-sockaddrlen, char);
+       }
+       else {
+           Copy(sun_ad, &addr, sizeof(addr), char);
+       }
 #   endif
 
-	Copy( sun_ad, &addr, sizeof addr, char );
-
 	if ( addr.sun_family != AF_UNIX ) {
 	    croak("Bad address family for %s, got %d, should be %d",
 			"Socket::unpack_sockaddr_un",
END

  #; )
  if ($vers =~ /^5\.6\./) {
    $patch =~ s/@@ -565,10 +565,16 @@/@@ -1016,10 +1016,16 @@/;
  }
  if ($vers =~ /^5\.[89]\./ or $vers =~ /^5\.1[0-2]\./) {
    $patch =~ s/@@ -565,10 +565,16 @@/@@ -363,10 +363,16 @@/;
  }
  if ($vers =~ /^5\.16\./ or $vers =~ /^5\.15\.[5-9]\./) {
    $patch =~ s|ext/Socket/Socket.xs|cpan/Socket/Socket.xs|g;
  }
  _patch($patch);

  _add_patchlevel($vers, "RT#111594 Socket::unpack_sockaddr_un heap-buffer-overflow");
}

1;
