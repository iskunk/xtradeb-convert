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

dpkg --compare-versions $deb_version ge 1:18.0.0 \
|| error 'version < 18 is not supported'

dpkg --compare-versions $deb_version lt 1:19.0.0 \
|| dpkg --compare-versions $deb_version ge 1:19.1.7 \
|| error 'please convert version >= 19.1.7 to avoid https://bugs.launchpad.net/bugs/2097731'

################################################################

# Enable the alternative "|hello" build dependencies to allow some
# flexibility in what packages are available.
sed -i '/^#BD_ALT_HELLO = yes/s/^#//' $debian/rules

# Don't use "|hello" for packages that *are* available, however,
# to reduce the risk of unexpected behavior/breakage.
sed -i -r '/^\s*(g\+\+-multilib|spirv-tools|wasi-libc)\b/{s/@BEGIN_.*@//;s/\s*\|\s*hello\b.*,/,/}' \
	$debian/control.in

# Make the llvm-spirv-NN optional build dependency use "|shove"
# instead of "|hello", as the latter is not available on i386.
sed -i -r '/^\s*llvm-spirv-\S+ /s/(\|\s*)hello\b/\1shove/' \
	$debian/control.in

# Neutralize a couple of checks in the rules file so that we don't
# need a full development setup for the regeneration step below.
sed -i -r '/installed by another constraint|dh_listpackages;/{n;s/^(\s+)(exit 1)/\1true XtraDeb \2/}' \
	$debian/rules

################################################################

finish

# Abbreviate an Ubuntu bit in the version string
sed -i -r '1s/(-[0-9]+)ubuntu([0-9]+)/\1u\2/' $debian/changelog

if [ -f $debian/../LICENSE.TXT -a "_$(basename $debian)" = _debian ]
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
