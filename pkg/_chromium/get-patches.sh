#!/bin/sh

wget='wget -c -nv'

bookworm_prefix=https://salsa.debian.org/chromium-team/chromium/-/raw/bookworm

set -ex

$wget -O bookworm_dav1d-extern.patch \
	$bookworm_prefix/debian/patches/bookworm/dav1d-extern.patch

$wget -O bookworm_derivre-create.patch \
	$bookworm_prefix/debian/patches/bookworm/derivre-create.patch

$wget -O bookworm_gn-absl.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-absl.patch

$wget -O bookworm_gn-funcs.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-funcs.patch

$wget -O bookworm_gn-hpp11.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-hpp11.patch

$wget -O bookworm_node18-import.patch \
	$bookworm_prefix/debian/patches/bookworm/node18-import.patch

$wget -O bookworm_rust-is-none-or.patch \
	$bookworm_prefix/debian/patches/bookworm/rust-is-none-or.patch

$wget -O bookworm_rust-unstable-features.patch \
	$bookworm_prefix/debian/patches/bookworm/rust-unstable-features.patch

$wget -O bookworm_rust-visibility.patch \
	$bookworm_prefix/debian/patches/bookworm/rust-visibility.patch

$wget https://bazaar.launchpad.net/~mozillateam/firefox/firefox.focal/download/head:/debian/build/keepalive-wrapper.py
