# pkg/icu/script.sh
#
# https://packages.debian.org/source/sid/icu#pdownload
# https://packages.ubuntu.com/source/icu
#

################################################################

xd_convert() {

ubuntu_dist jammy VENDOR || not_applicable

add_to_changelog << END
NOTE: This package has been modified to provide static libraries only.
It is intended solely for use as a build dependency.
END

if ubuntu_dist jammy
then
	# Use pkg-config instead of pkgconf as the former is better
	# supported on jammy (i.e. it has an i386 build, is in main
	# instead of universe...)
	sed -i '/^Build-Depends:/ s/\bpkgconf,/pkg-config,/' $debian/control
fi

# Build only static libraries (for better build-dep hygiene)
zap_control_package 'libicu\d\d' $debian/control
sed -ri '/^Depends:/ s/ libicu[0-9]{2} [^,]+,//' $debian/control
sed -ri '/dh_auto_configure/ s/(--enable-static) /\1 --disable-shared /' \
	$debian/rules
sed -i '/\.so$/ d' $debian/libicu-dev.install

# Avoid link errors like "relocation R_X86_64_PC32 against symbol `...'
# can not be used when making a shared object; recompile with -fPIC"
sed -i \
	-e '/^export DEB_CXXFLAGS_MAINT_APPEND/ {' \
	-e 's/$/ -fPIC/' \
	-e 'i export DEB_CFLAGS_MAINT_APPEND = -fPIC' \
	-e '}' \
	$debian/rules

##
## Patch series modifications
##

if ubuntu_dist jammy noble
then
	new_patch xtradeb-autoconf-downgrade.patch
fi

if ubuntu_dist jammy
then
	new_patch xtradeb-ignore-intltest.patch
fi

} # xd_convert()

################################################################

# end pkg/icu/script.sh
