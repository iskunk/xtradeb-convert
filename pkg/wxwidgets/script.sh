# pkg/wxwidgets/script.sh
#
# https://packages.debian.org/source/sid/wxwidgets3.2#pdownload
# https://packages.ubuntu.com/source/wxwidgets3.2
#

################################################################

xd_convert() {

ubuntu_dist jammy VENDOR || not_applicable

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

# Add a couple of dependencies to the libwxgtkX.Y-dev package that are
# needed by the static library (and are not auto-detected)
perl -pi \
	-e 'if (/^(\s{,10})libglu1-mesa-dev,/) {' \
	-e '  $_ .= "${1}libgtk-3-dev,\n";' \
	-e '  $_ .= "${1}libnotify-dev,\n";' \
	-e '}' \
	$debian/control

# Add a warning note
add_to_package_description ALL << END
 NOTE: This package comes from a build that was modified by XtraDeb to provide
 static libraries only.  It is intended solely for use as a build dependency,
 and should not be installed on a user system otherwise.
END

# Already in main -dev package
sed -i '/libwx_gtk\*media\*/d; /libwx_gtk\*webview\*/d' $debian/*.install

# Forgotten library? (Audacity build fails without this)
echo 'usr/lib/*/libwxscintilla*.a' >> $debian/libwxgtk3.2-dev.install

# Don't build the doc package, as it depends on a CSS package not
# available in jammy
zap_control_package wx3.2-doc $debian/control
zap_rules_target override_dh_installdocs-indep $debian/rules

##
## Patch series modifications
##

# (none for now)

} # xd_convert()

################################################################

# end pkg/wxwidgets/script.sh
