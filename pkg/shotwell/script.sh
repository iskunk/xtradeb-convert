# pkg/shotwell/script.sh
#
# https://packages.debian.org/source/sid/shotwell#pdownload
# https://packages.ubuntu.com/source/shotwell
#

################################################################

xd_convert() {

# On jammy, Xdp.Portal.initable_new() is not available
# (seems to require libportal-dev >= 0.7)
! ubuntu_dist jammy || not_supported

if ubuntu_dist noble
then
	# This package only became available as of plucky
	sed -ri '/^\s+libjxl-gdk-pixbuf,$/ d' $debian/control
fi

##
## Patch series modifications
##

if ubuntu_dist noble
then
	new_patch xtradeb-no-regex-flags-default.patch
fi

} # xd_convert()

################################################################

# end pkg/shotwell/script.sh
