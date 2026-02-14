# pkg/keepassxc/script.sh
#
# https://packages.debian.org/source/sid/keepassxc#pdownload
# https://packages.ubuntu.com/source/keepassxc
#

################################################################

xd_convert() {

if ubuntu_dist jammy noble
then
	# Downgrade this dependency
	sed -ri '/^\s+libbotan-3-dev,/ s/3/2/' $debian/control
fi

} # xd_convert()

################################################################

xd_check() {

# Check the -full and -minimal packages separately as they conflict
# with each other. Don't bother checking the transitional package.
for deb in "$@"
do
	case "./$deb" in
		*/keepassxc-full_* | */keepassxc-minimal_*)
		default_check "$deb"
		;;

		*/keepassxc_*) ;;

		*) error "$deb: unrecognized KeePassXC package" ;;
	esac
done

} # xd_check()

################################################################

# end pkg/keepassxc/script.sh
