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

# Enable the use of vendored Rust dependencies
cat >> $debian/rules << END

#
# Added by XtraDeb
#

# $vendor_date
VENDOR_TIMESTAMP = $vendor_timestamp
VENDOR_VERSION   = $upstream_version

include debian/xtradeb-vendor.mk

execute_after_dh_auto_configure: setup-vendor-rust
END

cp $base_dir/pkg/_common/xtradeb-vendor.mk $debian/

sed -i '/^Maintainer:/ i XS-XtraDeb-Vendor-Source-Depends: dh-cargo' \
	$debian/control

##
## Patch series modifications
##

# Don't mess with Cargo.toml
disable_patch relax-dep.diff

} # xd_convert()

################################################################

# end pkg/rust-cbindgen/script.sh
