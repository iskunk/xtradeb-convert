#!/bin/bash
# rust-cbindgen.sh
#
# This script operates on the debian/ subdirectory of an
# Ubuntu rust-cbindgen source package, as available from
# https://packages.ubuntu.com/source/oracular/rust-cbindgen
#

# rust-cbindgen/debian/ location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize rust-cbindgen

grep -Fqx 'Source: rust-cbindgen' $debian/control 2>/dev/null \
|| error "$debian: not a rust-cbindgen source package debian/ subdirectory"

ubuntu_dist jammy noble || not_applicable

################################################################
##
## Modifications to allow building on Ubuntu jammy and later
##
################################################################

# Remove all dependencies on Rust crate packages, as most of them are not
# available in the release we are targeting.
sed -i -r '/^ +librust-/d' $debian/control

# Don't build the librust-cbindgen development packages, because we don't
# need them, and they will have usage-time dependencies on Rust crate
# packages that aren't available anyway.
sed -i -r '/^Package: librust-cbindgen(\+clap)?-dev/,/^$/d' \
	$debian/control

cat >> $debian/xtradeb.tmp << 'END'

# Added by XtraDeb
override_dh_auto_configure:
	test -d vendor
	mkdir debian/cargo_registry
	cd debian/cargo_registry && ln -s ../../vendor/* .
	dh_auto_configure -- --buildsystem cargo
END
(cd $debian && \
	sed -i '/dh \$@ --buildsystem cargo/ r xtradeb.tmp' rules)
rm $debian/xtradeb.tmp

# Add rules to generate a vendor source tree and tarball. These will be
# used to provide cbindgen's build dependencies instead of distro-packaged
# Rust crates. (Note that the vendor tarball is reproducible for a given
# version of the rust-cbindgen source package)
cat >> $debian/rules << 'END'

#
# Added by XtraDeb
#

CARGO ?= cargo

vendor/VERSION:
	$(CARGO) --version
	rm -rf vendor
	umask 022; $(CARGO) vendor

# Delete superfluous MS Windows crates to save some space
	find vendor/windows* \
		-depth \
		-type f \
		! -name Cargo.toml \
		! -name lib.rs \
		! -name main.rs \
		! -name \*.json \
		-delete
	find vendor -depth -type d -empty -delete

	(echo 'These are Rust crate dependencies needed to build cbindgen.'; \
	 echo "Collected using $$($(CARGO) --version)"; echo; \
	 echo 'Note: This tarball is reproducible. See the "vendor-tarball" rule in the'; \
	 echo 'debian/rules file of the XtraDeb rust-cbindgen source package.' \
	) > vendor/README
	dpkg-parsechangelog -S Version | sed 's/-.*//' > $@

vendor-tarball: vendor/VERSION
	version=$$(cat $<) \
	&& mtime=$$(stat -c '%Y' debian/debcargo.toml) \
	&& tarball=../rust-cbindgen_$$version.orig-vendor.tar.xz \
	&& tar cJf $$tarball \
		--format=gnu \
		--sort=name \
		--mtime @$$mtime \
		--clamp-mtime \
		--numeric-owner \
		--owner=0 \
		--group=0 \
		vendor \
	&& ls -l $$tarball
END

################################################################

finish

# Abbreviate an Ubuntu bit in the version string
sed -i -r '1s/(-[0-9]+)ubuntu([0-9]+)/\1u\2/' $debian/changelog

echo "Rust-cbindgen package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end rust-cbindgen.sh
