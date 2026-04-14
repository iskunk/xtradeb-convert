# pkg/yt-dlp/script.sh
#
# https://packages.debian.org/source/sid/yt-dlp#pdownload
# https://packages.ubuntu.com/source/yt-dlp
#

################################################################

xd_convert() {

if ubuntu_dist jammy noble
then
	# Downgrade this dependency
	sed -ri '/^\s+python3-hatchling / s/>= .+\)/>= 0.15.0)/' \
		$debian/control
fi

##
## Patch series modifications
##

if ubuntu_dist jammy noble
then
	new_patch 0101-fix-hatchling-license.patch
fi

if ubuntu_dist jammy
then
	new_patch 0102-fix-urllib3-six.patch
fi

} # xd_convert()

################################################################

# end pkg/yt-dlp/script.sh
