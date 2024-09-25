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

if ! grep -Fqx 'Source: calibre' $debian/control 2>/dev/null
then
	echo "$0: error: $debian: not a calibre source package debian/ subdirectory"
	exit 1
fi

if ! ubuntu_dist noble
then
	echo "$0: error: this script targets only Ubuntu noble"
	exit 1
fi

################################################################
##
## Modifications to allow building on Ubuntu noble
##
################################################################

perl -pi -e 's/python3-pyzstd,/python3-zstd,/' $debian/control

##
## Patch series modifications
##

# Patch name is awkward but that's what Debian went with
new_patch 0098-Some-color-scheme-functions-are-not-available-in-Qt-.patch

new_patch 0099-rewrite-test_zstd.patch

################################################################

finish

echo "Calibre package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end calibre.sh
