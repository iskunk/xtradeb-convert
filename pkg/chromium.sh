#!/bin/bash
# chromium.sh
#
# This script operates on the debian/ subdirectory of a
# Debian chromium source package, as available from
# https://packages.debian.org/source/sid/chromium#pdownload
#

# chromium/debian/ directory location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize chromium

grep -Eq '^Source: (ungoogled-)?chromium$' $debian/control 2>/dev/null \
|| error "$debian: not an (ungoogled-)chromium source package debian/ subdirectory"

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

cat >$debian/xtradeb.tmp <<'END'
ifneq ($(filter arm64,$(DEB_BUILD_ARCH)),)
# final link takes >150m, don't let Launchpad kill the build prematurely
keepalive=debian/scripts/keepalive-wrapper.py 7200
endif
END
if ubuntu_dist noble oracular
then
	cat >>$debian/xtradeb.tmp <<'END'
ifneq ($(filter armhf arm64,$(DEB_HOST_ARCH)),)
# clang-16 gives us "argument unused during compilation" warnings for these
export   DEB_CFLAGS_MAINT_STRIP+=-fstack-clash-protection -fno-stack-clash-protection
export DEB_CXXFLAGS_MAINT_STRIP+=-fstack-clash-protection -fno-stack-clash-protection
endif
END
fi
(cd $debian && \
	sed -i -r -e '/^defines\+=host_cpu=."arm."/{N;r xtradeb.tmp' -e '}' rules)
rm -f $debian/xtradeb.tmp
perl -pi -e 's/(ninja .* chrome )/\$(keepalive) $1/' $debian/rules

# Borrow the keepalive wrapper from the Ubuntu 20.04 Firefox build
cp -fp $base_dir/_chromium/keepalive-wrapper.py $debian/scripts/

perl -pi \
	-e '/ninja .+ chrome/ and $_= <<END . $_;' \
	-e '	# XtraDeb workaround for https://crbug.com/40943790' \
	-e '	ninja -j\$(njobs) -C out/Release ui/webui/resources/cr_components/history_clusters:build_ts' \
	-e 'END' \
	$debian/rules

if ubuntu_dist oracular
then
	# There is no longer a plain "rustc" package
	perl -pi -e 's/^(\s+rustc) \(.+\),/$1-1.80,/' \
		$debian/control
	perl -pi -e 's!^(rust_sysroot)=.*!$1=/usr/lib/rust-1.80!' \
		$debian/rules
fi

################################################################
##
## Modifications to allow building on Ubuntu jammy and later
##
################################################################

# rustc-web is only available in Debian (old)stable
sed -i -r 's/\b(rustc)-web,/\1,/' $debian/control

# Don't do the bindgen hack, it's not needed
sed -i -r \
	-e '/^defines\+=rust_bindgen_root=/s!\$\(CURDIR\)/debian/bindgen/root!!' \
	-e '/^override_dh_auto_configure:/s/ set_up_bindgen\b//' \
	$debian/rules

if ubuntu_dist jammy noble
then
	# Build with clang-18 instead of -19
	sed -i -r '/(clang|libc\+\+|lld)/s/19/18/' \
		$debian/control \
		$debian/rules \
		$debian/patches/debianization/clang-version.patch
fi

if ubuntu_dist jammy
then
	# The libgtk-3-0t64 package is not available until noble
	sed -i -r 's/\b(libgtk-3-0)t64\b/\1/' $debian/control

	# Statically link the libc++-18 libraries, as they are not normally
	# available in jammy (note: -static-libstdc++ does apply to libc++,
	# the option is just inappropriately named)
	sed -i -r '/^export LDFLAGS=/s!$! -static-libstdc++ -L/usr/lib/llvm-$(CLANG_MVERS)/lib -l:libc++abi.a -l:libunwind.a!' \
		$debian/rules

	# Jammy does not have a sufficiently new libspa-0.2-dev to compile
	# Chromium's PipeWire support. Typical compile error:
	#
	#   third_party/webrtc/modules/video_capture/linux/video_capture_pipewire.cc:329:19: error: invalid application of 'sizeof' to an incomplete type 'struct spa_meta_videotransform'
	#        SPA_POD_Int(sizeof(struct spa_meta_videotransform)))));
	#                    ^     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	sed -i '/\brtc_use_pipewire=true\b/d' $debian/rules

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

	# Why this only affects jammy is unclear, but the linker adds a
	# spurious run-time dependency on libtest_trace_processor.so to the
	# chromium-shell binary. This is a test-related library that is not
	# packaged.
	perl -pi \
		-e '/# XtraDeb workaround/ and $_= <<END . $_;' \
		-e '	# Avoid chromium-shell -> libtest_trace_processor.so dependency' \
		-e '	sed -i \x{27}/^  solibs =/s! \\./libtest_trace_processor\\.so!!\x{27} out/Release/obj/content/shell/content_shell.ninja' \
		-e 'END' \
		$debian/rules
fi

##
## Patch series modifications
##

if ubuntu_dist jammy
then
	new_patch bookworm/bubble-contents.patch
fi

if ubuntu_dist jammy noble
then
	new_patch bookworm/cacheline.patch
	new_patch bookworm/gn-absl.patch
	new_patch bookworm/gn-funcs.patch
	new_patch bookworm/highway-blink.patch

	# Don't require a bleeding-edge version of LibXML2
	# (note that Debian's package of 2.12 is now actually 2.9)
	perl -pi -e '/^\s+libxml2-dev\b/ and s/\(.+\),/(<< 2.10),/' \
		$debian/control
else
	# The LibXML2 2.12 package in oracular is (still) the real deal
	disable_patch bookworm/libxml-parseerr.patch
fi

if ubuntu_dist jammy
then
	new_patch bullseye/framesensorconst.patch
	new_patch xtradeb/av1-vaapi.patch
fi

if ubuntu_dist jammy noble
then
	new_patch xtradeb/clang-unknown-options.patch
fi

if ubuntu_dist jammy
then
	new_patch xtradeb/fix-constexpr.patch
fi

if ubuntu_dist noble oracular
then
	new_patch xtradeb/fortify-level-3.patch
fi

if ubuntu_dist jammy
then
	new_patch xtradeb/icf-arm.patch
	new_patch xtradeb/libdav1d-fields.patch
	new_patch xtradeb/openjpeg-no-strict-mode.patch
fi

new_patch xtradeb/warning-fixes.patch

################################################################

finish

echo "Chromium package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end chromium.sh
