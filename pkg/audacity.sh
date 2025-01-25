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
	# Bump down dependency version slightly
	perl -pi -e '/\blibmp3lame-dev \(>= .+\),/ and s/3.100-5/3.100-3/;' \
		$debian/control
fi

##
## Patch series modifications
##

if ubuntu_dist jammy
then
	new_patch xtradeb/libsbsms-static.patch
fi

################################################################

finish

echo "Audacity package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end audacity.sh
