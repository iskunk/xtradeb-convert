#!/bin/bash
# calibre.sh
#
# This script operates on the debian/ subdirectory of a
# Debian calibre source package, as available from
# https://packages.debian.org/source/sid/calibre#pdownload
#

# calibre/debian/ directory location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize calibre

grep -Fqx 'Source: calibre' $debian/control 2>/dev/null \
|| error "$debian: not a calibre source package debian/ subdirectory"

! ubuntu_dist jammy || not_supported

ubuntu_dist noble || not_applicable

################################################################
##
## Modifications to allow building on Ubuntu noble
##
################################################################

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
fi

################################################################

finish

echo "Calibre package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end calibre.sh
