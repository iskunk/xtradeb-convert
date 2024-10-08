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

stable=no
case "$deb_version" in
	?:115.*) stable=yes ;;
esac

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

# Use Clang/LLVM 17 specifically
# (the build fails mysteriously in a Rust component with clang-18)
sed -i -r \
	-e 's/^(\s+clang),/\1-17,/;' \
	-e 's/^(\s+libclang)-dev,/\1-17-dev,/;' \
	-e 's/^(\s+llvm)-dev,/\1-17-dev,/' \
	$debian/control

# Use version-specific cargo/rustc packages
sed -i -r 's/^(\s+(cargo|rustc)) \(.+\),/\1-1.76,/' $debian/control

cat >>$debian/rules <<'END'

# XtraDeb additions

export LLVM_OBJDUMP = llvm-objdump-17
export MOZ_LIBCLANG_PATH = /usr/lib/llvm-17/lib

export CARGO = cargo-1.76
export RUSTC = rustc-1.76
END

# Oracular does not have cargo/rustc 1.76, and 1.74 is too old
if ubuntu_dist oracular
then
	sed -i -r 's/\b(cargo|rustc)-1.76\b/\1-1.80/' \
		$debian/control \
		$debian/rules
fi

if [ $stable = no ] && ubuntu_dist noble
then
	# Use the bundled libnss as the system one is too old
	sed -i '/^ac_add_options --with-system-nss/s/with/without/' \
		$debian/mozconfig.default
fi

# Missing build dependency, not needed on Debian for some reason
# "pynacl 1.5.0 requires cffi, which is not installed."
perl -pi -e '/^(\s+)python3,/ and $_ .= "${1}python3-cffi,\n"' \
	$debian/control

# Don't rename the typing_extensions directory, as that breaks the build:
#
#   [...]
#     File ".../third_party/python/fluent.syntax/fluent/syntax/stream.py", line 2, in <module>
#       from typing_extensions import Literal
#   ModuleNotFoundError: No module named 'typing_extensions'
#   make[5]: *** [backend.mk:636: toolkit/content/neterror/.deps/aboutNetErrorCodes.js.stub] Error 1
#
perl -pi -e 'm!^\s+mv third_party/python/typing_extensions! and s/(mv)/#XtraDeb#$1/' \
	$debian/rules

#### Fixes for LTO-enabled build
##
## Same issues as with firefox: https://bugs.debian.org/1050890
##

# Find the right file to modify with e.g.
#   find obj-thunderbird -name \*.mk -exec grep -l RUST_LIBRARY_FEATURES {} +
# Note:
#   .../toolkit/library/rust/backend.mk is for Thunderbird 115
#   .../comm/rust/gkrust/backend.mk is for Thunderbird >= 128
perl -pi \
	-e '/mach -v configure/ and $_ .= <<END;' \
	-e '' \
	-e '	# XtraDeb: workaround for LTO breakage in webrender build' \
	-e '	perl -pi -e \x{27}s/-flto(=\\w+)?//g; s/-ffat-lto-objects//g\x{27} \\' \
	-e '		obj-thunderbird/toolkit/library/rust/backend.mk \\' \
	-e '		obj-thunderbird/comm/rust/gkrust/backend.mk' \
	-e 'END' \
	$debian/rules

new_patch xtradeb/fix-param-lto-partitions.patch

##
## Patch series modifications
##

tag=$(test $stable = no || echo -v115)

new_patch xtradeb/fortify-source-3$tag.patch

if [ $stable = no ]
then
	new_patch xtradeb/mach-python-312.patch
	new_patch xtradeb/skia-cpu-arch.patch
fi

################################################################

finish

# Bump the epoch prefix up to 2, so that the thunderbird snap package isn't
# outright considered newer
perl -pi -e 'if (/^thunderbird / && $. == 1) { s/\(1:/(2:/; }' \
	$debian/changelog

echo "Thunderbird package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end thunderbird.sh
