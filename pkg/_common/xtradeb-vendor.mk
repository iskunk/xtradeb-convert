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

VENDOR_CARGO_LOCK := $(if $(VENDOR_CARGO_MANIFEST_PATH),$(VENDOR_CARGO_MANIFEST_PATH)/)Cargo.lock

ifneq "" "$(wildcard go.sum)"
VENDOR_GO_SUPPORT = 1
endif

ifneq "" "$(wildcard package-lock.json)"
VENDOR_NODEJS_SUPPORT = 1
endif

ifneq "" "$(wildcard $(VENDOR_CARGO_LOCK))"
VENDOR_RUST_SUPPORT = 1
# Note: This is used by dh-cargo tooling, not Cargo
export CARGO_VENDOR_DIR = vendor/cargo_registry
endif

# Run one of these from a (e.g.) "execute_after_dh_auto_configure" target

vendor_dir_check = \
	if [ ! -d vendor ]; then \
		echo 'Error: No vendor source directory found!'; \
		echo 'Is the orig-vendor tarball generated and present?'; \
		exit 1; \
	fi

.PHONY: setup-vendor-go setup-vendor-nodejs setup-vendor-rust

setup-vendor-go:
	@$(vendor_dir_check)

setup-vendor-nodejs:
	@$(vendor_dir_check)
	test -d node_modules
	cd node_modules && ln -s ../vendor/node_modules/* .

setup-vendor-rust:
	@$(vendor_dir_check)

# Populate the vendor/ subdirectory
#
.PHONY: get-vendor-source
get-vendor-source:
	rm -rf vendor
#
# Go
#
ifdef VENDOR_GO_SUPPORT
	go version
	go mod vendor -v
	echo "Vendored Go dependencies collected using $$(go version)" >> vendor/README
endif # VENDOR_GO_SUPPORT
#
# Node.js
#
ifdef VENDOR_NODEJS_SUPPORT
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
endif # VENDOR_NODEJS_SUPPORT
#
# Rust
#
ifdef VENDOR_RUST_SUPPORT
	cargo --version
	umask 022; unset CARGO_NET_OFFLINE; cargo vendor \
		$(if $(VENDOR_CARGO_MANIFEST_PATH), \
			--manifest-path $(VENDOR_CARGO_MANIFEST_PATH)/Cargo.toml \
		) \
		--locked \
		$(CARGO_VENDOR_DIR)
	@echo '# # #'
#
# Generate the XS-Vendored-Sources-Rust: field for the control file
	/usr/share/cargo/bin/dh-cargo-vendored-sources --output-expected > tmp.vsr
	sed -i 's/^/XS-Vendored-Sources-Rust: /; s/ /\n /g' tmp.vsr
# Work around $BUG
	perl -0777 -pi -e 's/(Rust:)\n/$$1/' tmp.vsr
	mv tmp.vsr vendor/cargo_registry/00-control-header.txt
#
# Update the control file if a substitution marker is present
	regex='^#@XS-Vendored-Sources-Rust@'; \
	! grep -q "$$regex" debian/control \
	|| sed -i -e "/$$regex/ { r vendor/cargo_registry/00-control-header.txt" -e 'd }' \
		debian/control
#
# Hollow out superfluous MS Windows crates to save some space
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
endif # VENDOR_RUST_SUPPORT
#
# Run the vendoring hook, if one was provided
	! grep -q '^get-vendor-source-hook\s*:' debian/rules \
	|| debian/rules get-vendor-source-hook
#
# Finishing touches
	cd vendor && find . -mindepth 2 -type f -printf '%P\n' \
	| LC_COLLATE=C sort | xargs -d '\n' md5sum > MD5SUMS
	(echo; \
	 echo 'Note: This tarball is reproducible. See the "get-vendor-source" target'; \
	 echo 'in the debian/xtradeb-vendor.mk file of the source package.' \
	) >> vendor/README
	echo '$(VENDOR_VERSION)' > vendor/VERSION

.PHONY: vendor-tarball
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
