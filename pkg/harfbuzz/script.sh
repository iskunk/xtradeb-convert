# pkg/harfbuzz/script.sh
#
# https://packages.debian.org/source/sid/harfbuzz#pdownload
# https://packages.ubuntu.com/source/harfbuzz
#

################################################################

xd_convert() {

# This script modifies harfbuzz not only so that it builds on jammy,
# but also to build as static libraries, so that it can fulfill build
# dependencies for Chromium without requiring new shared libraries at
# runtime. Newer Ubuntu releases already have a recent enough harfbuzz
# package to avoid needing this script.

ubuntu_dist jammy VENDOR \
|| not_applicable 'this conversion is needed only for jammy'

add_to_changelog << END
NOTE: This package has been modified to provide static libraries only,
and support for GObject introspection and chafa rendering has been
disabled.  It is intended solely for use as a build dependency.
END

# There are three main changes that need to be made:
#
# 1. Build harfbuzz as static libraries rather than shared, so that
#    Chromium can consume it without gaining new shared-library
#    dependencies (which will cause package installation to break on
#    end-users' systems as the required version isn't available);
#
# 2. Disable GObject introspection, as this is only supported in a
#    shared-library build.
#
# 3. Disable "chafa" functionality, as newer harfbuzz releases require
#    a version that is not available in jammy, and what this provides
#    is superfluous for our needs.
#

# Remove build dependencies on introspection stuff and libchafa
sed -ri \
	-e '/^\s+dh-sequence-gir,$/ d' \
	-e '/^\s+gir[0-9.]+-\S+-dev,$/ d' \
	-e '/^\s+gobject-introspection .+,$/ d' \
	-e '/^\s+libchafa-dev,$/ d' \
	-e '/^\s+libgirepository[0-9.]+-dev,$/ d' \
	$debian/control

# Remove all runtime library package definitions, as they are not
# needed when only static libraries are used
zap_control_package 'gir[\d.]+-harfbuzz-[\d.]+'	$debian/control
zap_control_package 'libharfbuzz\d+b'		$debian/control
zap_control_package 'libharfbuzz\d+-udeb'	$debian/control
zap_control_package 'libharfbuzz-cairo\d+'	$debian/control
zap_control_package 'libharfbuzz-gobject\d+'	$debian/control
zap_control_package 'libharfbuzz-icu\d+'	$debian/control
zap_control_package 'libharfbuzz-subset\d+'	$debian/control

# Add build options to prefer static libraries, disable GObject
# introspection, and disable chafa support
perl -pi \
	-e 'if (/^\s+dh_auto_configure\b/) {' \
	-e '  /chafa=disabled/ or s/$/ -Dchafa=disabled/;' \
	-e '  s/$/ -Dintrospection=disabled --default-library static/;' \
	-e '}' \
	$debian/rules

# Drop GObject introspection dpkg variable references
sed -ri '/\$\{gir:(Depends|Provides)\}/ d' $debian/control

# Some package builds link to HarfBuzz using a solitary "-lharfbuzz"
# instead of querying pkg-config for the full set of flags. This is OK
# for a shared library, but a static one will lack a reference to its
# libgraphite2 transitive dependency, and thus the link fails with
# missing graphite2 symbols. Rather than hack in a -lgraphite2 flag into
# every offending build, we replace libharfbuzz.a with a linker script
# that effectively adds that dependency under the covers.
#
# Reference for linker scripts:
# https://sourceware.org/binutils/docs/ld/File-Commands.html
cat > $debian/xtradeb.tmp << 'END'

# XtraDeb: Use linker script to include libgraphite2 dependency
# when linking the static -lharfbuzz in isolation
	cd debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH) \
	&& mv libharfbuzz.a libharfbuzz.real.a \
	&& (echo '/* GNU ld script'; \
	    echo ' */'; \
	    echo 'INPUT ( -lharfbuzz.real -lgraphite2 )' \
	   ) > libharfbuzz.a \
	&& perl -pi -e 's/( -lharfbuzz)(?!\S)/$$1.real/g' pkgconfig/*.pc
END
(cd $debian && sed -i '/dh_auto_install .* build-main/ r xtradeb.tmp' rules)
rm $debian/xtradeb.tmp

# Replace references to shared libraries with static equivalents, and
# remove references to GObject introspection files
perl -pi \
	-e 's/\.so(\.\*(\[0-9\])?)?/.a/;' \
	-e 'm!^usr/share/gir-! and s/^/#xtradeb#/' \
	$debian/libharfbuzz-dev.install

# When building against a newer ICU, a newer C++ standard is needed to
# avoid compile errors like
#
#   /usr/include/unicode/char16ptr.h:271:38: error: ‘enable_if_t’ in namespace ‘std’ does not name a template type
#     271 | template<typename T, typename = std::enable_if_t<std::is_same_v<T, UChar>>>
#         |                                      ^~~~~~~~~~~
#
sed -i '/^export DEB_LDFLAGS_MAINT_APPEND =/ i export DEB_CXXFLAGS_MAINT_APPEND = -std=c++17' \
	$debian/rules

} # xd_convert()

################################################################

xd_check() {

for deb in "$@"
do
	case "./$deb" in
		*/libharfbuzz-bin_*) ;;
		*/libharfbuzz-doc_*) ;;

		*/libharfbuzz-dev_*)
		contents=$(dpkg-deb -c "$deb")
		grep -q '/libharfbuzz\.real\.a$' <<< $contents \
		|| error 'libharfbuzz-dev package is missing libharfbuzz.real.a'
		;;

		*) error "extraneous binary package: $deb" ;;
	esac
done

check_no_shared_libs "$@"

default_check "$@"

} # xd_check()

################################################################

# end pkg/harfbuzz/script.sh
