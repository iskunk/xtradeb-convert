#!/bin/sh

wget='wget -c -nv'

bookworm_prefix=https://salsa.debian.org/chromium-team/chromium/-/raw/bookworm

set -ex

# Note: Patch was relocated in Git
$wget -O bookworm_adler1.patch \
	$bookworm_prefix/debian/patches/trixie/adler1.patch

$wget -O bookworm_dav1d-extern.patch \
	$bookworm_prefix/debian/patches/bookworm/dav1d-extern.patch

$wget -O bookworm_derivre-create.patch \
	$bookworm_prefix/debian/patches/bookworm/derivre-create.patch

$wget -O bookworm_eslint.patch \
	$bookworm_prefix/debian/patches/bookworm/eslint.patch

$wget -O bookworm_gn-absl.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-absl.patch

$wget -O bookworm_gn-funcs.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-funcs.patch

$wget -O bookworm_gn-hpp11.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-hpp11.patch

$wget -O bookworm_gn-path-exists2.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-path-exists2.patch

# Note: Patch was relocated in Git
$wget -O bookworm_libxml-parseerr.patch \
	$bookworm_prefix/debian/patches/trixie/libxml-parseerr.patch

$wget -O bookworm_node18-import.patch \
	$bookworm_prefix/debian/patches/bookworm/node18-import.patch

$wget -O bookworm_rust-visibility.patch \
	$bookworm_prefix/debian/patches/bookworm/rust-visibility.patch
