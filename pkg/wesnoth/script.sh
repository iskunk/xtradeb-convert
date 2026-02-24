# pkg/wesnoth/script.sh
#
# https://packages.debian.org/source/sid/wesnoth-1.18#pdownload
# https://packages.ubuntu.com/source/wesnoth
#

################################################################

xd_convert() {

if ubuntu_dist jammy
then
	# Downgrade these build-deps
	sed -ri \
		-e '/^\s+debhelper / s/>= .+\)/>= 13.6)/' \
		-e '/^\s+liblua5.4-dev / s/>= .+\)/>= 5.4.4)/' \
		$debian/control.in

	# Use the better-supported pkg-config instead of pkgconf
	sed -ri 's/^(\s+)pkgconf,/\1pkg-config,/' \
		$debian/control.in

	# dh_installchangelogs --no-trim changelog.md
	# Unknown option: no-trim
	# dh_installchangelogs: error: unknown option or error during option parsing; aborting
	sed -i '/dh_installchangelogs/ s/--no-trim //' $debian/rules
fi

if [ $debian/control.in -nt $debian/control ]
then
	branch=${source_name##*-}
	sed "s/BRANCH/$branch/g" $debian/control.in > $debian/control
fi

} # xd_convert()

################################################################

# end pkg/wesnoth/script.sh
