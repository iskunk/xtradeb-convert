#!/bin/sh

wget='wget -c -nv'

bookworm_prefix=https://salsa.debian.org/chromium-team/chromium/-/raw/bookworm

set -ex

$wget -O bookworm_bubble-contents.patch \
	$bookworm_prefix/debian/patches/bookworm/bubble-contents.patch

$wget -O bookworm_cacheline.patch \
	$bookworm_prefix/debian/patches/bookworm/cacheline.patch

$wget -O bookworm_foreach.patch \
	$bookworm_prefix/debian/patches/bookworm/foreach.patch

$wget -O bookworm_gn-absl.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-absl.patch

$wget -O bookworm_gn-funcs.patch \
	$bookworm_prefix/debian/patches/bookworm/gn-funcs.patch

$wget -O bookworm_highway-blink.patch \
	$bookworm_prefix/debian/patches/bookworm/highway-blink.patch

$wget -O bookworm_less-void.patch \
	$bookworm_prefix/debian/patches/bookworm/less-void.patch

$wget -O bookworm_modff.patch \
	$bookworm_prefix/debian/patches/bookworm/modff.patch

$wget -O bookworm_rust-visibility.patch \
	$bookworm_prefix/debian/patches/bookworm/rust-visibility.patch

$wget -O fixes_absl-optional-bookworm.patch \
	$bookworm_prefix/debian/patches/fixes/absl-optional.patch

$wget https://bazaar.launchpad.net/~mozillateam/firefox/firefox.focal/download/head:/debian/build/keepalive-wrapper.py
