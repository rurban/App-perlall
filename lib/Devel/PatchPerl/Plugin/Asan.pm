package Devel::PatchPerl::Plugin::Asan;
use base 'Devel::PatchPerl';
# AddressSanitizer dies on buffer-overflows
# and most perl security releases do not fix them.

=head2 Devel::PatchPerl::Plugin::Asan::patchperl()

Plugin for Devel::PatchPerl to fix several buffer overflows in production perls
which prevent compilations with clang AddressSanitizer, aka asan.

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


package Devel::PatchPerl;

push @patch, (
  {
    perl => [ 
              qr/^5\.12\.[0-5]$/,
              qr/^5\.1[35]\.\d$/,
              qr/^5\.14\.[0-3]$/,
            ],
    subs => [ [ \&_patch_listutil_boot ], [ \&_patch_sdbm], [ \&_patch_patchlevel_2 ], ],
  },
  {
    perl => [ qr/^5\.16\.0$/ ],
    subs => [ [ \&_patch_listutil_boot ], [ \&_patch_patchlevel_1l ], ],
  },
  {
    perl => [ qr/^5\.1[01]\.\d$/ ],
    subs => [ [ \&_patch_sdbm], [ \&_patch_patchlevel_1s ], ],
  }
);

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
}

sub _patch_patchlevel_1s
{
  _patch(<<'END');
--- patchlevel.h.orig	2012-11-12 10:53:26.000000000 -0600
+++ patchlevel.h	2012-11-12 10:56:02.790350262 -0600
@@ -131,6 +131,7 @@ static const char * const local_patches[] = {
        ,"uncommitted-changes"
 #endif
        PERL_GIT_UNPUSHED_COMMITS       /* do not remove this line */
+       ,"RT#111586 sdbm.c off-by-one access to global .dir"
        ,NULL
 };

END
}

sub _patch_patchlevel_1l
{
  _patch(<<'END');
--- patchlevel.h.orig	2012-11-12 10:53:26.000000000 -0600
+++ patchlevel.h	2012-11-12 10:56:02.790350262 -0600
@@ -131,6 +131,7 @@ static const char * const local_patches[] = {
        ,"uncommitted-changes"
 #endif
        PERL_GIT_UNPUSHED_COMMITS       /* do not remove this line */
+       ,"RT#72700 List::Util boot Fix off-by-two on string literal length"
        ,NULL
 };

END
}

sub _patch_patchlevel_2
{
  _patch(<<'END');
--- patchlevel.h.orig	2012-11-12 10:53:26.000000000 -0600
+++ patchlevel.h	2012-11-12 10:56:02.790350262 -0600
@@ -131,6 +131,8 @@ static const char * const local_patches[] = {
 	,"uncommitted-changes"
 #endif
 	PERL_GIT_UNPUSHED_COMMITS    	/* do not remove this line */
+	,"RT#72700 List::Util boot Fix off-by-two on string literal length"
+	,"RT#111586 sdbm.c off-by-one access to global .dir"
 	,NULL
 };
 
END
}

1;
