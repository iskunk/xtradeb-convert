#!/bin/bash
# chromium.sh
#
# This script operates on the debian/ subdirectory of a
# Debian chromium source package, as available from
# https://packages.debian.org/source/sid/chromium#pdownload
#

debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize chromium

if ! grep -Eq '^Source: (ungoogled-)?chromium$' $debian/control 2>/dev/null
then
	echo "$0: error: $debian: not an (ungoogled-)chromium source package debian/ subdirectory"
	exit 1
fi

################################################################

# Comment out Debian bookmarks
perl -pi \
	-e '$d=/<DT>.*www\.debian\.org/;' \
	-e '$d&&!$pd and print"<!-- XtraDeb edit --\n";' \
	-e '!$d&&$pd and print"-- XtraDeb additions follow -->\n";' \
	-e '$pd=$d' \
	$debian/initial_bookmarks.html

cat >$debian/xtradeb.tmp <<END
        <DT><A HREF="https://www.ubuntu.com/" ICON="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACSklEQVQ4jX1TXWhSYRj+ZMxRN7vpZuwiRrBREchgxS6CQXTn1EULyWiFdIQQRCu6yI0Yg4KUJIOhNCSiusqLbmSMLroQ2WgRw5Oxc456NHeOOmPqMX/W4ekm/46uF76bl/d53p/n+QhRRImLjWf9Djdvm9xmZ1UyO6uSedvkdtbvcJe42LiyvisKQZedMQzWWC1Bv8cYBmuFoMveA6RpWv3z0aWNo4CslqDOx9BIMw1Wp5IzzsvrNE2rWwSi59arLoBOhZzHitLGW5Q/vYewNIc6t4NGhgOrU4HVEmT9DjchhBBpd0vD6lRyE5yyTkNcMaGyuY5m1PkYhKU5JG+e6mwil5mvZ4jopXzNZPzaCVS/b6KeoBE3jiB5ewKJ66PIeayQpSL+HOTB3znXIskFHj4hSfMY10wUXi8DAPKrD3pukHVRAAAp/LGVS1omYoTVEvx69xTybwl7Tj3qfAzx+eEeAu7KcRRDARwEX7ZV0Q80CKMfaBTWFiFLRaTtMzjMpsAZ1H2VSNsugrdoOkiPVUh8YTTdWmFtEQCw59T3gu0zAIBiKNC9gvjM9KZ1xPlh1H58QTUaQdw4gsSNk+AMagjLRjQyHA73M11KCF7LKqlEw1OdncQVE7IuCuXPH9oycjsQHl9F0nxaIeO3s4QQQoTnCwHlyPkXNhRDARRDAaTunkc1GkE1Gmk38lK+lhMZhhlK37sQ+Z+V/60ms1qC9P3pcJeVmyT9JlE+0Uv5GIYZOvJHVqLhKdFL+ToNljSPcaKX8km7Wxpl/V9ZLTo82gQ36wAAAABJRU5ErkJggg==">Ubuntu</A>
        <DT><A HREF="https://xtradeb.net/" ICON="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACkUlEQVQ4jY2TX2jNYRjHP8/7vme//TlYOgodMhobWtyQuxOZ3Yhku3Eh1ERKSlyQCFdEiIiliIZyoYgVm1JbQtr2syQzjSaMcHZ2/vze93Ux/yLyvXl6+n6/z/P0rQf+A5dBA3RCVTd0hND+BCoBzB/ienT9O0TaiNILqQ0CtjpPWa6IlmfXSIyB+Rr4CJuAzX8MaLiC/dHEWG0CFuNg2DK5qJST6Qw5BS4HHQDyq9nvZrwrY5kzdEaPidkBrirFZ+v5II6kGk//xy5aC4MUEtU8ibdwwXgQUmhpI7Kl7NIlbFAWqOKI66XWlvAq3sJgZj1zcewsn0iDSTLWRpSl63j/4wJ/jKpomC5ThNgCfdqzRLbx/DsfHWKp3sKtoRSrYiU0KUFyjlBlapmUraNx+BFzlSbEoJ3joGzjuW8kBpA+zhwf8VmEfPwuZ/OeDuvBCk3KCeeUYpPtY130hmZXYIiI+x6EU0SdZayxl7iYbWO2/5ZZzHDeCrvG3OSwAaoLjoeiqPBphryngB0R7gHZWElKvaPaaaYJeA/SfZ1BB28BlHM0GkGrgDOmghodUE7AHAE/U5BxlWxnKqdVwAKfwgh4YIOGoz0w/WeIJ5gaDRGaGLGoQGjy1MkOBgBeTKE4UUUoir3hDZ6WQ4uCeA7aFSAelGykVzzNxNBmNDW2mGMhxPuTlFT0kZU8+3yeA3HN1QDiHvDQZEbqCHSenVYo1oZMrp92C9e/vKK4G1723mHGlHkkEtUMvO+h1Vru10DTvx6oqAsevgX/GnwIfmAGbdl60pkVPM3UMh9A/W70IK0pTAPkDez/BD2foD+C5tIkb0hi9Sy0C5j+1+2/4h6MegATdoPKLGJldi23/SmWf+e/AvzuCKinXVlBAAAAAElFTkSuQmCC">XtraDeb</A>
END

# Add Ubuntu and XtraDeb bookmarks
(cd $debian && \
	sed -i '/XtraDeb additions/ r xtradeb.tmp' initial_bookmarks.html)

rm -f $debian/xtradeb.tmp

# Avoid setting an empty value here
sed -i '/^export CLANG_MVERS *=/s/\bDebian\b/Ubuntu/' $debian/rules

# /etc/debian_version is not meaningful on an Ubuntu system
# (Note that lsb_release(1) sometimes prints "No LSB modules are available")
sed -i '/@BUILD_DIST@/s!\bcat /etc/debian_version\b!lsb_release -rs 2>/dev/null!' $debian/rules

# Also update the launcher script in the same way
# (note: script could be named "ungoogled-chromium")
sed -i \
	-e '/^DIST=/s!\bcat /etc/debian_version\b!lsb_release -rs 2>/dev/null!' \
	-e '/^export CHROME_VERSION_EXTRA=/s/\bDebian\b/Ubuntu/g' \
	$debian/scripts/*chromium

# Enable thin LTO for better performance
# https://bugs.debian.org/1033305
# (Conditionally exclude armhf, which cannot muster the necessary RAM)
thin_lto=yes
if [ $thin_lto = yes ]
then
	# Note: use_thin_lto=true requires concurrent_links to be unset
	sed -i \
		-e '/\buse_thin_lto=false\b/d' \
		-e '/\bconcurrent_links=1\b/d' \
		$debian/rules

	# TODO: check if i386 needs to be excluded too
	cat >$debian/xtradeb.tmp <<'END'
# XtraDeb: use ThinLTO everywhere except for armhf (insufficient RAM)
ifeq ($(filter armhf,$(DEB_HOST_ARCH)),)
defines+=use_thin_lto=true
ifneq ($(filter arm64,$(DEB_HOST_ARCH)),)
# final link takes >150m, don't let Launchpad kill the build prematurely
keepalive=debian/scripts/keepalive-wrapper.py 7200
endif
else
defines+=use_thin_lto=false concurrent_links=1
endif
END
	(cd $debian && \
		sed -i -r -e '/^defines\+=host_cpu=."arm."/{N;r xtradeb.tmp' -e '}' rules)
	rm -f $debian/xtradeb.tmp
	perl -pi -e 's/(ninja .* chrome )/\$(keepalive) $1/' $debian/rules

	# Borrow the keepalive wrapper from the Ubuntu 20.04 Firefox build
	cp -fp $base_dir/_chromium/keepalive-wrapper.py $debian/scripts/
fi

################################################################
##
## Modifications to allow building on Ubuntu jammy and later
##
################################################################

if ubuntu_dist jammy
then
	# Jammy's older GN chokes on syntax in build/nocompile.gni
	cat >$debian/xtradeb.tmp <<'END'
# XtraDeb
defines+=enable_nocompile_tests=false

END
	(cd $debian && sed -i '/^# enabled features/e cat xtradeb.tmp' rules)
	rm -f $debian/xtradeb.tmp

	# Fix V4L breakage on arm64/armhf due to older kernel headers:
	#
	#   media/gpu/chromeos/fourcc.cc:357:31: error: use of undeclared identifier 'V4L2_PIX_FMT_MM21'
	#   static_assert(Fourcc::MM21 == V4L2_PIX_FMT_MM21, "Mismatch Fourcc");
	#                                 ^
	#   media/gpu/chromeos/fourcc.cc:360:31: error: use of undeclared identifier 'V4L2_PIX_FMT_P010'
	#   static_assert(Fourcc::P010 == V4L2_PIX_FMT_P010, "Mismatch Fourcc");
	#                                 ^
	#   media/gpu/v4l2/v4l2_video_decoder_backend_stateless.cc:695:7: error: use of undeclared identifier 'V4L2_PIX_FMT_HEVC_SLICE'
	#         V4L2_PIX_FMT_HEVC_SLICE,
	#         ^
	#   media/gpu/v4l2/v4l2_video_decoder_backend_stateless.cc:698:7: error: use of undeclared identifier 'V4L2_PIX_FMT_VP9_FRAME'
	#         V4L2_PIX_FMT_VP9_FRAME,
	#         ^
	# The below edits use the same settings as the bullseye build.
	# Related: https://bugs.debian.org/1011346
	perl -pi \
		-e '/^defines\+=host_cpu=."arm64."/ and s/use_v4l2_codec=true (use_vaapi)=false/$1=true/;' \
		-e '/^defines\+=host_cpu=."arm."/ and s/\s*use_v4l2_codec=true//' \
		$debian/rules
fi

##
## Patch series modifications
##

if ubuntu_dist jammy mantic
then
	new_patch bookworm/bubble-contents.patch
fi

if ubuntu_dist jammy
then
	new_patch bookworm/constcountrycode.patch
	new_patch bookworm/generate-ninja.patch

	# Can't handle the Rust build
	sed -i -r '/^ +rustc .+,$/d' $debian/control
	perl -pi -e '/^defines\+=rustc_version=/ and $_.="defines+=enable_rust=false\n"' \
		$debian/rules

	new_patch bookworm/undo-rust-req.patch
fi

if ubuntu_dist jammy && \
   ! grep -Fqx bullseye/av1-vaapi.patch $debian/patches/series
then
	new_patch bullseye/av1-vaapi.patch
	new_patch bullseye/framesensorconst.patch
fi

if ubuntu_dist jammy
then
	disable_patch fixes/absl-optional.patch
	new_patch xtradeb/absl-optional-libstdc++-11.patch
fi

if ubuntu_dist mantic noble
then
	new_patch xtradeb/clang-match-rust-target.patch
fi

if ubuntu_dist jammy
then
	new_patch xtradeb/fix-constexpr.patch
fi

# TEMPORARY: Remove once Timothy Pearson's patches incorporate this
# https://github.com/ungoogled-software/ungoogled-chromium-debian/issues/334#issuecomment-1767888316
# https://github.com/ungoogled-software/ungoogled-chromium-debian/issues/334#issuecomment-1769452191
new_patch xtradeb/fix-ppc64el-lto.patch

if ubuntu_dist noble
then
	new_patch xtradeb/fortify-level-3.patch
fi

if [ $thin_lto = yes ]
then
	# Needed for Clang 16 generally
	new_patch xtradeb/lld-options.patch
fi

################################################################

finish

echo "Chromium package conversion for '$ubuntu_dist' complete."

# end chromium.sh
