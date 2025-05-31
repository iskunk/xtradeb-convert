#!/bin/bash
# llvm-toolchain.sh
#
# This script operates on the debian/ subdirectory of an
# Ubuntu llvm-toolchain-NN source package, as available from e.g.
# https://packages.ubuntu.com/source/plucky/llvm-toolchain-20
#

# llvm-toolchain-NN/debian/ location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize llvm-toolchain

grep -Eq '^Source: llvm-toolchain-[0-9]{2}$' $debian/control 2>/dev/null \
|| error "$debian: not an llvm-toolchain-NN source package debian/ subdirectory"

################################################################

# Enable the alternative "hello" build dependencies to avoid stage 2
# requirements, like llvm-spirv-NN, that are not available.
sed -i '/^#BD_ALT_HELLO = yes/s/^#//' $debian/rules

# Drop the "hello" alternative for packages that *are* available,
# however, to reduce the risk of unexpected behavior/breakage.
sed -i -r '/^\s*(g\+\+-multilib|wasi-libc)\b/s/@BEGIN_.*@//' \
	$debian/control.in

# Neutralize the "missing wasi-libc" error case, as it can interfere
# with the regeneration step below.
sed -i -r '/installed by another constraint/{n;s/^(\s+)(exit 1)/\1true XtraDeb \2/}' \
	$debian/rules

################################################################

finish

# Abbreviate an Ubuntu bit in the version string
sed -i -r '1s/(-[0-9]+)ubuntu([0-9]+)/\1u\2/' $debian/changelog

if [ -f $debian/../clang/CMakeLists.txt -a "_$(basename $debian)" = _debian ]
then
	# Make a list of all files present in the debianization dir
	(cd $debian && : >xtradeb.tmp && find . -type f >xtradeb.tmp)

	rm -f $debian/../stamps/preconfigure

	# Regenerate files
	(unset MAKEFLAGS; cd $debian/.. && set -x && debian/rules stamps/preconfigure) \
	|| error 'failed to regenerate debianization files'
	echo

	# Delete any (new) files that were not previously present
	(cd $debian && find . -type f ! -exec grep -Fqx {} xtradeb.tmp \; -delete)
	rm $debian/xtradeb.tmp
else
	cat <<END

Note: Please run

  \$ cd $(cd $debian/.. && pwd)
  \$ rm -f stamps/preconfigure
  \$ debian/rules stamps/preconfigure

in the LLVM source tree, to regenerate necessary files.

END
fi

echo "LLVM package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end llvm-toolchain.sh
