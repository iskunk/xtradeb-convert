# pkg/calibre/script.sh
#
# https://packages.debian.org/source/sid/calibre#pdownload
# https://packages.ubuntu.com/source/calibre
#

################################################################

xd_convert() {

! ubuntu_dist jammy || not_supported

ubuntu_dist noble || not_applicable

################################################################
##
## Modifications to allow building on Ubuntu noble
##
################################################################

# Downgrade some dependencies to what's available
sed -i -r \
	-e '/^\s+dh-python /s/>= \S+\)/>= 6.2024)/' \
	-e '/^\s+python3-py7zr /s/>= \S+\)/>= 0.11.3)/' \
	$debian/control

# Drop some others that aren't available
sed -i -r \
	-e '/^\s+libonnxruntime-dev,/d' \
	-e '/^\s+qt6-svg-plugins,/d' \
	$debian/control

##
## Patch series modifications
##

if ubuntu_dist noble
then
	# Patch name is awkward but that's what Debian went with
	new_patch 0098-Some-color-scheme-functions-are-not-available-in-Qt-.patch

	# python3-pyzstd is not available before oracular
	sed -i 's/python3-pyzstd,/python3-zstd,/' $debian/control
	new_patch 0099-rewrite-test_zstd.patch

	new_patch 0100-drop-piper.patch
	new_patch 0101-py7zr-compat.patch
fi

} # xd_convert()

################################################################

# end pkg/calibre/script.sh
