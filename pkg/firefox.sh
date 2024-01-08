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

if ! grep -Eq '^Source: firefox(-esr)?$' $debian/control 2>/dev/null
then
	echo "$0: error: $debian: not a firefox(-esr) source package debian/ subdirectory"
	exit 1
fi
if [ ! -f $debian/browser.README.Debian.in ]
then
	echo "$0: error: $debian: not a Debian firefox source package debian/ subdirectory"
	exit 1
fi

# https://wiki.mozilla.org/Distribution_INI_File

if [ -f $debian/distribution.ini ]
then
	echo "$0: error: package already has distribution.ini file"
	exit 1
fi

cat >$debian/distribution.ini <<END
# XtraDeb addition

[Global]
id=xtradeb
version=1.0
about=Mozilla Firefox for Ubuntu

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

# DIST needs to be set properly
perl -pi -e 's/^DIST = unknown/DIST = \$(DEB_DISTRIBUTION)/' \
	$debian/upstream.mk

# Hook in our vendored copy of cbindgen
perl -pi \
	-e '/^RUSTFLAGS =/ and $_ .= <<END;' \
	-e '' \
	-e '# XtraDeb' \
	-e 'CBINDGEN = \$(CURDIR)/cbindgen/target/release/cbindgen' \
	-e 'END' \
	\
	-e '/^EXPORTS :=/ and s/$/  CBINDGEN/;' \
	-e 'm!^stamps/configure-\$\(PRODUCT\)::! and s/$/  \$(CBINDGEN)/;' \
	\
	-e 'm!rm -rf debian/objdir! and $_ .= <<END;' \
	-e '' \
	-e '	# XtraDeb' \
	-e '	rm -rf cbindgen/.cargo/.package-cache cbindgen/target' \
	-e 'END' \
	$debian/rules

cat >>$debian/rules <<'END'

# XtraDeb additions

# Build our vendored copy of cbindgen
$(CBINDGEN): cbindgen/Cargo.toml
	cd cbindgen && RUST_BACKTRACE=full cargo build --release
END

# Extend distribution-release-specific conditionals with Ubuntu names
# (note: line continuations are not supported by the preprocessor)

perl -pi -e '/^\%if DIST == bullseye/ and s/$/  || DIST == jammy/' \
	$debian/browser.mozconfig.in

perl -pi -e '/^\%if DIST != bullseye/ and s/$/  \&\& DIST != jammy/' \
	$debian/control.in

perl -pi -e 's/(filter buster bullseye bookworm),/$1  jammy lunar mantic,/' \
	$debian/rules

## This conditional doesn't handle USE_SYSTEM_NSS=0 properly
#perl -pi -e 's/^\%ifndef (USE_SYSTEM_NSS)$/\%if !$1/' \
#	$debian/browser.install.in \
#	$debian/browser.lintian-overrides.in

if ubuntu_dist lunar mantic
then
	# Fix for https://bugs.launchpad.net/bugs/2033450
	perl -pi \
		-e '/^(\s+)libc\+\+-dev-wasm32,/ and $_ = <<END . $_;' \
		-e '%% XtraDeb: install this so Clang can find WASI libc++ headers' \
		-e '${1}  libc++-dev,' \
		-e 'END' \
		$debian/control.in
fi

# cbindgen is included as an orig source tarball, as the distro-packaged
# versions are too old
perl -pi -e '/^\s+cbindgen .+,$/ and s/^/%%xtradeb%%/' $debian/control.in

##
## Patch series modifications
##

# Fix for https://bugs.launchpad.net/bugs/2033572
if ubuntu_dist lunar mantic
then
	new_patch xtradeb/fix-libc++-wasm-link-error.patch
fi

#### Fixes for LTO-enabled build
##
## More information here: https://bugs.debian.org/1050890
##

perl -pi \
	-e '/^# Use thinLTO on armhf/ and $_ = <<END . $_;' \
	-e '	# XtraDeb: workaround for LTO breakage in webrender build' \
	-e '	perl -pi -e \x{27}s/-flto(=\\w+)?//g; s/-ffat-lto-objects//g\x{27} \\' \
	-e '		build-browser/toolkit/library/rust/backend.mk' \
	-e '' \
	-e 'END' \
	$debian/rules

new_patch xtradeb/fix-param-lto-partitions.patch

# These errors occur in a LTO build for some reason:
#
#   dwz: debian/firefox/usr/lib/firefox/libmozavcodec.so: Unknown DWARF DW_OP_0
#   dwz: debian/firefox/usr/lib/firefox/libmozavutil.so: Unknown DWARF DW_OP_183
#   dwz: debian/firefox/usr/lib/firefox/libmozavcodec.so: Unknown DWARF DW_OP_0
#   dwz: debian/firefox/usr/lib/firefox/libmozavutil.so: Unknown DWARF DW_OP_183
#
perl -pi -e '/dh_dwz -X libxul/ and s/$/ \\\n\t\t-X libmozav  # XtraDeb: needed to avoid LTO build breakage/' \
	$debian/rules

################################################################

finish

# Add a "1:" epoch prefix to the version, so that the firefox snap package
# isn't outright considered newer
perl -pi \
	-e 'if (/^firefox / && $. == 1) {' \
	-e '  s/\((.+)\)/(1:$1)/;' \
	-e '}' \
	$debian/changelog

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
	(unset MAKEFLAGS; cd $debian/.. && set -x && debian/rules $files_to_regen TESTDIR=) || exit
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

echo "Firefox package conversion for '$ubuntu_dist' complete."

# end firefox.sh
