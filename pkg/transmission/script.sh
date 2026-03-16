# pkg/transmission/script.sh
#
# https://packages.debian.org/source/sid/transmission#pdownload
# https://packages.ubuntu.com/source/transmission
#

################################################################

xd_convert() {

# libgtkmm-4.0-dev is not available
! ubuntu_dist jammy || not_supported

if ubuntu_dist noble
then
	# Slight dependency downgrade (also see patch below)
	sed -ri '/^\s+libgtkmm-4.0-dev / s/>= .*\)/>= 4.10)/' $debian/control
fi

##
## Patch series modifications
##

if ubuntu_dist noble
then
	new_patch xtradeb-gtkmm-downgrade.patch
fi

} # xd_convert()

################################################################

# end pkg/transmission/script.sh
