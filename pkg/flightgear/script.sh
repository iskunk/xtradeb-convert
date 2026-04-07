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

case "$source_name" in
	flightgear)
	# Download these packages from the Ubuntu repo, not our PPA,
	# as they are very large.
	test_build_depends='flightgear-data-ai/resolute flightgear-data-base/resolute'
	;;

	flightgear-data)
	error 'flightgear-data package should be copied, not converted'
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
