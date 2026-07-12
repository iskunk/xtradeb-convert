# xtradeb-vendor.mk
# XtraDeb rules for vendoring Go/Node.js/Rust dependencies, so that package
# builds need not require distro-packaged versions of modules/crates
#
# This file is included from debian/rules and is not intended for
# standalone use.
#

ifndef VENDOR_TIMESTAMP
$(error VENDOR_TIMESTAMP is not defined)
endif
ifndef VENDOR_VERSION
$(error VENDOR_VERSION is not defined)
endif

# Run one of these from a (e.g.) "execute_after_dh_auto_configure" target

vendor_dir_check = \
	if [ ! -d vendor ]; then \
		echo 'Error: No vendor source directory found!'; \
		echo 'Is the orig-vendor tarball generated and present?'; \
		exit 1; \
	fi

setup-vendor-go:
	@$(vendor_dir_check)

setup-vendor-nodejs:
	@$(vendor_dir_check)
	test -d node_modules
	cd node_modules && ln -s ../vendor/node_modules/* .

setup-vendor-rust:
	@$(vendor_dir_check)
	test -d debian/cargo_registry
	for crate in $$(cd vendor/cargo_registry && echo *); do \
		test -f vendor/cargo_registry/$$crate/Cargo.toml || continue; \
		test ! -e debian/cargo_registry/$$crate || continue; \
		ln -s ../../vendor/cargo_registry/$$crate debian/cargo_registry/ || exit; \
	done

# Populate the vendor/ subdirectory
#
get-vendor-source:
	rm -rf vendor
#
# Go
#
ifneq "" "$(wildcard go.sum)"
	go version
	go mod vendor -v
	echo "Vendored Go dependencies collected using $$(go version)" >> vendor/README
endif # go.mod
#
# Node.js
#
ifneq "" "$(wildcard package-lock.json)"
	npm --version
	test ! -d node_modules
	npm ci --ignore-scripts
	test -d node_modules
	for mod in $$(cd debian/build_modules && echo *); do \
		test -f debian/build_modules/$$mod/package.json || continue; \
		rm -rf node_modules/$$mod; \
	done
	mkdir -p vendor
	mv node_modules vendor/
	rm -fv debian/nodejs/extcopies debian/nodejs/extlinks
	echo "Vendored Node.js dependencies collected using npm version $$(npm --version)" >> vendor/README
endif # package-lock.json
#
# Rust
#
ifneq "" "$(wildcard Cargo.lock)"
	cargo --version
	umask 022; cargo vendor --locked vendor/cargo_registry
	@echo '# # #'
#
# Generate the XS-Vendored-Sources-Rust: header for the control file
	CARGO_VENDOR_DIR=vendor/cargo_registry \
	/usr/share/cargo/bin/dh-cargo-vendored-sources --output-expected > tmp.vsr
	sed -i 's/^/XS-Vendored-Sources-Rust: /; s/$$/,/; s/ /\n /g' tmp.vsr
	mv tmp.vsr vendor/cargo_registry/00-control-header.txt
#
# Delete superfluous MS Windows crates to save some space
	for crate in \
		vendor/cargo_registry/winapi* \
		vendor/cargo_registry/windows* ; \
	do \
		test -d $$crate || continue; \
		find $$crate \
			-type f \
			! -name Cargo.toml \
			! -name lib.rs \
			! -name main.rs \
			! -name \*.json \
			-delete \
		|| exit; \
	done
	find vendor -depth -type d -empty -delete
#
# The checksum files sometimes refer to non-existent things
# (Also, see https://github.com/rust-lang/cargo/issues/11063)
	find vendor -type f -name .cargo-checksum.json \
	| while read x; do echo '{"files":{}}' > "$$x"; done
	echo "Vendored Rust dependencies collected using $$(cargo --version)" >> vendor/README
endif # Cargo.lock
#
	cd vendor && find . -mindepth 2 -type f -printf '%P\n' \
	| LC_COLLATE=C sort | xargs -d '\n' md5sum > MD5SUMS
	(echo; \
	 echo 'Note: This tarball is reproducible. See the "get-vendor-source" target'; \
	 echo 'in the debian/xtradeb-vendor.mk file of the source package.' \
	) >> vendor/README
	echo '$(VENDOR_VERSION)' > vendor/VERSION

vendor-tarball: get-vendor-source
	chmod -R g=u-w,o=u-w vendor
	source=$$(dpkg-parsechangelog -S Source) \
	&& version='$(VENDOR_VERSION)' \
	&& tarball=../$${source}_$$version.orig-vendor.tar.xz \
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

# end xtradeb-vendor.mk
