# pkg/llama.cpp/script.sh
#
# https://packages.debian.org/source/sid/llama.cpp
# https://packages.ubuntu.com/source/llama.cpp
#
# https://packages.debian.org/source/sid/ggml
# https://packages.ubuntu.com/source/ggml
#
# https://packages.debian.org/source/sid/tokenizers
# https://packages.ubuntu.com/source/tokenizers
#

################################################################

xd_convert() {

case "$source_name" in

	tokenizers)
	# Use version-specific cargo/rustc packages
	sed -ri 's/^(\s+)(cargo|rustc)(,|$)/\1\2-'"$rust_version"'\3/' \
		$debian/control
	# Remove all dependencies on Rust crate packages; vendor 'em all
	sed -ri '/^\s+librust-/ d' \
		$debian/control
	# Add vendoring framework
	cat >> $debian/rules << END
#
# Added by XtraDeb
#

# $vendor_date
VENDOR_TIMESTAMP = $vendor_timestamp
VENDOR_VERSION   = $upstream_version

VENDOR_CARGO_MANIFEST_PATH = bindings/python

include debian/xtradeb-vendor.mk

execute_after_dh_auto_configure: setup-vendor-rust
END
	cp $base_dir/pkg/_common/xtradeb-vendor.mk $debian/
	sed -i '/^Build-Depends:/ i XS-XtraDeb-Vendor-Source-Depends: dh-cargo' \
		$debian/control
	sed -i "/^directory =/ s:'.*':'vendor/cargo_registry':" \
		$debian/cargo-config.toml
	disable_patch set_version.patch
	;;

esac

} # xd_convert()

################################################################

xd_check() {

case "$source_name" in
	llama.cpp) include_xtradeb_ppa=test ;; #XXX
esac

default_check "$@"

} # xd_check()

################################################################

# end pkg/llama.cpp/script.sh
