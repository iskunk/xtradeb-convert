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

VENDOR_CARGO = @VENDOR_CARGO@

# @VENDOR_DATE@
VENDOR_TIMESTAMP = @VENDOR_TIMESTAMP@

vendor/VERSION:
	$(VENDOR_CARGO) --version
	rm -rf vendor
	umask 022; $(VENDOR_CARGO) vendor --locked
	@echo '# # #'

# Delete superfluous MS Windows crates to save some space
	find vendor/windows* \
		-type f \
		! -name Cargo.toml \
		! -name lib.rs \
		! -name main.rs \
		! -name \*.json \
		-delete
	find vendor -depth -type d -empty -delete

# The checksum files sometimes refer to non-existent things
# (Also, see https://github.com/rust-lang/cargo/issues/11063)
	find vendor -type f -name .cargo-checksum.json \
	| while read x; do echo '{"files":{}}' > "$$x"; done

	cd vendor && find . -mindepth 2 -type f -printf '%P\n' \
	| LC_COLLATE=C sort | xargs -d '\n' md5sum > MD5SUMS

	(echo 'These are Rust crate dependencies needed to build cbindgen.'; \
	 echo "Collected using $$($(VENDOR_CARGO) --version)"; echo; \
	 echo 'Note: This tarball is reproducible. See the "make-vendor-source" target'; \
	 echo 'in the debian/rules file of the XtraDeb rust-cbindgen source package.' \
	) > vendor/README

	dpkg-parsechangelog -S Version | sed 's/-[^-]*$$//' > $@
	chmod -R g=u-w,o=u-w vendor

make-vendor-source: vendor/VERSION
	version=$$(cat $<) \
	&& tarball=../rust-cbindgen_$$version.orig-vendor.tar.xz \
	&& test ! -f $$tarball \
	&& XZ_OPT=-T1 tar cJf $$tarball \
		--format=gnu \
		--sort=name \
		--mtime=@$(VENDOR_TIMESTAMP) \
		--numeric-owner \
		--owner=0 \
		--group=0 \
		vendor \
	&& ls -l $$tarball
END

vendor_cargo=/usr/lib/rust-1.91/bin/cargo
vendor_cargo_dep=cargo-1.91

sed -i \
	-e "s!@VENDOR_CARGO@!$vendor_cargo!g" \
	-e "s!@VENDOR_DATE@!$vendor_date!g" \
	-e "s!@VENDOR_TIMESTAMP@!$vendor_timestamp!g" \
	$debian/rules

sed -i "/^Maintainer:/ i XS-XtraDeb-Vendor-Source-Depends: $vendor_cargo_dep" \
	$debian/control

##
## Patch series modifications
##

# Don't need this, thanks to the vendoring
disable_patch relax-dep.diff

} # xd_convert()

################################################################

xd_convert_post() {

# Abbreviate an Ubuntu bit in the version string
sed -i -r '1s/(-[0-9]+)ubuntu([0-9]+)/\1u\2/' $debian/changelog

} # xd_convert_post()

################################################################

# end pkg/rust-cbindgen/script.sh
