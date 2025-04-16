#!/bin/bash
# thunderbird.sh
#
# This script operates on the debian/ subdirectory of a Debian
# thunderbird source package, as available from
# https://packages.debian.org/source/bookworm/thunderbird#pdownload
# https://packages.debian.org/source/sid/thunderbird#pdownload
#

# thunderbird/debian/ directory location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize thunderbird

grep -Fqx 'Source: thunderbird' $debian/control 2>/dev/null \
|| error "$debian: not a thunderbird source package debian/ subdirectory"

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

rust_version=$(ubuntu_dist plucky && echo 1.84 || echo 1.80)

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

################################################################

finish

# Bump the epoch prefix up to 2, so that the thunderbird snap package isn't
# outright considered newer
perl -pi -e 'if (/^thunderbird / && $. == 1) { s/\(1:/(2:/; }' \
	$debian/changelog

echo "Thunderbird package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end thunderbird.sh
