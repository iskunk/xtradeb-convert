# pkg/thunderbird/script.sh
#
# https://packages.debian.org/source/sid/thunderbird#pdownload
#

################################################################

xd_convert() {

! ubuntu_dist jammy \
|| not_applicable 'release already has an official thunderbird package'

################################################################
##
## Modifications to allow building on Ubuntu noble and later
##
################################################################

# Some tweaks particular to the ~deb12 (bookworm) package
sed -i -r \
	-e '/^\s+(cargo|cbindgen|rustc)-web /s/-web//' \
	-e '/^\s+libotr5,$/s/,/t64,/' \
	$debian/control

# Use lld for a faster final link
# (this and the "optimize=-lto" bit are submitted upstream at
# https://salsa.debian.org/mozilla-team/thunderbird/-/merge_requests/10)
perl -pi -e '/^(\s+)clang,$/ and $_.="${1}lld,\n"' $debian/control
sed -i '/-Wl,--reduce-memory-overheads/s/^/#xtradeb#/' $debian/rules

cat >$debian/xtradeb.tmp <<END

# XtraDeb: Disable default LTO options, as they make for an expensive build
export DEB_BUILD_MAINT_OPTIONS += optimize=-lto
END
(cd $debian && sed -i '/export DH_VERBOSE=1/ r xtradeb.tmp' rules)
rm $debian/xtradeb.tmp

cat >$debian/xtradeb.tmp <<END

# XtraDeb specific things
ac_add_options --enable-lto=thin
END
(cd $debian && sed -i '/--enable-application=comm\/mail/ r xtradeb.tmp' \
	mozconfig.thunderbird)
rm $debian/xtradeb.tmp

get_rust_version

# Use version-specific cargo/rustc packages
sed -i -r 's/^(\s+(cargo|rustc)) \(.+\),/\1-'"$rust_version,/" $debian/control

cat >>$debian/rules <<END

# XtraDeb additions

export CARGO = cargo-$rust_version
export RUSTC = rustc-$rust_version
END

if ubuntu_dist noble
then
	# Use the bundled libnss as the system one is too old
	sed -i '/^ac_add_options --with-system-nss/s/with/without/' \
		$debian/mozconfig.default
fi

##
## Patch series modifications
##

new_patch xtradeb/fix-param-lto-partitions.patch
new_patch xtradeb/fortify-source-3.patch
new_patch xtradeb/mach-python-312.patch
new_patch xtradeb/skia-cpu-arch.patch

need_version_epoch_bump=yes

} # xd_convert()

################################################################

# end pkg/thunderbird/script.sh
