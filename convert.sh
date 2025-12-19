#!/bin/bash
# convert.sh
#
# Main script to convert a Debian or (recent) Ubuntu source package into a
# form targeted to a specific Ubuntu release.
#

debian="$1"
ubuntu_dist_raw="$2"

set -eu

# In case the user is confused
case "$debian" in
	'' | -h | --help)
	echo "usage: $0 DEBIAN-DIR [UBUNTU-RELEASE]"
	exit 0
	;;
esac

base_dir=$(cd $(dirname $0) && pwd)
. $base_dir/pkg/_common/functions.sh

if [ -z "${DEBFULLNAME:-}" ]
then
	export DEBFULLNAME='XtraDeb User'
	export DEBEMAIL='xtradeb.user@example.com'
fi

# If the Ubuntu release was not specified, then use a reasonable default
if [ -z "$ubuntu_dist_raw" -a "_$(lsb_release -is)" = _Ubuntu ]
then
	ubuntu_dist_raw=$(lsb_release -cs)
fi
test -n "$ubuntu_dist_raw" || ubuntu_dist_raw=jammy

set_ubuntu_dist "$ubuntu_dist_raw"

# Verify that these packages are installed
dpkg --status dpkg-dev devscripts >/dev/null || exit

# Verify that required files are present in the debian/ dir
for x in \
	$debian/changelog \
	$debian/control \
	$debian/rules
do
	test -f $x || error "$debian: not a source package debian/ subdirectory"
done

source_name=$(sed -n 's/^Source: *// p' $debian/control)

deb_version=$(dpkg-parsechangelog \
	--file $debian/changelog \
	--show-field Version)

cur_dist=$(dpkg-parsechangelog \
	--file $debian/changelog \
	--show-field Distribution)

if grep -q xtradeb <<< $deb_version && \
   [ "_$cur_dist" != _UNRELEASED ]
then
	error 'package is already converted'
fi

resource_name=$(get_resource_name $source_name)

changelog_add_file=$debian/xtradeb-changelog.tmp
control_contact_edits=yes
multi_dist=no
need_version_epoch_bump=no
patch_series_changed=no
patch_series_tmp=$debian/xtradeb-series.tmp
rm -f $patch_series_tmp
resource_dir=$base_dir/pkg/$resource_name
version_suffix="xtradeb1.${ubuntu_ver/./}."
zapped_package_list=

# Apply debianization patch(es), if present
have_xtradeb_patch=no
for patch in \
	$resource_dir/$source_name.patch \
	$resource_dir/$source_name.$ubuntu_dist.patch
do
	if [ -f $patch ]
	then
		# Can't touch anything outside of debian/
		! grep -E '^(---|\+\+\+) ' $patch \
		  | grep -v -e '^--- a/debian/' -e '^+++ b/debian/' \
		  | grep -q . \
		|| error "$patch: targets file outside of debian/"

		echo "Applying $(basename $patch)"
		(cd $debian && patch -p2 -F0) < $patch
		have_xtradeb_patch=yes
	fi
done

script=$base_dir/pkg/$resource_name/script.sh
test ! -f $script || . $script

if [ "_$multi_dist" = _yes ]
then
	echo "XtraDeb conversion for Ubuntu $ubuntu_ver/$ubuntu_dist and later releases."
else
	echo "XtraDeb conversion for Ubuntu $ubuntu_ver/$ubuntu_dist."
fi > $changelog_add_file

################
##
xd_convert
##
################

# Some packages (e.g. Firefox) use a generated control file
control=control
test ! -f $debian/control.in || control=control.in

if [ $control_contact_edits = yes ]
then
	# We are now the maintainer
	perl -pi \
		-e '/^XSBC-Original-Maintainer:/i and $_="";' \
		-e 's/^(Maintainer): (.+)$/$1: $ENV{DEBFULLNAME} <$ENV{DEBEMAIL}>\nXSBC-Original-Maintainer: $2/;' \
		$debian/$control

	zap_control_field Uploaders $debian/$control
fi

if [ -f $patch_series_tmp ]
then
	(echo; echo '# XtraDeb'; cat $patch_series_tmp) >>$debian/patches/series
	rm $patch_series_tmp
	patch_series_changed=yes
fi

if [ -f $debian/patches/series ]
then
	# Check that all referenced patches are present
	for patch in $(grep -v '^#' $debian/patches/series | grep .)
	do
		test -f $debian/patches/$patch \
		|| error "$patch: missing patch file"
	done
fi

# Use the same urgency as the upstream release
urgency=$(dpkg-parsechangelog \
	--file $debian/changelog \
	--show-field Urgency)

debchange \
	--no-conf \
	--no-auto-nmu \
	--local $version_suffix \
	--urgency $urgency \
	--changelog $debian/changelog \
	'<dummy_line>'

while read cl_line
do
	debchange \
		--no-conf \
		--no-auto-nmu \
		--changelog $debian/changelog \
		"$cl_line"
done < $changelog_add_file

sed -i '3{/^  \* <dummy_line>$/d}' $debian/changelog

debchange \
	--no-conf \
	--no-auto-nmu \
	--distribution $ubuntu_dist \
	--changelog $debian/changelog \
	''

rm $changelog_add_file

if [ "_$need_version_epoch_bump" = _yes ]
then
	ver=$(dpkg-parsechangelog \
		--file $debian/changelog \
		--show-field Version)

	grep -Eq '^[0-9]+:' <<< $ver || ver="0:$ver"

	ver2=$(perl -pe 's/^(\d+):/($1+1).":"/e' <<< $ver)

	sed -ri "1s/\\(\\S+\\)/($ver2)/" $debian/changelog
fi

# Drop Debian stable release from the version string, if present
sed -i '1s/~deb[0-9][0-9]u/u/' $debian/changelog

if [ -n "${XTRADEB_VERSION_MAJOR:-}" ]
then
	echo "Overriding XtraDeb version major to $XTRADEB_VERSION_MAJOR"
	sed -i -r "1s/(xtradeb)[0-9]+\\./\\1$XTRADEB_VERSION_MAJOR./" \
		$debian/changelog
fi
if [ -n "${XTRADEB_VERSION_MINOR:-}" ]
then
	echo "Overriding XtraDeb version minor to $XTRADEB_VERSION_MINOR"
	sed -i -r "1s/\\.[0-9]+\\) /.$XTRADEB_VERSION_MINOR) /" \
		$debian/changelog
fi

################
##
xd_convert_post
##
################

if [ $patch_series_changed = yes -a -f $debian/../.pc/applied-patches ]
then
	cat <<END

Warning: Patch series has changed, please run

  \$ cd $(cd $debian/.. && pwd)
  \$ quilt pop -afq && quilt push -afq

in the top-level source directory of the package.

END
fi

# Check if we are nearing end of support for the targeted Ubuntu release
t_now=$(date -u '+%s')
t_end=$(date -u -d $ubuntu_support_end '+%s')
days=$(( (t_end - t_now) / 86400 ))
if [ 0 -ge $days ]
then
	warning "Ubuntu $ubuntu_ver/$ubuntu_dist is no longer receiving standard support."
elif [ $days -le 30 ]
then
	warning "Ubuntu $ubuntu_ver/$ubuntu_dist has $days day(s) of standard support remaining."
fi

# All done!
echo "Package converted for Ubuntu $ubuntu_ver/$ubuntu_dist:"
head -n1 $debian/changelog

# end convert.sh
