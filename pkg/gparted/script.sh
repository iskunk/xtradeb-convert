# pkg/gparted/script.sh
#
# https://packages.debian.org/source/sid/gparted#pdownload
# https://packages.ubuntu.com/source/gparted
#

################################################################

xd_convert() {

if ubuntu_dist jammy
then
	new_patch XtraDeb-Fix-pkexec-check.patch
fi

} # xd_convert()

################################################################

# end pkg/gparted/script.sh
