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

# Add Ubuntu and XtraDeb bookmarks
# Reference: https://wiki.mozilla.org/Distribution_INI_File
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

# Note: Modify "control.in", not "control". The latter will be regenerated
# after changes to the former are complete.

# Enable ALSA support
x=$debian/../toolkit/moz.configure
test ! -f $x || grep -q .--enable-alsa $x \
|| error 'ALSA support appears to be missing'
cat >> $debian/config/mozconfig.in << END

# XtraDeb additions
ac_add_options --enable-alsa
END

# Allow unsigned extensions in system dirs
perl -pi -e '/^ac_add_options --with-unsigned-addon-scopes=app/ && !/system/ and s/$/,system/' \
	$debian/config/mozconfig.in

# Narrow the LLVM dependencies to a single version, as the alternations
# that allow the use of multiple versions unfortunately do not ensure that
# the versions installed are consistent (e.g. clang-20 + llvm-19-dev).
grep -P '^\s+clang-\d\d \| ' $debian/control | grep -qw clang-$llvm_version \
|| test $ubuntu_dist = VENDOR \
|| error "debian/control does not specify clang-$llvm_version et al."
perl -pi \
	-e 'if (/^\s*((lib)?clang|lld|llvm)-\d\d(-dev)? /) {' \
	-e '  s/ \|[^,]+//;' \
	-e '  s/-\d\d/-'"$llvm_version"'/;' \
	-e '}' \
	$debian/control.in

if ! grep '^LLVM_VERSIONS =' $debian/build/rules.mk | grep -qw $llvm_version
then
	sed -ri "s/^(LLVM_VERSIONS =) */\\1 $llvm_version /" \
		$debian/build/rules.mk
fi

if ! grep -Fq "rustc-$rust_version" $debian/control.in
then
	sed -ri 's/^(\s+)(cargo|rustc)-/\1\2-'"$rust_version"' | \2-/' \
		$debian/control.in
	sed -ri 's/^(RUSTC_VERSIONS =)\s*/\1 '"$rust_version"' /' \
		$debian/build/rules.mk
fi

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
	(cd $debian && sed -i \
		-e '/^# enable the crash reporter/{r xtradeb.tmp' \
		-e 'N}' \
		build/rules.mk)
	rm $debian/xtradeb.tmp
fi

# The cdbs package dropped the entire /usr/share/cdbs/1/class/ directory
# in resolute, which breaks the debianization. Bundle a copy of makefile.mk
# and its dependencies to allow the build to proceed.
if ubuntu_dist resolute
then
	cp -a $resource_dir/cdbs-class $debian/
	sed -i \
		-e '1G' \
		-e '1a # XtraDeb workaround' \
		-e '1a _cdbs_class_path = $(CURDIR)/debian/cdbs-class' \
		-e 's!/usr/share/cdbs/1/class/!$(_cdbs_class_path)/!' \
		$debian/build/rules.mk
fi

##
## Patch series modifications
##

new_patch xtradeb-mach-clobber-hang.patch

if ubuntu_dist jammy noble
then
	new_patch xtradeb-riscv-no-unistd64.patch
fi

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
echo

} # xd_convert_post()

################################################################

# end pkg/firefox-mt/script.sh
