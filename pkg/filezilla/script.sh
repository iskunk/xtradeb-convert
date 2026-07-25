# pkg/filezilla/script.sh
#
# https://packages.debian.org/source/sid/filezilla#pdownload
# https://packages.debian.org/source/sid/fzssh#pdownload
# https://packages.debian.org/source/sid/libfilezilla#pdownload
# https://packages.ubuntu.com/source/filezilla
# https://packages.ubuntu.com/source/fzssh
# https://packages.ubuntu.com/source/libfilezilla
#
# Note: Both filezilla and fzssh depend on libfilezilla.
#

################################################################

xd_convert() {

# filezilla needs a newer version of libboost-regex than jammy provides
# (BOOST_RE_VERSION >= 500; version >= 1.76; see m4/check_regex.m4)
! ubuntu_dist jammy || not_supported

if ubuntu_dist noble
then
	# Downgrade these build-deps
	sed -ri \
		-e '/^\s+libgnutls28-dev / s/>= 3\.8\.4\)/>= 3.8.3)/' \
		-e '/^\s+nettle-dev / s/>= .+\)/>= 3.9.1)/' \
		$debian/control
fi

case $source_name in
	fzssh | libfilezilla)
	add_to_changelog << END
NOTE: This package has been modified to provide static libraries only.
It is intended solely for use as a build dependency.
END
	;;
esac

case $source_name in

	filezilla)

	sed -ri '/^\s+dh_auto_configure/ s/$/  --enable-static --disable-shared/' \
		$debian/rules

	;;
	################################

	fzssh)

	# Making the libraries static means that the libargon2 dependency
	# needs to be specified explicitly
	perl -pi -e 's/^(\s+)libfzssh\d+(\.\d+)* \(= [^)]+\),/${1}libargon2-dev,/' \
		$debian/control

	sed -n '/^Package: libfzssh-dev$/,/^$/ p' $debian/control \
	| grep -q libargon2-dev \
	|| error 'libargon2 edit failed'

	zap_control_package 'libfzssh\S*\d\d.*' $debian/control

	sed -i '/libfzssh\*\.so/ s/\.so$/.a/' $debian/libfzssh-dev.install

	cat >> $debian/rules << END

# XtraDeb: Avoid breakage due to "single-binary" behavior
override_dh_auto_install:
	dh_auto_install --destdir=debian/tmp
END

	if ubuntu_dist noble
	then
		new_patch 0100-XtraDeb-fzssh-deps.patch
	fi

	new_patch 0101-XtraDeb-fzssh-static.patch

	;;
	################################

	libfilezilla)

	zap_control_package 'libfilezilla\d\d' $debian/control
	sed -ri '/^Depends:/ s/\blibfilezilla[0-9]+ \(= [^)]+\), +//' \
		$debian/control

	sed -i '/lib\*\.so$/ s/\.so/.a/' $debian/libfilezilla-dev.install

	cat >> $debian/rules << END

# XtraDeb: Build this library statically
override_dh_auto_configure:
	dh_auto_configure -- --enable-static --disable-shared
END

	new_patch 0100-XtraDeb-libfilezilla-static.patch

	;;
	################################

esac

} # xd_convert()

################################################################

xd_check() {

check_no_shared_libs "$@"

case $source_name in
	fzssh) include_xtradeb_ppa=deps ;;
esac

default_check "$@"

} # xd_check()

################################################################

# end pkg/filezilla/script.sh
