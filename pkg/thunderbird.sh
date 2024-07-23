#!/bin/bash
# thunderbird.sh
#
# This script operates on the debian/ subdirectory of a Debian
# thunderbird source package, as available from
# https://packages.debian.org/source/sid/thunderbird#pdownload
#

# thunderbird/debian/ directory location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize thunderbird

if ! grep -Fqx 'Source: thunderbird' $debian/control 2>/dev/null
then
	echo "$0: error: $debian: not a thunderbird source package debian/ subdirectory"
	exit 1
fi

if ubuntu_dist jammy
then
	echo "$0: error: Ubuntu $ubuntu_ver/$ubuntu_dist already has an official thunderbird package"
	exit 1
fi

################################################################
##
## Modifications to allow building on Ubuntu noble and later
##
################################################################

# Some tweaks particular to the ~deb12 (bookworm) package
sed -i -r \
	-e '/^\s+autoconf2\.13,/d' \
	-e '/^\s+libfontconfig1-dev,/s/1//' \
	-e '/^\s+libotr5,/s/,/t64,/' \
	$debian/control

# Downgrade this dependency slightly to accommodate noble
sed -i -r '/^\s+librnp-dev /s/ 0\.17\.1\b/ 0.17.0/' $debian/control

# Use Clang/LLVM 17 specifically
# (the build fails mysteriously in a Rust component with clang-18)
sed -i -r \
	-e 's/^(\s+clang),/\1-17,/;' \
	-e 's/^(\s+libclang)-dev,/\1-17-dev,/;' \
	-e 's/^(\s+llvm)-dev,/\1-17-dev,/' \
	$debian/control

cat >>$debian/rules <<'END'

# XtraDeb additions

export LLVM_OBJDUMP = llvm-objdump-17
export MOZ_LIBCLANG_PATH = /usr/lib/llvm-17/lib
END

# Missing build dependency, not needed on Debian for some reason
# "pynacl 1.5.0 requires cffi, which is not installed."
perl -pi -e '/^(\s+)python3,/ and $_ .= "${1}python3-cffi,\n"' \
	$debian/control

#### Fixes for LTO-enabled build
##
## Same issues as with firefox: https://bugs.debian.org/1050890
##

# Find the right file to modify with e.g.
#   find obj-thunderbird -name \*.mk -exec grep -l RUST_LIBRARY_FEATURES {} +
perl -pi \
	-e '/mach -v configure/ and $_ .= <<END;' \
	-e '' \
	-e '	# XtraDeb: workaround for LTO breakage in webrender build' \
	-e '	perl -pi -e \x{27}s/-flto(=\\w+)?//g; s/-ffat-lto-objects//g\x{27} \\' \
	-e '		obj-thunderbird/toolkit/library/rust/backend.mk' \
	-e 'END' \
	$debian/rules

new_patch xtradeb/fix-param-lto-partitions.patch

##
## Patch series modifications
##

new_patch xtradeb/fortify-source-3.patch

################################################################

finish

# Bump the epoch prefix up to 2, so that the thunderbird snap package isn't
# outright considered newer
perl -pi -e 'if (/^thunderbird / && $. == 1) { s/\(1:/(2:/; }' \
	$debian/changelog

echo "Thunderbird package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end thunderbird.sh
