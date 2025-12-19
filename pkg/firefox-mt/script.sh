# pkg/firefox-mt/script.sh
#
# Operates on a Mozilla Team PPA firefox source package; see
# https://launchpad.net/~mozillateam/+archive/ubuntu/ppa/+packages
# https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu/pool/main/f/firefox/
#

multi_dist=yes

################################################################

xd_convert() {

# Need cdbs to regenerate the control file
dpkg --status cdbs >/dev/null \
|| error '"cdbs" package is required to regenerate files'

head -n1 $debian/changelog \
| grep -Pq '.-0ubuntu0\.\d\d\.\d\d\.1~mt\d\) ' \
|| error "$debian: not a Mozilla Team PPA firefox source package debian/ subdirectory"

################################################################

# https://wiki.mozilla.org/Distribution_INI_File

# Add Ubuntu and XtraDeb bookmarks
cat >>$debian/distribution.ini <<END

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

# Use thin LTO (on 64-bit builders) for better performance
cat >> $debian/config/mozconfig.in << END

# XtraDeb additions
%%if DEB_BUILD_ARCH_BITS == 64
ac_add_options --enable-lto=thin
%%endif
END

# Enable ALSA support
x=$debian/../toolkit/moz.configure
test ! -f $x || grep -q .--enable-alsa $x \
|| error 'ALSA support appears to be missing'
cat >> $debian/config/mozconfig.in << END
ac_add_options --enable-alsa
END

# Don't reduce LTO strength on arm64; the builders can handle it
sed -i -r '/filter arm64 armhf/s/(arm64)/xtradeb-\1/' \
	$debian/build/rules.mk
sed -i -r '/filter aarch64 arm/s/(aarch64)/xtradeb-\1/' \
	$debian/patches/armhf-rustc-thin-lto.patch
patch_series_changed=yes

# The armhf builders, however, can't do Rust thin LTO at all
sed -i 's/lto = "thin"/lto = "off"/' $debian/build/rules.mk

# Allow unsigned extensions in system dirs
perl -pi -e '/^ac_add_options --with-unsigned-addon-scopes=app/ && !/system/ and s/$/,system/' \
	$debian/config/mozconfig.in

# Don't print keepalive messages so frequently
sed -i -r 's/^(\s*target_timeout) = 60$/\1 = 900/' \
	$debian/build/keepalive-wrapper.py

# Don't need (fake)root to build the package
sed -i '/^Build-Depends:/ i Rules-Requires-Root: no' $debian/control.in

# Narrow the LLVM dependencies to a single version, as the alternations
# that allow the use of multiple versions unfortunately do not ensure that
# the versions installed are consistent (e.g. clang-20 + llvm-19-dev).
case $ubuntu_dist in
	jammy | noble) llvm_version=19 ;;
	*) llvm_version=20 ;;
esac
grep -q '^\s*clang-20 | clang-19 | clang-18,' $debian/control \
|| error 'debian/control no longer specifies clang-{20,19,18}'
perl -pi \
	-e 'if (/^\s*((lib)?clang|llvm)-20(-dev)? /) {' \
	-e '  s/ \|[^,]+//;' \
	-e '  s/-\d\d/-'"$llvm_version"'/;' \
	-e '}' \
	$debian/control.in

if ! grep -Fq "rustc-$rust_version" $debian/control.in
then
	sed -i -r 's/^(\s+)(cargo|rustc)-/\1\2-'"$rust_version"' | \2-/' \
		$debian/control.in
	sed -i -r 's/^(RUSTC_VERSIONS =)\s*/\1 '"$rust_version"' /' \
		$debian/build/rules.mk
fi

# Don't build for armhf, as it is prone to failing with
#
#   13:03.67 rustc-LLVM ERROR: out of memory
#   13:03.67 Allocation failed
#   13:04.07 error: could not compile `firefox-on-glean` (lib)
#
sed -i -r 's/^(Architecture): any$/\1: amd64 arm64 ppc64el riscv64 s390x/' \
	$debian/control.in \
	$debian/control.langpacks \
	$debian/control.langpacks.unavail

################################################################
##
## Modifications to allow building on Ubuntu jammy and later
##
################################################################

# Note: Modify "control.in", not "control". The latter will be regenerated
# after changes to the former are complete.

# Bump up debhelper compat level to 10 (quells warnings)
sed -i -r '/^\s+debhelper \(>= 9\),/s/9/10/' $debian/control.in

# Also needed for debhelper
echo 10 > $debian/compat

##
## Patch series modifications
##

# (none at present)

need_version_epoch_bump=yes

} # xd_convert()

################################################################

xd_convert_post() {

# Remove the (non-XtraDeb) Ubuntu release bit from the version string
sed -ri '1s/0ubuntu0\.[0-9]{2}\.[0-9]{2}\.[0-9]~mt//' \
	$debian/changelog

# Regenerate control file
ln -s . $debian/debian || exit
(unset MAKEFLAGS; cd $debian && set -x && debian/rules debian/control) \
|| error 'failed to regenerate debianization files'
rm $debian/debian

} # xd_convert_post()

################################################################

# end pkg/firefox-mt/script.sh
