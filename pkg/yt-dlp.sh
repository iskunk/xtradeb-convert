#!/bin/bash
# yt-dlp.sh
#
# This script operates on the debian/ subdirectory of a
# Debian yt-dlp source package, as available from
# https://packages.debian.org/source/sid/yt-dlp#pdownload
#

# yt-dlp/debian/ directory location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize yt-dlp

grep -Fqx 'Source: yt-dlp' $debian/control 2>/dev/null \
|| error "$debian: not a yt-dlp source package debian/ subdirectory"

################################################################
##
## Modifications to allow building on Ubuntu jammy and noble
##
################################################################

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

################################################################

finish

echo "yt-dlp package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end yt-dlp.sh
