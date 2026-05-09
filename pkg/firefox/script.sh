# pkg/firefox/script.sh
#
# https://packages.debian.org/source/sid/firefox#pdownload
# https://packages.debian.org/source/sid/firefox-esr#pdownload
#

################################################################

xd_convert() {

test -f $debian/browser.README.Debian.in \
|| error "$debian: not a Debian firefox source package debian/ subdirectory"

is_esr=$(grep -qx 'Source: firefox-esr' $debian/control && echo true || echo false)

# https://wiki.mozilla.org/Distribution_INI_File

test ! -f $debian/distribution.ini \
|| error 'package already has distribution.ini file'

cat > $debian/distribution.ini << END
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

cat >> $debian/browser.install.in << END

# XtraDeb addition
debian/distribution.ini usr/share/@browser@/distribution
END

# Don't need (fake)root to build the package
sed -i '/^Build-Depends:/ i Rules-Requires-Root: no' $debian/control.in

# Launchpad's amd64 and ppc64el builders don't have enough (virtual) memory
# to build Firefox, so use our builder-tweak package to add more swap.
sed -ri 's/^(\s+)libx11-dev,$/\1xtradeb-builder-tweak <!noxtradeb>,\n\0/' \
	$debian/control.in

# Submitted upstream at
# https://salsa.debian.org/mozilla-team/firefox/-/merge_requests/12 (ESR)
# https://salsa.debian.org/mozilla-team/firefox/-/merge_requests/13 (reg.)
cat >> $debian/make.mk << END

# XtraDeb additions

# Don't use the default LTO options, as they make for an expensive build
export DEB_BUILD_MAINT_OPTIONS += optimize=-lto
END

cat >> $debian/browser.mozconfig.in << END

# XtraDeb additions
%if DEB_HOST_ARCH != armhf
%if DEB_HOST_ARCH != i386
ac_add_options --enable-rust-simd
%endif
%endif
%if DEB_BUILD_ARCH != armhf
%if DEB_HOST_ARCH != riscv64
# armhf: Causes OOM failures
# riscv64: Causes "relocation R_RISCV_JAL out of range" link errors
ac_add_options --enable-lto=thin
%endif
%endif
END

# Make DEB_BUILD_ARCH usable in preprocessor inputs
sed -i '/^\$(PREPROCESSED_FILES): VARS =/ s/$/  DEB_BUILD_ARCH/' \
	$debian/rules

# Even thin LTO is too much for armhf:
#
#   error: failed to mmap file '.../armv7-unknown-linux-gnueabihf/.../libstyle-<mumble>.rlib': Cannot allocate memory (os error 12)
#   error: could not compile `gkrust` (lib) due to 1 previous error
#
sed -ri \
	-e 's/^# Use thinLTO (on armhf)/# Disable LTO \1/' \
	-e 's/^(export DEBIAN_RUST_LTO=-Clto)=thin/\1=off/' \
	$debian/rules

# Use lld for faster linking
perl -pi -e '/^(\s+)clang,/ and $_.="${1}lld,\n"' \
	$debian/control.in

sed -ri \
	-e 's/^(\s+clang),/\1-'"$llvm_version"',/' \
	-e 's/^(\s+libclang)-dev,/\1-'"$llvm_version"'-dev,/' \
	-e 's/^(\s+libclang-rt)-(dev-wasm32),/\1-'"$llvm_version"'-\2,/' \
	-e 's/^(\s+libc\+\+)-(dev-wasm32),/\1-'"$llvm_version"'-\2,/' \
	-e 's/^(\s+lld),/\1-'"$llvm_version"',/' \
	-e 's/^(\s+llvm)-dev,/\1-'"$llvm_version"'-dev,/' \
	$debian/control.in

sed -ri \
	-e "s!^(CC :=) clang.*!\\1 clang-$llvm_version!" \
	-e "s!^(CXX :=) clang\+\+.*!\\1 clang++-$llvm_version!" \
	$debian/rules

if ubuntu_dist noble
then
	# https://github.com/llvm/llvm-project/issues/131394
	cat > $debian/xtradeb.tmp << 'END'

ifeq (ppc64el,$(DEB_HOST_ARCH))
# Avoid "Undefined temporary symbol .L_MergedGlobals.*" link errors
CXXFLAGS += -mllvm -enable-global-merge=FALSE
LDFLAGS += -Wl,-mllvm,-enable-global-merge=FALSE
endif
END
	(cd $debian && sed -i '/call lazy,LDFLAGS,/ r xtradeb.tmp' rules)
	rm $debian/xtradeb.tmp
fi

cat >> $debian/browser.mozconfig.in << END
ac_add_options --enable-linker=lld-$llvm_version
END

# Ubuntu provides version-in-name cargo/rustc packages
sed -ri 's/^(\s+(cargo|rustc)) \(>= (@RUST_VERSION@)\),/\1-\3,/' \
	$debian/control.in

sed -ri 's/^(%define RUST_VERSION) .*/\1 '"$rust_version"'/' \
	$debian/control.in

cat >> $debian/browser.mozconfig.in << END
ac_add_options CARGO=cargo-$rust_version
ac_add_options RUSTC=rustc-$rust_version
END

# DIST needs to be set properly
sed -i 's/^DIST = unknown/DIST = $(DEB_DISTRIBUTION)/' \
	$debian/upstream.mk

# Extend distribution-release-specific conditionals with Ubuntu names
# (note: line continuations are not supported by the preprocessor)

# --without-wasm-sandboxed-libraries
sed -i '/^%if DIST == bullseye/ s/$/  || DIST == jammy/' \
	$debian/browser.mozconfig.in

# WebAssembly library dependencies
sed -i '/^%if DIST != bullseye/ s/$/  \&\& DIST != jammy/' \
	$debian/control.in

## SYSTEM_LIBS += nspr vpx
#sed -ri 's/(filter bullseye),/\1  jammy,/' \
#	$debian/rules

# SYSTEM_LIBS += nss
sed -ri 's/(filter bullseye bookworm trixie),/\1  jammy noble questing resolute,/' \
	$debian/rules

## This conditional doesn't handle USE_SYSTEM_NSS=0 properly
#perl -pi -e 's/^\%ifndef (USE_SYSTEM_NSS)$/\%if !$1/' \
#	$debian/browser.install.in \
#	$debian/browser.lintian-overrides.in

# Use a keepalive wrapper, as some link operations take a long time
cp $base_dir/pkg/chromium/keepalive-wrapper.py $debian/
sed -ri 's!^(\s+\+)(dh_auto_build)!\1debian/keepalive-wrapper.py 3600 \2!' \
	$debian/rules

news=$resource_dir/NEWS.XtraDeb.html
if [ -f $news ]
then
	# Show a post-upgrade notice to the user

	cp $news $debian/

	test ! -e $debian/policies.json \
	|| error 'debian/policies.json file is already present'

	# The startup.homepage_override_url pref does not appear to be
	# usable; only a policy setting has the desired effect.
	#
	# For documentation on Firefox policies, see
	# https://mozilla.github.io/policy-templates/

	cat > $debian/policies.json << END
{
  "policies": {
    "OverridePostUpdatePage": "file:///usr/share/doc/firefox/NEWS.XtraDeb.html"
  }
}
END
	# Note: usr/lib/@browser@/distribution is a symlink to
	# usr/share/@browser@/distribution; see browser.links.in
	cat >> $debian/browser.install.in << END

debian/NEWS.XtraDeb.html usr/share/doc/@browser@
debian/policies.json usr/share/@browser@/distribution
END
fi

if false # ! $is_esr
then
	# Transition from firefox-mt

	for dh_type in conffiles maintscript
	do
		test \
			! -e $debian/browser.$dh_type -a \
			! -e $debian/browser.$dh_type.in \
		|| error "debian/browser.$dh_type* file is already present"
	done

	# Remove obsolete config files
	cat > $debian/browser.conffiles.in << END
remove-on-upgrade /etc/apport/blacklist.d/@browser@
remove-on-upgrade /etc/apport/native-origins.d/@browser@
remove-on-upgrade /etc/@browser@/syspref.js
END

	# A few paths change from directories to symlinks, and we need
	# to handle those specially if we want the correct result
	for subdir in \
		browser/chrome \
		browser/defaults \
		distribution
	do
		cat >> $debian/browser.maintscript.in << END
dir_to_symlink /usr/lib/@browser@/$subdir /usr/share/@browser@/$subdir 1:139.0~ @browser@
END
	done
fi

# When we regenerate files below, avoid creating anything outside of the
# debian/ tree (specifically, the stamps/ directory and/or files therein)
sed -i \
	-e '/mkdir -p stamps/ i ifndef XTRADEB_CONVERT' \
	-e '/if.*wildcard.*touch/ a endif # XTRADEB_CONVERT' \
	$debian/rules

##
## Patch series modifications
##

if ! $is_esr
then
	new_patch xtradeb/ffmpeg-vulkan-armhf.patch
fi

# https://bugs.launchpad.net/bugs/2033572
if ubuntu_dist resolute
then
	new_patch xtradeb/fix-libc++-wasm-link-error.patch
fi

new_patch xtradeb/fix-param-lto-partitions.patch

if $is_esr
then
	new_patch xtradeb/fortify-source-esr.patch
	new_patch xtradeb/python-314-update.patch
else
	new_patch xtradeb/fortify-source.patch
	new_patch xtradeb/jit-simulator-riscv64.patch
fi

if ubuntu_dist resolute
then
	if $is_esr
	then
		new_patch xtradeb/libyuv-rvv-support-esr.patch
		new_patch xtradeb/resolute-fixes-esr.patch
		new_patch xtradeb/resolute-fixes-checksums.patch
	else
		new_patch xtradeb/libyuv-rvv-support.patch
	fi
fi

if ! $is_esr
then
	new_patch xtradeb/ppc64el-workaround-for-llvm-assembler.patch

	if ubuntu_dist jammy noble
	then
		new_patch xtradeb/riscv-no-unistd64.patch
	fi

	new_patch xtradeb/xsimd-ppc64el.patch
fi

if [ $source_name = firefox ]
then
	need_version_epoch_bump=yes
fi

} # xd_convert()

################################################################

xd_convert_post() {

# Regenerate files
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
	(unset MAKEFLAGS; cd $debian/.. && set -x && debian/rules $files_to_regen TESTDIR= XTRADEB_CONVERT=1) \
	|| error 'failed to regenerate debianization files'
	rm -r  $debian/.mozbuild
	rm -rf $debian/objdir	# firefox-esr has this, but not firefox
	echo
else
	cat << END

Note: Please run

  \$ cd $(cd $debian/.. && pwd)
  \$ debian/rules $files_to_regen

in the Firefox source tree, to regenerate necessary files.

END
fi

} # xd_convert_post()

################################################################

# end pkg/firefox/script.sh
