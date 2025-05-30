#!/bin/bash
# rustc.sh
#
# This script operates on the debian/ subdirectory of an
# Ubuntu rustc-X.YY source package, as available from
# https://packages.ubuntu.com/source/plucky/rustc-1.81#pdownload
# https://packages.ubuntu.com/source/plucky/rustc-1.82#pdownload
# https://packages.ubuntu.com/source/plucky/rustc-1.83#pdownload
# https://packages.ubuntu.com/source/plucky/rustc-1.84#pdownload
#

# rustc-X.YY/debian/ location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize rustc

grep -Eq '^Source: rustc-[0-9.]+$' $debian/control 2>/dev/null \
|| error "$debian: not an Ubuntu rustc-X.YY source package debian/ subdirectory"

# Latest version of Rust available in each Ubuntu release
# (so the version we're converting had better be newer)
latest=
case $ubuntu_dist in
	jammy | noble) latest=1.80 ;;
	oracular) latest=1.81 ;;
	plucky) latest=1.84 ;;
esac
test -z "$latest" || dpkg --compare-versions $deb_version gt $latest.99 \
|| not_applicable "Rust $latest is in the official archive"

################################################################

# Downgrade some dependencies
if ubuntu_dist jammy
then
	sed -i '/^\s*dh-cargo /s/ 28ubuntu1~/ 28/' $debian/control.in
	sed -i '/dh-cargo-vendored-sources/s/^/#xtradeb#/' $debian/rules
fi
if ubuntu_dist jammy noble oracular
then
	sed -i '/^\s*libgit2-dev /s/ 1.9.0~*/ 1.1.0/' $debian/control.in
	# Also see libgit2-downgrade.patch below
fi

case "$deb_version" in
	1.83.* | 1.84.*)
	# Missing build-dep -- https://bugs.launchpad.net/bugs/2107682
	perl -pi -e '/^(\s+)libsqlite3-dev,$/ and $_.="${1}libzstd-dev,\n"' \
		$debian/control.in
	;;
esac

if ubuntu_dist jammy
then
	cat >>$debian/rules <<'END'

# XtraDeb additions

# Jammy doesn't have e.g. /usr/bin/x86_64-linux-gnu-pkg-config
xd_host  := $(shell $(RUST_BOOTSTRAP_DIR)/bin/rustc -Vv | awk '/^host:/{print $$2}')
xd_host2 := $(subst -,_,$(xd_host))
export PKG_CONFIG_$(xd_host2) = /usr/bin/pkg-config
END
fi

# Don't hard-code the build parallelism
(cd $debian && patch -p1 -s) <<'END'
--- debian/rules.orig
+++ debian/rules
@@ -69,7 +69,3 @@
 ifneq (,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
-ifeq ($(DEB_HOST_ARCH),riscv64)
 NJOBS := -j $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
-else
-NJOBS := -j 4
-endif
 endif
END

# Make this only a warning
sed -i '/No suitable Rust toolchain found/s/error/info Warning:/' \
	$debian/rules

# This option interferes with creating the source package
x=$debian/source/options
if [ -f $x ] && grep -q '^include-removal' $x
then
	rm $x
fi

##
## Patch series modifications
##

if ubuntu_dist jammy noble oracular
then
	# Beware of file paths containing version strings
	test -f $debian/../vendor/libgit2-sys-0.17.0+1.8.1/build.rs \
	|| test ! -d $debian/../vendor \
	|| error 'libgit2-downgrade.patch needs updating'

	disable_patch ubuntu/ubuntu-update-libgit2-to-1.9.patch
	new_patch xtradeb/libgit2-downgrade.patch
fi

################################################################

finish

# Abbreviate an Ubuntu bit in an overly long version string
sed -i -r '1s/(-[0-9]+)ubuntu([0-9]+)/\1u\2/' $debian/changelog

if [ -f $debian/../version -a "_$(basename $debian)" = _debian ]
then
	# Make a list of all files present in the debianization dir
	(cd $debian && : >xtradeb.tmp && find . -type f >xtradeb.tmp)

	# Regenerate files
	(unset MAKEFLAGS; cd $debian/.. && set -x && debian/rules debian/preconfigure.stamp) \
	|| error 'failed to regenerate debianization files'
	echo

	# Delete any (new) files that were not previously present
	(cd $debian && find . -type f ! -exec grep -Fqx {} xtradeb.tmp \; -delete)
	rm $debian/xtradeb.tmp
else
	cat <<END

Note: Please run

  \$ cd $(cd $debian/.. && pwd)
  \$ debian/rules debian/preconfigure.stamp

in the Rust source tree, to regenerate necessary files.

END
fi

echo "Rust package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end rustc.sh
