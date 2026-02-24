# pkg/qt6/script.sh
#
# https://packages.debian.org/source/sid/qt6-base#pdownload
# https://packages.ubuntu.com/source/qt6-base
#

################################################################

xd_convert() {

echo 'Note: This build does not include documentation packages.' | add_to_changelog

# Building documentation requires a previous build of qt6-base, so...
zap_control_field	Build-Depends-Indep		$debian/control
zap_control_package	qt6-base-doc			$debian/control
zap_control_package	qt6-base-doc-dev		$debian/control
zap_control_package	qt6-base-doc-html		$debian/control
zap_rules_target	override_dh_auto_build-indep	$debian/rules
zap_rules_target	override_dh_auto_install-indep	$debian/rules

cat >> $debian/rules << END

# XtraDeb: Don't error out due to the numerous not-installed files
override_dh_missing:
	dh_missing --list-missing
END

if ubuntu_dist jammy
then
	# pkg-kde-tools Provides: this in noble and later (and is already
	# a build-dep here)
	sed -ri '/^\s+dh-sequence-pkgkde-symbolshelper,/d' \
		$debian/control

	# Downgrade these build-deps
	sed -ri \
		-e '/^\s+cmake /s/>= .+\)/>= 3.22.1)/' \
		-e '/^\s+dpkg-dev /s/>= .+\)/>= 1.21.1)/' \
		$debian/control

	# Use the better-supported pkg-config instead of pkgconf
	sed -ri 's/^(\s+)pkgconf,/\1pkg-config,/' \
		$debian/control

	# "(subst)" directives in the *.symbols files are not supported
	(cd $debian && grep -l '\bsubst\b' *.symbols | xargs rm -v)
fi

} # xd_convert()

################################################################

# end pkg/qt6/script.sh
