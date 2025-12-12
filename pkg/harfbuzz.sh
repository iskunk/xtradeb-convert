#!/bin/bash
# harfbuzz.sh
#
# This script operates on the debian/ subdirectory of a
# Debian (or Ubuntu) harfbuzz source package, as available from
# https://packages.debian.org/source/sid/harfbuzz#pdownload
#
# It modifies harfbuzz not only so that it builds on jammy, but
# also to build as static libraries, so that it can fulfill build
# dependencies for Chromium without requiring new shared libraries
# at runtime. Newer Ubuntu releases already have a recent enough
# harfbuzz package to avoid needing this script.
#

debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize harfbuzz

grep -Fqx 'Source: harfbuzz' $debian/control 2>/dev/null \
|| error "$debian: not a harfbuzz source package debian/ subdirectory"

ubuntu_dist jammy || not_applicable 'this script is needed only for jammy'

changelog_text+=" NOTE: This package has been modified to provide static libraries only, and support for GObject introspection and chafa rendering have been disabled. It is intended solely for use as a build dependency."

################################################################

# There are two main changes that need to be made:
#
# 1. Build harfbuzz as static libraries rather than shared, so that
#    Chromium can consume it without gaining new shared-library
#    dependencies (which will cause package installation to break on
#    end-users' systems as the required version isn't available);
#
# 2. Disable GObject introspection, as this is only supported in a
#    shared-library build.
#
# We also disable "chafa" functionality, as newer harfbuzz releases
# require a version that is not available in jammy, and what this
# provides is superfluous for our needs.
#

# Remove build dependencies on introspection stuff and libchafa
sed -ri \
	-e '/^\s+dh-sequence-gir,$/d' \
	-e '/^\s+gir[0-9.]+-\S+-dev,$/d' \
	-e '/^\s+libchafa-dev,$/d' \
	-e '/^\s+libgirepository[0-9.]+-dev,$/d' \
	$debian/control

# Remove all runtime library package definitions, as they are not
# needed when only static libraries are used
zap_control_package 'gir[\d.]+-harfbuzz-[\d.]+'	$debian/control
zap_control_package 'libharfbuzz\d+b'		$debian/control
zap_control_package 'libharfbuzz-cairo\d+'	$debian/control
zap_control_package 'libharfbuzz-gobject\d+'	$debian/control
zap_control_package 'libharfbuzz-icu\d+'	$debian/control
zap_control_package 'libharfbuzz-subset\d+'	$debian/control

# Add build options to prefer static libraries, disable introspection,
# and disable chafa support
perl -pi \
	-e 'if (/^\s+dh_auto_configure\b/) {' \
	-e '  /chafa=disabled/ or s/$/ -Dchafa=disabled/;' \
	-e '  s/$/ -Dintrospection=disabled --default-library static/;' \
	-e '}' \
	$debian/rules

# Replace references to shared libraries with static equivalents, and
# remove references to GObject introspection files
perl -pi \
	-e 's/\.so(\.\*(\[0-9\])?)?/.a/;' \
	-e 'm!^usr/share/gir-! and $_=""' \
	$debian/libharfbuzz-dev.install

################################################################

finish

echo "Harfbuzz package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end harfbuzz.sh
