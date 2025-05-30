#!/bin/bash
# generic.sh
#
# Use this on packages that we are importing from Debian/Ubuntu into a
# PPA without conversion to avoid a "same version already has published
# binaries in the destination archive" error from Launchpad.
#

debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize generic

control_contact_edits=no

changelog_text="No-change version tweak for Ubuntu $ubuntu_ver/$ubuntu_dist."

finish

echo "Package version tweaked for Ubuntu $ubuntu_ver/$ubuntu_dist:"
head -n1 $debian/changelog

# end generic.sh
