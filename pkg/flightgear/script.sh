# pkg/flightgear/script.sh
#
# https://packages.debian.org/source/sid/flightgear#pdownload
# https://packages.debian.org/source/sid/flightgear-data#pdownload
# https://packages.debian.org/source/sid/simgear#pdownload
# https://packages.ubuntu.com/source/flightgear
# https://packages.ubuntu.com/source/flightgear-data
# https://packages.ubuntu.com/source/simgear
#

################################################################

xd_convert() {

# Too much missing to support jammy
! ubuntu_dist jammy || not_supported

# The current package comes from resolute, so only target prior releases
ubuntu_dist noble questing || not_applicable

case "$source_name" in
	flightgear)
	# Download these packages from the Ubuntu repo, not our PPA,
	# as they are very large.
	sed -i -e '/^Standards-Version:/{' \
		-e 'i XS-XtraDeb-Test-Build-Depends:' \
		-e 'i \ flightgear-data-ai/resolute,' \
		-e 'i \ flightgear-data-base/resolute,' \
		-e '}' \
		$debian/control
	;;
esac

} # xd_convert()

################################################################

xd_check() {

for deb in "$@"
do
	include_xtradeb_ppa=

	case "./$deb" in
		*/flightgear_*) include_xtradeb_ppa=play ;;

		*/flightgear-data_* | */simgear_*) ;;

		*) error "$deb: unrecognized FlightGear package" ;;
	esac

	default_check "$deb"
done

} # xd_check()

################################################################

# end pkg/flightgear/script.sh
