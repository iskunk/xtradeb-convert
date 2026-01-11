#!/bin/sh
# get-patches.sh

wget='wget -c -nv'

git_prefix=https://salsa.debian.org/chromium-team/chromium/-/raw

set -ex

$wget -O bookworm_dav1d-extern.patch \
	$git_prefix/bookworm/debian/patches/bookworm/dav1d-extern.patch

$wget -O bookworm_derivre-create.patch \
	$git_prefix/bookworm/debian/patches/bookworm/derivre-create.patch

$wget -O bookworm_eslint.patch \
	$git_prefix/bookworm/debian/patches/bookworm/eslint.patch

$wget -O bookworm_gn-absl.patch \
	$git_prefix/bookworm/debian/patches/bookworm/gn-absl.patch

$wget -O bookworm_gn-funcs.patch \
	$git_prefix/bookworm/debian/patches/bookworm/gn-funcs.patch

$wget -O bookworm_gn-hpp11.patch \
	$git_prefix/bookworm/debian/patches/bookworm/gn-hpp11.patch

$wget -O bookworm_gn-path-exists2.patch \
	$git_prefix/bookworm/debian/patches/bookworm/gn-path-exists2.patch

$wget -O bookworm_node-esm-dirname.patch \
	$git_prefix/bookworm/debian/patches/bookworm/node-esm-dirname.patch

$wget -O bookworm_node18-import.patch \
	$git_prefix/bookworm/debian/patches/bookworm/node18-import.patch

$wget -O bookworm_rust-unsafe-extern.patch \
	$git_prefix/bookworm/debian/patches/bookworm/rust-unsafe-extern.patch

$wget -O bookworm_rust-visibility.patch \
	$git_prefix/bookworm/debian/patches/bookworm/rust-visibility.patch

$wget -O trixie_adler1.patch \
	$git_prefix/trixie/debian/patches/trixie/adler1.patch

$wget -O trixie_libxml-parseerr.patch \
	$git_prefix/trixie/debian/patches/trixie/libxml-parseerr.patch

$wget -O trixie_libxml2-no-xxe.patch \
	$git_prefix/trixie/debian/patches/trixie/libxml2-no-xxe.patch

$wget -O trixie_rust-is-multiple-of.patch \
	$git_prefix/trixie/debian/patches/trixie/rust-is-multiple-of.patch

# end get-patches.sh
