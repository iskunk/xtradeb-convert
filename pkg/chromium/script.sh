# pkg/chromium/script.sh
#
# https://packages.debian.org/source/sid/chromium#pdownload
#

################################################################

xd_convert() {

# Comment out Debian bookmarks
perl -pi \
	-e '$d=/<DT>.*www\.debian\.org/;' \
	-e '$d&&!$pd and print"<!-- XtraDeb edit --\n";' \
	-e '!$d&&$pd and print"-- XtraDeb additions follow -->\n";' \
	-e '$pd=$d' \
	$debian/initial_bookmarks.html

cat > $debian/xtradeb.tmp << END
        <DT><A HREF="https://www.ubuntu.com/" ICON="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACSklEQVQ4jX1TXWhSYRj+ZMxRN7vpZuwiRrBREchgxS6CQXTn1EULyWiFdIQQRCu6yI0Yg4KUJIOhNCSiusqLbmSMLroQ2WgRw5Oxc456NHeOOmPqMX/W4ekm/46uF76bl/d53p/n+QhRRImLjWf9Djdvm9xmZ1UyO6uSedvkdtbvcJe42LiyvisKQZedMQzWWC1Bv8cYBmuFoMveA6RpWv3z0aWNo4CslqDOx9BIMw1Wp5IzzsvrNE2rWwSi59arLoBOhZzHitLGW5Q/vYewNIc6t4NGhgOrU4HVEmT9DjchhBBpd0vD6lRyE5yyTkNcMaGyuY5m1PkYhKU5JG+e6mwil5mvZ4jopXzNZPzaCVS/b6KeoBE3jiB5ewKJ66PIeayQpSL+HOTB3znXIskFHj4hSfMY10wUXi8DAPKrD3pukHVRAAAp/LGVS1omYoTVEvx69xTybwl7Tj3qfAzx+eEeAu7KcRRDARwEX7ZV0Q80CKMfaBTWFiFLRaTtMzjMpsAZ1H2VSNsugrdoOkiPVUh8YTTdWmFtEQCw59T3gu0zAIBiKNC9gvjM9KZ1xPlh1H58QTUaQdw4gsSNk+AMagjLRjQyHA73M11KCF7LKqlEw1OdncQVE7IuCuXPH9oycjsQHl9F0nxaIeO3s4QQQoTnCwHlyPkXNhRDARRDAaTunkc1GkE1Gmk38lK+lhMZhhlK37sQ+Z+V/60ms1qC9P3pcJeVmyT9JlE+0Uv5GIYZOvJHVqLhKdFL+ToNljSPcaKX8km7Wxpl/V9ZLTo82gQ36wAAAABJRU5ErkJggg==">Ubuntu</A>
        <DT><A HREF="https://xtradeb.net/" ICON="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACkUlEQVQ4jY2TX2jNYRjHP8/7vme//TlYOgodMhobWtyQuxOZ3Yhku3Eh1ERKSlyQCFdEiIiliIZyoYgVm1JbQtr2syQzjSaMcHZ2/vze93Ux/yLyvXl6+n6/z/P0rQf+A5dBA3RCVTd0hND+BCoBzB/ienT9O0TaiNILqQ0CtjpPWa6IlmfXSIyB+Rr4CJuAzX8MaLiC/dHEWG0CFuNg2DK5qJST6Qw5BS4HHQDyq9nvZrwrY5kzdEaPidkBrirFZ+v5II6kGk//xy5aC4MUEtU8ibdwwXgQUmhpI7Kl7NIlbFAWqOKI66XWlvAq3sJgZj1zcewsn0iDSTLWRpSl63j/4wJ/jKpomC5ThNgCfdqzRLbx/DsfHWKp3sKtoRSrYiU0KUFyjlBlapmUraNx+BFzlSbEoJ3joGzjuW8kBpA+zhwf8VmEfPwuZ/OeDuvBCk3KCeeUYpPtY130hmZXYIiI+x6EU0SdZayxl7iYbWO2/5ZZzHDeCrvG3OSwAaoLjoeiqPBphryngB0R7gHZWElKvaPaaaYJeA/SfZ1BB28BlHM0GkGrgDOmghodUE7AHAE/U5BxlWxnKqdVwAKfwgh4YIOGoz0w/WeIJ5gaDRGaGLGoQGjy1MkOBgBeTKE4UUUoir3hDZ6WQ4uCeA7aFSAelGykVzzNxNBmNDW2mGMhxPuTlFT0kZU8+3yeA3HN1QDiHvDQZEbqCHSenVYo1oZMrp92C9e/vKK4G1723mHGlHkkEtUMvO+h1Vru10DTvx6oqAsevgX/GnwIfmAGbdl60pkVPM3UMh9A/W70IK0pTAPkDez/BD2foD+C5tIkb0hi9Sy0C5j+1+2/4h6MegATdoPKLGJldi23/SmWf+e/AvzuCKinXVlBAAAAAElFTkSuQmCC">XtraDeb</A>
END

# Add Ubuntu and XtraDeb bookmarks
(cd $debian && \
	sed -i '/XtraDeb additions/ r xtradeb.tmp' initial_bookmarks.html)

if ubuntu_dist noble
then
	cat > $debian/xtradeb.tmp << 'END'
ifneq ($(filter armhf,$(DEB_HOST_ARCH)),)
# clang gives us "argument unused during compilation" warnings for these
export   DEB_CFLAGS_MAINT_STRIP+=-fno-stack-clash-protection
export DEB_CXXFLAGS_MAINT_STRIP+=-fno-stack-clash-protection
endif
END
	(cd $debian && \
		sed -ri -e '/^export DEB_CXXFLAGS_MAINT_STRIP=-g/{r xtradeb.tmp' -e '}' rules)
fi

cat > $debian/xtradeb.tmp << 'END'

# final link takes >150m, don't let Launchpad kill the build prematurely
keepalive=debian/scripts/keepalive-wrapper.py 7200
END
(cd $debian && \
	sed -ri -e '/^defines\+=host_cpu=."loong64."/{N;r xtradeb.tmp' -e '}' rules)
perl -pi -e 's/(ninja .* chrome )/\$(keepalive) $1/' $debian/rules

rm -f $debian/xtradeb.tmp

# Borrow the keepalive wrapper from the Ubuntu 20.04 Firefox build
cp -fp $resource_dir/keepalive-wrapper.py $debian/scripts/

perl -pi \
	-e '/ninja .+ chrome/ and $_= <<END . $_;' \
	-e '	# XtraDeb workaround for https://crbug.com/40943790' \
	-e '	ninja \$(CR_VERBOSE) -j\$(njobs) -C out/Release ui/webui/resources/cr_components/history_clusters:build_ts' \
	-e 'END' \
	$debian/rules

################################################################
##
## Modifications to allow building on Ubuntu jammy and later
##
################################################################

# Are we using libc++ (Clang) instead of libstdc++ (GNU)?
use_libcxx=$(grep -q '^\s*libc++-[0-9]*-dev,' $debian/control \
	&& echo true || echo false)

# Are we linking libc++ statically?
static_libcxx=$($use_libcxx \
	&& grep -q '^export LDFLAGS:=.* -static-libstdc++' $debian/rules \
	&& echo true || echo false)

# rustc-web is only available in Debian (old)stable
sed -ri '/^\s+rustc-web(:any)? \(.+\),/ s/-web//' $debian/control

# Ubuntu provides "rustc-N.NN" packages
sed -ri \
	-e 's/^(\s+rustc)(:any)? \(.+\),$/\1-'"$rust_version"'\2,/' \
	-e 's/^(\s+rustfmt)(:any)?,$/\1-'"$rust_version"'\2,/' \
	-e 's/^(\s+libstd-rust)(-dev) \(.+\)/\1-'"$rust_version"'\2/' \
	$debian/control
sed -ri 's!^(rust_sysroot)=.*!\1=/usr/lib/rust-'"$rust_version"'!' \
	$debian/rules

# Don't do the bindgen hack, it's not needed
sed -ri \
	-e '/^defines\+=rust_bindgen_root=/ s!\$\(CURDIR\)/debian/bindgen/root!!' \
	-e '/^override_dh_auto_configure:/ s/ set_up_bindgen\b//' \
	$debian/rules

llvm_version_orig=19

grep -Eq "^\\s+clang-$llvm_version_orig(:\\w+)?,\$" $debian/control \
|| error "original control file does not use clang-$llvm_version_orig"

if [ $llvm_version -ne $llvm_version_orig ]
then
	sed -ri '/(clang|libc\+\+|lld|llvm)/'"s/-$llvm_version_orig/-$llvm_version/" \
		$debian/control \
		$debian/rules \
		$debian/patches/debianization/clang-version.patch
fi

if [ $llvm_version -ge 20 ]
then
	# Over 34K warnings from -Wnontrivial-memcall alone
	x='-Wno-nontrivial-memcall'
	! grep -q ".$x" $debian/rules \
	|| error "d/rules already contains $x flag"

	perl -pi -e '/^(\s+)-Wno-unknown-pragmas / and $_.="$1'"$x"' \\\n"' \
		$debian/rules
fi

if [ $llvm_version/$rust_version != 20/1.91 ]
then
	# Avoid link errors like the following, a result of Rust using an
	# LLVM backend newer than the C++ linker:
	#
	#   ld.lld-20: error: ...: Unknown attribute kind (103) \
	#   (Producer: 'LLVM21.1.2-rust-1.91.1-stable' Reader: 'LLVM 20.1.8')
	#
	# (the conditional above is not a general solution, obviously)
	sed -i '/toolchain_supports_rust_thin_lto=false/ d' $debian/rules
fi

# This package will land in Ubuntu sometime after resolute
sed -ri 's/^\s+esbuild-wasm,/ d' $debian/control

if ubuntu_dist jammy noble && $use_libcxx && ! $static_libcxx
then
	# Statically link the libc++ runtime libraries, as we are using a
	# newer version of LLVM than is available in the official repos
	# (note: -static-libstdc++ does apply to libc++, the option is
	# just inappropriately named)
	sed -ri '/^export LDFLAGS:=/ s/$/ -static-libstdc++/' \
		$debian/rules
	static_libcxx=true
fi

if ubuntu_dist jammy
then
	# The libgtk-3-0t64 package is not available until noble
	sed -ri 's/\b(libgtk-3-0)t64\b/\1/' $debian/control

	# If we are using libstdc++, then use version 12, because 11 has
	# issues with std::string not being constexpr
	$use_libcxx || \
	perl -pi -e '/^(\s+)libclang-\S+-dev,/ and $_.="${1}libstdc++-12-dev,\n"' \
		$debian/control

	# Pkg-config is better supported on jammy
	sed -ri 's/^(\s+)pkgconf,/\1pkg-config,/' $debian/control

	# Jammy does not have a sufficiently new libspa-0.2-dev to compile
	# Chromium's PipeWire support. Typical compile error:
	#
	#   third_party/webrtc/modules/video_capture/linux/video_capture_pipewire.cc:329:19: error: invalid application of 'sizeof' to an incomplete type 'struct spa_meta_videotransform'
	#        SPA_POD_Int(sizeof(struct spa_meta_videotransform)))));
	#                    ^     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	sed -i '/\brtc_use_pipewire=true\b/ d' $debian/rules

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

	# Jammy does not have a recent enough kernel to use the AV1
	# hardware decoder. Also drop the linux-libc-dev build-dep,
	# as it is a proxy for the required kernel version.
	sed -ri '/^defines.=use_av1_hw_decoder=true/ s/^/#xtradeb#/' \
		$debian/rules
	sed -ri '/^\s+linux-libc-dev / d' $debian/control
fi

if ubuntu_dist jammy noble
then
	# Fix OpenH264 breakage due to an older system library:
	#
	#   third_party/webrtc/modules/video_coding/codecs/h264/h264_encoder_impl.cc:483:18: error: no member named 'bPsnrY' in 'Source_Picture_s'
	#     483 |     pictures_[i].bPsnrY = calculate_psnr;
	#         |     ~~~~~~~~~~~~ ^
	#   third_party/webrtc/modules/video_coding/codecs/h264/h264_encoder_impl.cc:484:18: error: no member named 'bPsnrU' in 'Source_Picture_s'
	#     484 |     pictures_[i].bPsnrU = calculate_psnr;
	#         |     ~~~~~~~~~~~~ ^
	#   third_party/webrtc/modules/video_coding/codecs/h264/h264_encoder_impl.cc:485:18: error: no member named 'bPsnrV' in 'Source_Picture_s'
	#     485 |     pictures_[i].bPsnrV = calculate_psnr;
	#         |     ~~~~~~~~~~~~ ^
	#
	# Keep this run of spaces: ..................... vvvvvvvvv
	sed -i '/use_unofficial_version_number=false/ a \         rtc_video_psnr=false \\' \
		$debian/rules
fi

if true
then
	# Prevent the linker from adding a spurious run-time dependency on
	# libtest_trace_processor.so to the chromium-shell binary. This is
	# a test-related library that is not packaged.
	# https://issues.chromium.org/425388883
	perl -pi \
		-e 'if (m!gn gen out/Release! && !$done) {' \
		-e '  $_ .= <<END;' \
		-e '	# Avoid chromium-shell -> libtest_trace_processor.so dependency' \
		-e '	sed -i \x{27}/^  solibs =/ s! \\./libtest_trace_processor\\.so!!\x{27} out/Release/obj/content/shell/content_shell.ninja' \
		-e 'END' \
		-e '  $done = 1;' \
		-e '}' \
		$debian/rules

	# Zap Debian's workaround (ship the library) as we don't need it
	sed -i '/libtest_trace_processor/ d' $debian/*chromium-shell.install
fi

if ubuntu_dist noble
then
	# https://github.com/llvm/llvm-project/issues/131394
	cat > $debian/xtradeb.tmp << 'END'
ifeq (ppc64el,$(DEB_HOST_ARCH))
# Avoid "Undefined temporary symbol .L_MergedGlobals.*" link errors
export CXXFLAGS += -mllvm -enable-global-merge=FALSE
export LDFLAGS += -Wl,-mllvm,-enable-global-merge=FALSE
endif

END
	(cd $debian && sed -i \
		-e '/^# disable clang plugins/{r xtradeb.tmp' -e 'N}' \
		rules)
	rm $debian/xtradeb.tmp
fi

##
## Patch series modifications
##

if ubuntu_dist jammy
then
	new_patch bookworm/dav1d-extern.patch
fi

if dpkg --compare-versions $rust_version le 1.82
then
	new_patch bookworm/derivre-create.patch
fi

if ubuntu_dist jammy noble
then
	new_patch bookworm/gn-absl.patch
	new_patch bookworm/gn-funcs.patch
	new_patch bookworm/gn-hpp11.patch
	new_patch bookworm/gn-path-exists2.patch
	new_patch bookworm/node-esm-dirname.patch
	new_patch bookworm/node18-import.patch

	# Contingent on the version of rust-bindgen
	new_patch bookworm/rust-unsafe-extern.patch
fi

if dpkg --compare-versions $rust_version le 1.82
then
	new_patch bookworm/rust-visibility.patch
fi

if dpkg --compare-versions $rust_version le 1.85
then
	new_patch trixie/adler1.patch
fi

if ubuntu_dist jammy noble questing
then
	new_patch trixie/gn-len.patch
fi

new_patch trixie/gn-module-name.patch

if ubuntu_dist jammy noble questing
then
	new_patch trixie/nodejs-main.patch
fi

if dpkg --compare-versions $rust_version lt 1.87
then
	new_patch trixie/rust-is-multiple-of.patch
fi

if dpkg --compare-versions $rust_version le 1.91
then
	new_patch rust-1.85/file_as_c_str.patch
fi

if dpkg --compare-versions $rust_version lt 1.89
then
	new_patch rust-1.85/jxl-features.patch
	new_patch rust-1.85/jxl-simd-avx512.patch
fi

if ubuntu_dist jammy
then
	new_patch xtradeb/av1-vaapi.patch
	new_patch xtradeb/bindgen-no-c++23.patch
fi

if [ $llvm_version -lt 20 ]
then
	new_patch xtradeb/clang-flags.patch
fi

if ubuntu_dist jammy
then
	new_patch xtradeb/flac-error-status.patch
fi

if ! ubuntu_dist jammy
then
	new_patch xtradeb/fortify-level-3.patch
fi

if ubuntu_dist jammy
then
	new_patch xtradeb/libdav1d-fields.patch
fi

if ubuntu_dist noble
then
	new_patch xtradeb/mksnapshot-arm64-fix.patch
fi

if ubuntu_dist jammy
then
	new_patch xtradeb/openjpeg-no-strict-mode.patch
	new_patch xtradeb/rust-allocator-types.patch
fi

if dpkg --compare-versions $rust_version lt 1.90
then
	new_patch xtradeb/rust-alloc-error-handler.patch
fi

new_patch xtradeb/rustfmt-path.patch

if ubuntu_dist resolute
then
	new_patch xtradeb/seccomp-conflict.patch
fi

new_patch xtradeb/swiftshader-llvm-16.patch

# Disable the loong64 patches, as Ubuntu doesn't support that architecture
sed -i '/^loongarch64/ s/^/#xd#/' $debian/patches/series

} # xd_convert()

################################################################

# end pkg/chromium/script.sh
