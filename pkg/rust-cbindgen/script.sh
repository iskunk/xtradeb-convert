# pkg/rust-cbindgen/script.sh
#
# https://packages.ubuntu.com/source/rust-cbindgen
#

################################################################

xd_convert() {

# Remove all dependencies on Rust crate packages, as most of them are not
# available in the release we are targeting.
sed -ri '/^\s+librust-/ d' $debian/control

# Don't build the librust-cbindgen development packages, because we don't
# need them, and they will have install-time dependencies on Rust crate
# packages that aren't available anyway.
zap_control_package 'librust-cbindgen(\+clap)?-dev' $debian/control

# Add rules to generate (and consume) a vendor source tree and tarball.
# These will provide cbindgen's build dependencies instead of
# distro-packaged Rust crates. (Note that the vendor tarball is
# reproducible for a given version of the rust-cbindgen source package)
cat >> $debian/rules << 'END'

#
# Added by XtraDeb
#

override_dh_auto_configure:
	@if [ ! -d vendor ]; then \
		echo 'Error: No vendor source directory found!'; \
		echo 'Is the orig-vendor tarball generated and present?'; \
		exit 1; \
	fi
	mkdir debian/cargo_registry
	cd debian/cargo_registry && ln -s ../../vendor/* .
	dh_auto_configure -- --buildsystem cargo

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

} # xd_convert()

################################################################

xd_convert_post() {

# Abbreviate an Ubuntu bit in the version string
sed -i -r '1s/(-[0-9]+)ubuntu([0-9]+)/\1u\2/' $debian/changelog

} # xd_convert_post()

################################################################

# end pkg/rust-cbindgen/script.sh
