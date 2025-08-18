#!/bin/bash
# firefox.sh
#
# This script operates on the debian/ subdirectory of a Debian
# firefox or firefox-esr source package, as available from
# https://packages.debian.org/source/sid/firefox#pdownload
# https://packages.debian.org/source/sid/firefox-esr#pdownload
#

# firefox/debian/ directory location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize firefox

grep -Eq '^Source: firefox(-esr)?$' $debian/control 2>/dev/null \
|| error "$debian: not a firefox(-esr) source package debian/ subdirectory"

test -f $debian/browser.README.Debian.in \
|| error "$debian: not a Debian firefox source package debian/ subdirectory"

is_esr=$(grep -qx 'Source: firefox-esr' $debian/control && echo true || echo false)

# https://wiki.mozilla.org/Distribution_INI_File

test ! -f $debian/distribution.ini \
|| error 'package already has distribution.ini file'

cat >$debian/distribution.ini <<END
# XtraDeb addition

[Global]
id=xtradeb
version=1.0
about=Mozilla Firefox$($is_esr && echo ' ESR' || :) for Ubuntu

[Preferences]
app.distributor="xtradeb"
app.distributor.channel="debian"

[BookmarksToolbar]
item.1.description=Ubuntu website
item.1.title=Ubuntu
item.1.link=https://www.ubuntu.com
item.1.icon=https://www.ubuntu.com/favicon.ico
item.1.iconData=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACSklEQVQ4jX1TXWhSYRj+ZMxRN7vpZuwiRrBREchgxS6CQXTn1EULyWiFdIQQRCu6yI0Yg4KUJIOhNCSiusqLbmSMLroQ2WgRw5Oxc456NHeOOmPqMX/W4ekm/46uF76bl/d53p/n+QhRRImLjWf9Djdvm9xmZ1UyO6uSedvkdtbvcJe42LiyvisKQZedMQzWWC1Bv8cYBmuFoMveA6RpWv3z0aWNo4CslqDOx9BIMw1Wp5IzzsvrNE2rWwSi59arLoBOhZzHitLGW5Q/vYewNIc6t4NGhgOrU4HVEmT9DjchhBBpd0vD6lRyE5yyTkNcMaGyuY5m1PkYhKU5JG+e6mwil5mvZ4jopXzNZPzaCVS/b6KeoBE3jiB5ewKJ66PIeayQpSL+HOTB3znXIskFHj4hSfMY10wUXi8DAPKrD3pukHVRAAAp/LGVS1omYoTVEvx69xTybwl7Tj3qfAzx+eEeAu7KcRRDARwEX7ZV0Q80CKMfaBTWFiFLRaTtMzjMpsAZ1H2VSNsugrdoOkiPVUh8YTTdWmFtEQCw59T3gu0zAIBiKNC9gvjM9KZ1xPlh1H58QTUaQdw4gsSNk+AMagjLRjQyHA73M11KCF7LKqlEw1OdncQVE7IuCuXPH9oycjsQHl9F0nxaIeO3s4QQQoTnCwHlyPkXNhRDARRDAaTunkc1GkE1Gmk38lK+lhMZhhlK37sQ+Z+V/60ms1qC9P3pcJeVmyT9JlE+0Uv5GIYZOvJHVqLhKdFL+ToNljSPcaKX8km7Wxpl/V9ZLTo82gQ36wAAAABJRU5ErkJggg==
item.2.description=XtraDeb website
item.2.title=XtraDeb
item.2.link=https://xtradeb.net
item.2.icon=https://xtradeb.net/favicon.ico
item.2.iconData=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACkUlEQVQ4jY2TX2jNYRjHP8/7vme//TlYOgodMhobWtyQuxOZ3Yhku3Eh1ERKSlyQCFdEiIiliIZyoYgVm1JbQtr2syQzjSaMcHZ2/vze93Ux/yLyvXl6+n6/z/P0rQf+A5dBA3RCVTd0hND+BCoBzB/ienT9O0TaiNILqQ0CtjpPWa6IlmfXSIyB+Rr4CJuAzX8MaLiC/dHEWG0CFuNg2DK5qJST6Qw5BS4HHQDyq9nvZrwrY5kzdEaPidkBrirFZ+v5II6kGk//xy5aC4MUEtU8ibdwwXgQUmhpI7Kl7NIlbFAWqOKI66XWlvAq3sJgZj1zcewsn0iDSTLWRpSl63j/4wJ/jKpomC5ThNgCfdqzRLbx/DsfHWKp3sKtoRSrYiU0KUFyjlBlapmUraNx+BFzlSbEoJ3joGzjuW8kBpA+zhwf8VmEfPwuZ/OeDuvBCk3KCeeUYpPtY130hmZXYIiI+x6EU0SdZayxl7iYbWO2/5ZZzHDeCrvG3OSwAaoLjoeiqPBphryngB0R7gHZWElKvaPaaaYJeA/SfZ1BB28BlHM0GkGrgDOmghodUE7AHAE/U5BxlWxnKqdVwAKfwgh4YIOGoz0w/WeIJ5gaDRGaGLGoQGjy1MkOBgBeTKE4UUUoir3hDZ6WQ4uCeA7aFSAelGykVzzNxNBmNDW2mGMhxPuTlFT0kZU8+3yeA3HN1QDiHvDQZEbqCHSenVYo1oZMrp92C9e/vKK4G1723mHGlHkkEtUMvO+h1Vru10DTvx6oqAsevgX/GnwIfmAGbdl60pkVPM3UMh9A/W70IK0pTAPkDez/BD2foD+C5tIkb0hi9Sy0C5j+1+2/4h6MegATdoPKLGJldi23/SmWf+e/AvzuCKinXVlBAAAAAElFTkSuQmCC
END

cat >>$debian/browser.install.in <<END

# XtraDeb addition
debian/distribution.ini usr/share/@browser@/distribution
END

################################################################
##
## Modifications to allow building on Ubuntu jammy and later
##
################################################################

rm -f $debian/rules.add

# Submitted upstream at
# https://salsa.debian.org/mozilla-team/firefox/-/merge_requests/12 (ESR)
# https://salsa.debian.org/mozilla-team/firefox/-/merge_requests/13 (reg.)
cat >>$debian/make.mk <<END

# XtraDeb additions

# Don't use the default LTO options, as they make for an expensive build
export DEB_BUILD_MAINT_OPTIONS += optimize=-lto
END

cat >>$debian/browser.mozconfig.in <<END

# XtraDeb additions
ac_add_options --enable-lto=thin
END

if ubuntu_dist jammy
then
	# Use Clang/LLVM 15 specifically (instead of jammy's default of 14)
	# to avoid incompatibilities with Rust 1.80 or newer:
	#
	#   /usr/bin/ld: error: LLVM gold plugin has failed to create
	#   LTO module: Opaque pointers are only supported in
	#   -opaque-pointers mode (Producer: 'LLVM18.1.7-rust-1.80.1-stable'
	#   Reader: 'LLVM 14.0.0')
	sed -i -r \
		-e 's/^(\s+clang),/\1-15,/' \
		-e 's/^(\s+libclang)-dev,/\1-15-dev,/' \
		-e 's/^(\s+libclang-rt)-(dev-wasm32),/\1-15-\2,/' \
		-e 's/^(\s+libc\+\+)-(dev-wasm32),/\1-15-\2,/' \
		-e 's/^(\s+lld),/\1-15,/' \
		-e 's/^(\s+llvm)-dev,/\1-15-dev,/' \
		$debian/control.in

	cat >>$debian/rules.add <<'END'

export CC  = clang-15
export CXX = clang++-15
END
fi

# Ubuntu provides version-in-name cargo/rustc packages
sed -i -r 's/^(\s+(cargo|rustc)) \(>= (@RUST_VERSION@)\),/\1-\3,/' \
	$debian/control.in

rust_version=$( \
	ubuntu_dist plucky && echo 1.84 || \
	(! $is_esr && echo 1.82) || \
	echo 1.80 \
)

sed -i -r 's/^(%define RUST_VERSION) .*/\1 '"$rust_version/" \
	$debian/control.in

cat >>$debian/rules.add <<END

export CARGO ?= cargo-$rust_version
export RUSTC ?= rustc-$rust_version
END

# DIST needs to be set properly
sed -i 's/^DIST = unknown/DIST = $(DEB_DISTRIBUTION)/' \
	$debian/upstream.mk

if ubuntu_dist jammy
then
	# Hook in our vendored copy of cbindgen, as the distro-provided
	# package version in jammy is too old
	perl -pi \
		-e '/^RUSTFLAGS =/ and $_ .= <<END;' \
		-e '' \
		-e '# XtraDeb' \
		-e 'CBINDGEN = \$(CURDIR)/cbindgen/target/release/cbindgen' \
		-e 'END' \
		\
		-e '/^EXPORTS :=/ and $_ .= "EXPORTS += CBINDGEN\n";' \
		-e 'm!^stamps/configure-\$\(PRODUCT\)::! and s/$/  \$(CBINDGEN)/;' \
		\
		-e 'm!rm -rf debian/objdir! and $_ .= <<END;' \
		-e '' \
		-e '	# XtraDeb' \
		-e '	rm -rf cbindgen/.cargo/.package-cache cbindgen/target' \
		-e 'END' \
		$debian/rules

	cat >>$debian/rules.add <<'END'

# Build our vendored copy of cbindgen
$(CBINDGEN): cbindgen/Cargo.toml
	cd cbindgen && RUST_BACKTRACE=full $(CARGO) build --release
END

	sed -i -r '/^\s+cbindgen .+,$/s/^/%%xtradeb%%/' $debian/control.in
fi

# Extend distribution-release-specific conditionals with Ubuntu names
# (note: line continuations are not supported by the preprocessor)

# --without-wasm-sandboxed-libraries
sed -i '/^%if DIST == bullseye/s/$/  || DIST == jammy/' \
	$debian/browser.mozconfig.in

# WebAssembly library dependencies
sed -i '/^%if DIST != bullseye/s/$/  \&\& DIST != jammy/' \
	$debian/control.in

# SYSTEM_LIBS += nss
sed -i -r 's/(filter bullseye bookworm),/\1  jammy noble plucky,/' \
	$debian/rules

## This conditional doesn't handle USE_SYSTEM_NSS=0 properly
#perl -pi -e 's/^\%ifndef (USE_SYSTEM_NSS)$/\%if !$1/' \
#	$debian/browser.install.in \
#	$debian/browser.lintian-overrides.in

if [ -f $debian/rules.add ]
then
	(echo
	 echo '# XtraDeb additions'
	 cat $debian/rules.add
	) >>$debian/rules

	rm $debian/rules.add
fi

##
## Patch series modifications
##

# https://bugs.launchpad.net/bugs/2033572
if ubuntu_dist noble plucky
then
	new_patch xtradeb/fix-libc++-wasm-link-error.patch
fi

new_patch xtradeb/fix-param-lto-partitions.patch

if ubuntu_dist jammy
then
	true	# jammy uses _FORTIFY_SOURCE=2
elif $is_esr
then
	new_patch xtradeb/fortify-source-3-esr.patch
else
	new_patch xtradeb/fortify-source-3.patch
fi

################################################################

finish

if ! $is_esr
then
	# Add a "1:" epoch prefix to the version, so that the firefox snap
	# package isn't outright considered newer
	sed -i -r '1{/^firefox /s/\((.+)\)/(1:\1)/}' $debian/changelog
fi

files_to_regen=
for file in \
	control \
	firefox-esr.mozconfig
do
	if [ -f $debian/$file ]
	then
		files_to_regen+="${files_to_regen:+ }debian/$file"
	fi
done
if [ -f $debian/../browser/config/mozconfig -a "_$(basename $debian)" = _debian ]
then
	# Regenerate files
	(unset MAKEFLAGS; cd $debian/.. && set -x && debian/rules $files_to_regen TESTDIR=) \
	|| error 'failed to regenerate debianization files'
	rm -r  $debian/.mozbuild
	rm -rf $debian/objdir	# firefox-esr has this, but not firefox
	echo
else
	cat <<END

Note: Please run

  \$ cd $(cd $debian/.. && pwd)
  \$ debian/rules $files_to_regen

in the Firefox source tree, to regenerate necessary files.

END
fi

echo "Firefox package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end firefox.sh
