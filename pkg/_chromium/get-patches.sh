#!/bin/sh

wget='wget -c -nv'

set -ex

$wget -O bookworm_constcountrycode.patch \
	https://salsa.debian.org/chromium-team/chromium/-/raw/bookworm/debian/patches/bookworm/constcountrycode.patch

$wget -O bookworm_generate-ninja.patch \
	https://salsa.debian.org/chromium-team/chromium/-/raw/bookworm/debian/patches/bookworm/generate-ninja.patch

$wget -O bookworm_undo-rust-req.patch \
https://salsa.debian.org/chromium-team/chromium/-/raw/bookworm/debian/patches/bookworm/undo-rust-req.patch

$wget -O bullseye_devtools-ts-return.patch \
	https://salsa.debian.org/chromium-team/chromium/-/raw/bullseye/debian/patches/bullseye/devtools-ts-return.patch

$wget -O bullseye_framesensorconst.patch \
	https://salsa.debian.org/chromium-team/chromium/-/raw/bullseye/debian/patches/bullseye/framesensorconst.patch

$wget -O bullseye_node-trustedtypes.patch \
	https://salsa.debian.org/chromium-team/chromium/-/raw/bullseye/debian/patches/bullseye/node-trustedtypes.patch

$wget https://bazaar.launchpad.net/~mozillateam/firefox/firefox.focal/download/head:/debian/build/keepalive-wrapper.py
