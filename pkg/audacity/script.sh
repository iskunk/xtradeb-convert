# pkg/audacity/script.sh
#
# https://packages.debian.org/source/sid/audacity#pdownload
# https://packages.ubuntu.com/source/audacity
#

################################################################

xd_convert() {

ubuntu_dist jammy || not_applicable

################################################################
##
## Modifications to allow building on Ubuntu jammy
##
################################################################

if ubuntu_dist jammy
then
	# Bump down this dependency version slightly
	sed -ri '/^\s+libmp3lame-dev/ s/3.100-5/3.100-3/' \
		$debian/control

	# Not available
	sed -ri \
		-e '/^\s+libsbsms-dev[ ,]/d' \
		-e '/^\s+libvst3sdk-dev,/d' \
		$debian/control

	# Don't go looking for libsbsms
	perl -pi \
		-e '/-Daudacity_use_ffmpeg=/' \
		-e 'and $_ .= "\t  -Daudacity_use_sbsms=off \\\n";' \
		$debian/rules

	# Use the static config of wxWidgets
	sed -ri 's/(gtk3-unicode)-3/\1-static-3/' $debian/rules
fi

##
## Patch series modifications
##

if ubuntu_dist jammy
then
	new_patch XtraDeb-defuse-wxwidgets-lib-check.patch
fi

} # xd_convert()

################################################################

# end pkg/audacity/script.sh
