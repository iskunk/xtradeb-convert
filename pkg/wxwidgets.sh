#!/bin/bash
# wxwidgets.sh
#
# This script operates on the debian/ subdirectory of a
# Debian wxwidgets source package, as available from
# https://packages.debian.org/source/sid/wxwidgets3.2#pdownload
#

# wxwidgets/debian/ directory location and (optional) Ubuntu release
debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize wxwidgets

grep -Fqx 'Source: wxwidgets3.2' $debian/control 2>/dev/null \
|| error "$debian: not a wxwidgets source package debian/ subdirectory"

ubuntu_dist jammy || not_applicable

################################################################
##
## Modifications to allow building on Ubuntu jammy
##
################################################################

# Bump down dependency version slightly
perl -pi -e '/\bdpkg-dev \(>= .+\),/ and s/1.22.5/1.21.1/' \
	$debian/control

# Build the libraries as static, not shared
perl -pi -e 'm!GREP=/bin/grep! and $_ .= "\t\t--disable-shared \\\n"' \
	$debian/rules
#
sed -i 's/\.so$/.a/; /\.so\.\*$/d' $debian/*.install
#
sed -i -r 's!(config/gtk3-unicode)!\1-static!' $debian/*.alternatives.in

# Add a warning note to the package descriptions
perl -pi -0777 -e 's/^(Description:.*\n(?: .+\n)*)\n/${1} \@XTRADEB-DESC-ADD\@\n\n/gm' \
	$debian/control
cat > $debian/xtradeb.tmp << END
 .
 NOTE: This package comes from a build that was modified by XtraDeb to provide
 static libraries only.  It is intended solely for use as a build dependency,
 and should not be installed on a user system otherwise.
END
(cd $debian && sed -i -e '/^ @XTRADEB-DESC-ADD@/{r xtradeb.tmp' -e 'd}' \
	control)
rm $debian/xtradeb.tmp

# Already in main -dev package
sed -i '/libwx_gtk\*media\*/d; /libwx_gtk\*webview\*/d' $debian/*.install

# Forgotten library? (Audacity build fails without this)
echo 'usr/lib/*/libwxscintilla*.a' >> $debian/libwxgtk3.2-dev.install

# Don't build the doc package, as it depends on a CSS package not
# available in jammy
sed -i '/^Package: wx3.2-doc$/,/^$/d' $debian/control
#
sed -i -r 's/^(override_dh_installdocs-indep:)/XTRADEB-DISABLED.\1/' \
	$debian/rules

##
## Patch series modifications
##

# (none for now)

################################################################

finish

echo "wxWidgets package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end wxwidgets.sh
