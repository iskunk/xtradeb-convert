#!/bin/sh
#
# Note: This script is not applicable on amd64.
#
# It is a workaround for the issue described here:
# https://unix.stackexchange.com/questions/481824/apt-version-conflicts-across-different-architectures-even-with-multi-arch-same
#
# Pass in a list of package names (without versions nor arch specifiers).
# This script will download the associated amd64 packages, and create
# modified copies thereof with the same version as the native-arch ones.
# (This allows the two different-arch packages to be installed together.)
# The new packages are written to ${pkg}_fixed.deb filenames, in the
# current working directory.
#

set -x

for pkg in "$@"
do
	version=$(apt-cache policy $pkg | sed -n 's/^ *Candidate: *//p')

	test -n "$version" || continue

	apt-get download $pkg:amd64 || exit

	dpkg-deb -R ${pkg}_*.deb tmp-$pkg

	sed -i -r "s/^(Version:).*/\\1 $version/" tmp-$pkg/DEBIAN/control
	rm tmp-$pkg/usr/share/doc/*/changelog.Debian.gz

	dpkg-deb -b tmp-$pkg ${pkg}_fixed.deb

	rm -rf tmp-$pkg
done

# EOF
