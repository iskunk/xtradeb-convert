# pkg/0ad/script.sh
#
# https://packages.debian.org/source/sid/0ad#pdownload
# https://packages.debian.org/source/sid/0ad-data#pdownload
# https://packages.ubuntu.com/source/0ad
# https://packages.ubuntu.com/source/0ad-data
#

################################################################

xd_convert() {

test "_$source_name" = "_0ad" \
|| error '0ad-data package should be copied, not converted'

if ubuntu_dist jammy
then
	# Need a newer C++ compiler to avoid
	# "error: 'std::pair<_T1, _T2>::second' has incomplete type"
	sed -ri '/^\s+dpkg-dev / a \ g++-12,' $debian/control
fi

# Ubuntu provides "rustc-N.NN" packages
sed -ri \
	-e 's/^(\s+(cargo|rustc))(:any)? \(.+\),$/\1-'"$rust_version"'\3,/' \
	-e 's/^(\s+libstd-rust)(-dev) \(.+\)/\1-'"$rust_version"'\2/' \
	$debian/control

: > $debian/xtradeb.tmp
if ubuntu_dist jammy
then
	cat >> $debian/xtradeb.tmp << END

export CC  = gcc-12
export CXX = g++-12
END
fi
cat >> $debian/xtradeb.tmp << END

export CARGO = cargo-$rust_version
export RUSTC = rustc-$rust_version
END
(cd $debian && sed -i '/^export SHELL =/ r xtradeb.tmp' rules)
rm $debian/xtradeb.tmp

# Enable building for any architecture
sed -ri 's/^(Architecture): amd64 .*/\1: any/' $debian/control

##
## Patch series modifications
##

new_patch xtradeb-arch-support.patch

new_patch xtradeb-fmt-syntax.patch

} # xd_convert()

################################################################

xd_check() {

for deb in "$@"
do
	include_xtradeb_ppa=

	case "./$deb" in
		*/0ad_*) include_xtradeb_ppa=play ;;

		*/0ad-data_*) ;;

		*) error "$deb: unrecognized 0ad package" ;;
	esac

	default_check "$deb"
done

} # xd_check()

################################################################

# end pkg/0ad/script.sh
