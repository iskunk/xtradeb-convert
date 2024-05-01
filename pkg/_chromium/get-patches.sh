#!/bin/sh

wget='wget -c -nv'

set -ex

$wget -O bookworm_bubble-contents.patch \
	https://salsa.debian.org/chromium-team/chromium/-/raw/bookworm/debian/patches/bookworm/bubble-contents.patch

$wget -O bookworm_constcountrycode.patch \
	https://salsa.debian.org/chromium-team/chromium/-/raw/bookworm/debian/patches/bookworm/constcountrycode.patch

$wget -O bullseye_framesensorconst.patch \
	https://salsa.debian.org/chromium-team/chromium/-/raw/bullseye/debian/patches/bullseye/framesensorconst.patch

$wget https://bazaar.launchpad.net/~mozillateam/firefox/firefox.focal/download/head:/debian/build/keepalive-wrapper.py
