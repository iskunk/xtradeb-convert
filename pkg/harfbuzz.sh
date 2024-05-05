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

if ! ubuntu_dist jammy
then
	echo "$0: error: this script is needed only for jammy"
	exit 1
fi

pkg=$(dpkg-parsechangelog -l $debian/changelog -S Source)

if [ "_$pkg" != _harfbuzz ]
then
	echo "$0: error: $debian: not a harfbuzz source package debian/ subdirectory"
	exit 1
fi

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
sed -ri \
	-e '/^Package: gir[0-9.]+-harfbuzz-[0-9.]+$/,/^$/d' \
	-e '/^Package: libharfbuzz[0-9]b$/,/^$/d' \
	-e '/^Package: libharfbuzz-cairo[0-9]$/,/^$/d' \
	-e '/^Package: libharfbuzz-gobject[0-9]$/,/^$/d' \
	-e '/^Package: libharfbuzz-icu[0-9]$/,/^$/d' \
	-e '/^Package: libharfbuzz-subset[0-9]$/,/^$/d' \
	$debian/control

# Remove dependencies on the above runtime library packages
sed -ri \
	-e '/^\s+gir[0-9.]+-harfbuzz-[0-9.]+ \(= \$\{binary:Version\}\),$/d' \
	-e '/^\s+libharfbuzz\S+ \(= \$\{binary:Version\}\),$/d' \
	$debian/control

# Add build options to prefer static libraries, disable introspection,
# and disable chafa support
perl -pi \
	-e 'if (/^\s+dh_auto_configure\b/) {' \
	-e '  /chafa=disabled/ or s/$/ -Dchafa=disabled/;' \
	-e '  s/$/ --default-library static -Dintrospection=disabled/;' \
	-e '}' \
	$debian/rules

# Replace references to shared libraries with static equivalents, and
# remove references to GObject introspection files
perl -pi \
	-e 's/\.so(\.\*(\[0-9\])?)?/.a/;' \
	-e 'm!^usr/share/gir-! and $_=""' \
	$debian/libharfbuzz-dev.install

# Remove *.symbols files, as they are not needed for static libs
rm -f $debian/*.symbols

################################################################

finish

echo "Harfbuzz package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end harfbuzz.sh
