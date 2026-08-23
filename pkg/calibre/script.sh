# pkg/calibre/script.sh
#
# https://packages.debian.org/source/sid/calibre#pdownload
# https://packages.ubuntu.com/source/calibre
#

################################################################

xd_convert() {

# Too much missing to make this work, even for version 7.x.x
! ubuntu_dist jammy || not_supported

if dpkg --compare-versions $deb_version ge 9.0.0
then
	# Can't build 9.x.x on noble; it really needs Python 3.14
	! ubuntu_dist noble || not_supported
#
elif dpkg --compare-versions $deb_version ge 8.0.0
then
	ubuntu_dist noble VENDOR \
	|| not_applicable 'please build version >= 9.x.x'
else
	error 'package version is too old for conversion'
fi

major_version=${deb_version%%.*}

if ubuntu_dist noble
then
	# Downgrade some dependencies to what's available
	sed -ri \
		-e '/^\s+dh-python / s/>= \S+\)/>= 6.2024)/' \
		-e '/^\s+python3-py7zr / s/>= \S+\)/>= 0.11.3)/' \
		$debian/control

	# Drop some others that aren't available
	sed -ri \
		-e '/^\s+libonnxruntime-dev,/ d' \
		-e '/^\s+qt6-svg-plugins,/ d' \
		$debian/control
fi

drop_pykakasi=false

if ubuntu_dist noble resolute && \
   grep -q '^\s*python3-pykakasi,' $debian/control
then
	# Not available before stonking
	drop_pykakasi=true
	sed -ri -e '/^\s+python3-pykakasi,/ d' $debian/control
fi

cat > $debian/xtradeb.tmp << 'END'

# enable parallelization if requested
ifneq (,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
export CMAKE_BUILD_PARALLEL_LEVEL=$(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
endif
END
(cd $debian && sed -i '/^export VERBOSE=1/ r xtradeb.tmp' rules)
rm $debian/xtradeb.tmp

# 900+ lintian warnings from these
cat >> $debian/calibre.lintian-overrides << END

# XtraDeb
calibre: unusual-interpreter python [usr/lib/calibre/**/*.py]
calibre: unusual-interpreter python [usr/share/calibre/default_tweaks.py]
END

##
## Patch series modifications
##

if ubuntu_dist noble
then
	# Patch name is awkward but that's what Debian went with
	new_patch 0098-Some-color-scheme-functions-are-not-available-in-Qt-.patch

	# python3-pyzstd is not available before oracular
	sed -i 's/python3-pyzstd,/python3-zstd,/' $debian/control
	new_patch 0100-XtraDeb-rewrite-test_zstd.patch

	new_patch 0101-XtraDeb-drop-piper.patch
	new_patch 0102-XtraDeb-py7zr-compat.patch
fi

if $drop_pykakasi
then
	new_patch 0103-XtraDeb-drop-pykakasi.patch
fi

new_patch 0104-XtraDeb-no-network-v$major_version.patch

} # xd_convert()

################################################################

# end pkg/calibre/script.sh
