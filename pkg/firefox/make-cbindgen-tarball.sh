#!/bin/sh
#
# This script creates the firefox_VERSION.orig-cbindgen.tar.xz source
# tarball that allows building Firefox without a bleeding-edge version of
# cbindgen in the APT package repos.
#
# Based on the vendor_cbindgen() function in the debian/build/
# create-tarball.py script of Ubuntu's Firefox package for focal; see
# https://bazaar.launchpad.net/~mozillateam/firefox/firefox.focal/view/head:/debian/build/create-tarball.py
#
# Usage: Set the cbindgen_version variable below to the required value,
# and then run this script in a scratch directory somewhere.
#

cbindgen_version=0.26.0

umask 022

echo '*** Vendoring cbindgen and its dependencies ***'

set -ex

cargo new vendored-cbindgen --vcs none

( ####
	cd vendored-cbindgen

	echo "cbindgen = \"=$cbindgen_version\"" >> Cargo.toml

	cargo vendor

	cd vendor/cbindgen

	mkdir .cargo

	cargo vendor > .cargo/config

	(echo; echo '[workspace]') >> Cargo.toml
) ####

# Don't need Windows stuff
rm -rf vendored-cbindgen/vendor/cbindgen/vendor/winapi-*/lib
rm -f  vendored-cbindgen/vendor/cbindgen/vendor/winapi/src/*/*.rs

# Add a README file
cat > vendored-cbindgen/vendor/cbindgen/README.xtradeb << END
This tarball contains vendored Rust source code for cbindgen $cbindgen_version .
It was generated using the make-cbindgen-tarball.sh script.

This is provided to allow building Firefox, which usually requires a newer
version of cbindgen than is available in the APT package repositories.
END

# Rename the top-level directory to include the version
(cd vendored-cbindgen/vendor && mv cbindgen cbindgen-$cbindgen_version)

# Get a reproducible timestamp
wget -O release-info.json -q https://api.github.com/repos/mozilla/cbindgen/releases/tags/$cbindgen_version
release_timestamp=$(jq -r .published_at release-info.json)

XZ_OPT=-9 tar cJf firefox_VERSION.orig-cbindgen.tar.xz \
	--format=gnu \
	--sort=name \
	--mtime="$release_timestamp" \
	--clamp-mtime \
	--numeric-owner \
	--owner=0 \
	--group=0 \
	-C vendored-cbindgen/vendor \
	cbindgen-$cbindgen_version

# EOF
