#!/bin/bash
# audacity.sh
#
# This script operates on the debian/ subdirectory of a
# Debian audacity source package, as available from
# https://packages.debian.org/source/sid/audacity#pdownload
#

# audacity/debian/ directory location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize audacity

grep -Fqx 'Source: audacity' $debian/control 2>/dev/null \
|| error "$debian: not an audacity source package debian/ subdirectory"

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

################################################################

finish

echo "Audacity package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end audacity.sh
