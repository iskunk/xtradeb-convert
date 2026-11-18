# pkg/thunderbird/script.sh
#
# https://packages.debian.org/source/sid/thunderbird#pdownload
#

################################################################

xd_convert() {

test "_$source_name" != _thunderbird \
|| ! ubuntu_dist jammy \
|| test -n "${XTRADEB_NON_PRODUCTION:-}" \
|| not_applicable 'release already has an official thunderbird package'

# Use our "more swap" build hack so that Launchpad builders for ppc64el
# don't fall over
sed -i '/^Build-Depends:/ a \ xtradeb-build-hack-swap [ppc64el] <!noxtradeb>,' \
	$debian/control

# Use version-specific LLVM packages
sed -ri \
	-e 's/^(\s+clang),/\1-'"$llvm_version"',/' \
	-e 's/^(\s+(libclang|llvm))(-dev),/\1-'"$llvm_version"'\3,/' \
	$debian/control

# Use lld for a faster final link
# (this and the "optimize=-lto" bit are submitted upstream at
# https://salsa.debian.org/mozilla-team/thunderbird/-/merge_requests/10)
perl -pi -e '/^(\s+)clang-\d+,$/ and $_.="${1}lld-'"$llvm_version"',\n"' \
	$debian/control
sed -i '/-Wl,--reduce-memory-overheads/ s/^/#xtradeb#/' $debian/rules

cat > $debian/xtradeb.tmp << END

# XtraDeb: Disable default LTO options, as they make for an expensive build
export DEB_BUILD_MAINT_OPTIONS += optimize=-lto
END
(cd $debian && sed -i '/export DH_VERBOSE=1/ r xtradeb.tmp' rules)
rm $debian/xtradeb.tmp

# Use version-specific cargo/rustc packages
sed -ri 's/^(\s+(cargo|rustc)) \([^,]+\),/\1-'"$rust_version,/" \
	$debian/control

cat > $debian/xtradeb.tmp << END

# XtraDeb specific things
ac_add_options CC=clang-$llvm_version
ac_add_options CXX=clang++-$llvm_version
ac_add_options CARGO=cargo-$rust_version
ac_add_options RUSTC=rustc-$rust_version

# On riscv64, LTO yields "relocation R_RISCV_JAL out of range" link errors
if [ "_\$DEB_HOST_ARCH" != _riscv64 ]; then
  ac_add_options --enable-lto=thin
fi
END
(cd $debian && sed -i '/--enable-application=comm\/mail/ r xtradeb.tmp' \
	mozconfig.thunderbird)
rm $debian/xtradeb.tmp

# Fix the format of a couple commented-out lintian overrides
# (as we might need to use them)
sed -ri 's!^(#\w+bird: embedded-library) (usr/lib/\S+): (\w+)$!\1 \3 [\2]!' \
	$debian/*.lintian-overrides

if ubuntu_dist jammy noble resolute
then
	# Use the bundled libnss as the system one is too old
	sed -ri '/^\s+libnss3-dev / d' $debian/control
	sed -i '/^ac_add_options --with-system-nss/ s/with/without/' \
		$debian/mozconfig.default
	sed -ri '/^#\w+bird: embedded-library nss / s/^#//' \
		$debian/*.lintian-overrides
fi

if ubuntu_dist jammy
then
	# No ...t64 form available
	sed -ri 's/^(\s+libotr5)t64,/\1,/' $debian/control
fi

if ubuntu_dist jammy noble
then
	# Use the bundled librnp
	sed -ri '/^\s+librnp(-dev|0) / d' $debian/control
	sed -i '/--with-system-librnp/ s/with/without/' \
		$debian/mozconfig.default
	printf '\n# XtraDeb\n%s: embedded-library bzip2 [usr/lib/%s/librnp.so]\n' \
		$source_name $source_name \
	>> $debian/$source_name.lintian-overrides
else
	# Add a configure-time check to ensure the system librnp actually
	# meets Thunderbird's minimum version requirement (note that the
	# library is loaded dynamically at run-time)
	cat > $debian/xtradeb.tmp << 'END'
	# XtraDeb: Check that the system librnp passes muster
	min_rnp_version=$$(sed -nr '/^const MIN_RNP_VERSION =/ { s/.*\[(.+)\].*/\1/; s/, */./g; p }' \
		comm/mail/extensions/openpgp/content/modules/RNPLib.sys.mjs) && \
	test -n "$$min_rnp_version" && \
	pkg-config --atleast-version=$$min_rnp_version librnp
END
	(cd $debian && sed -i '/^override_dh_auto_configure:/ r xtradeb.tmp' \
		rules)
	rm $debian/xtradeb.tmp
fi

# Use a keepalive wrapper, as some link operations take a long time,
# and nice(1) the build down when running on Launchpad to avoid spurious
# (and log-less) "Failed to build" outcomes
cp $base_dir/pkg/chromium/keepalive-wrapper.py $debian/
sed -ri '/^\s+dh_auto_build/ i \	debian/keepalive-wrapper.py 3600 \\' \
	$debian/rules

# Fix a bizarre issue that causes a second-round build to immediately
# jump ahead to the "install" stage, even after running "clean"
sed -ri '/^\s+rm -rf debian.\.debhelper/ a \	rm -f debian/debhelper-build-stamp' \
	$debian/rules

##
## Patch series modifications
##

new_patch xtradeb/fix-param-lto-partitions.patch

if ! ubuntu_dist jammy
then
	new_patch xtradeb/fortify-source-3.patch
fi

if ! ubuntu_dist jammy noble
then
	new_patch xtradeb/libyuv-rvv-support.patch
fi

if ubuntu_dist jammy noble resolute
then
	new_patch pkg/firefox:xtradeb/ppc64el-workaround-for-llvm-assembler.patch
fi

new_patch xtradeb/python-no-pip-check.patch

if ubuntu_dist stonking
then
	new_patch pkg/firefox-mt:xtradeb-riscv-configure-rva23.patch \
		xtradeb/riscv-configure-rva23.patch
fi

if [ "_$source_name" = _thunderbird ]
then
	need_version_epoch_bump=yes
fi

} # xd_convert()

################################################################

# end pkg/thunderbird/script.sh
