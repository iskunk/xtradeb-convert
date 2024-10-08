# functions.sh

warning()
{
	local message="$1"
	echo "warning: $message"
}

error()
{
	local message="$1"
	echo "$0: error: $message"
	exit 1
}

not_applicable()
{
	local message="$1"
	test -n "$message" || message='package can be built without modifications'
	if [ -z "$ubuntu_ver" ]
	then
		echo "$0: not applicable: $message"
	else
		echo "$0: not applicable to Ubuntu $ubuntu_ver/$ubuntu_dist: $message"
	fi
	exit 2
}

initialize()
{
	package_name="$1"
	shift

	multi_dist=no

	while [ -n "$1" ]
	do
		case "$1" in
			--multi-dist) multi_dist=yes ;;
			*) error "initialize(): unrecognized option \"$1\"" ;;
		esac
		shift
	done

	test -n "$BASH_VERSION" \
	|| error 'initialize(): script must run under bash(1)'

	set -eu

	# In case the user is confused
	case "$debian" in
		'' | -h | --help)
		echo "usage: $0 DEBIAN-DIR [UBUNTU-RELEASE]"
		exit 0
		;;
	esac

	if [ -z "${DEBFULLNAME:-}" ]
	then
		export DEBFULLNAME='XtraDeb User'
		export DEBEMAIL='xtradeb.user@example.com'
	fi

	# Sanity checks

	if [ ! -f $debian/changelog -o \
	     ! -f $debian/control -o \
	     ! -f $debian/rules ]
	then
		error "$debian: not a source package debian/ subdirectory"
	fi

	if [ -z "$ubuntu_dist" -a $(lsb_release -is) = Ubuntu ]
	then
		ubuntu_dist=$(lsb_release -cs)
	fi
	test -n "$ubuntu_dist" || ubuntu_dist=jammy

	case "$ubuntu_dist" in
		jammy)    ubuntu_ver=22.04 ;;
		noble)    ubuntu_ver=24.04 ;;
		oracular) ubuntu_ver=24.10 ;;
		*) error "invalid Ubuntu distribution \"$ubuntu_dist\"" ;;
	esac

	version_suffix="xtradeb1.${ubuntu_ver/./}."

	# Verify that these packages are installed
	dpkg --status dpkg-dev devscripts quilt >/dev/null || exit

	deb_version=$(dpkg-parsechangelog --file $debian/changelog --show-field Version)

	if [ $multi_dist = yes ]
	then
		changelog_text="XtraDeb conversion for Ubuntu $ubuntu_ver/$ubuntu_dist and later releases."
	else
		changelog_text="XtraDeb conversion for Ubuntu $ubuntu_ver/$ubuntu_dist."
	fi

	cur_dist=$(dpkg-parsechangelog \
		--file $debian/changelog \
		--show-field Distribution)

	if grep -Fq "<$DEBEMAIL>" $debian/control && [ "_$cur_dist" != _UNRELEASED ]
	then
		# Package is already converted; prepare a new XtraDeb release
		debchange \
			--no-conf \
			--no-auto-nmu \
			--distribution $ubuntu_dist \
			--local $version_suffix \
			--changelog $debian/changelog
		exit
	fi

	patch_series_changed=no
	patch_series_tmp=$debian/patches/xtradeb-series.tmp
	rm -f $patch_series_tmp
}

ubuntu_dist()
{
	local d=
	for d in "$@"
	do
		if [ "_$d" = "_$ubuntu_dist" ]
		then
			return 0
		fi
	done

	return 1
}

new_patch()
{
	local inline=no
	if [ "_$1" = _--inline ]
	then
		inline=yes
		shift
	fi

	local patch_path=$1
	local patch_file=$(echo $patch_path | tr / _)

	if [ ! -d $debian/patches ]
	then
		echo 'note: creating new patch series'
		mkdir $debian/patches
		: > $debian/patches/series
	##
	elif [ ! -f $debian/patches/series ]
	then
		error 'new_patch(): package lacks a patch series to amend'
	fi

	if [ -f $patch_series_tmp ] && \
	   grep -Fqx $patch_path $patch_series_tmp
	then
		error "new_patch(): patch \"$patch_path\" already added"
	##
	elif grep -Fqx $patch_path $debian/patches/series
	then
		echo " * $patch_path  (already in series)"
		return
	##
	elif [ -f $debian/patches/$patch_path ]
	then
		echo " * $patch_path  (existing)"
	else
		echo " * $patch_path  (new)"
		mkdir -p $(dirname $debian/patches/$patch_path)
		if [ $inline = yes ]
		then
			sed 's/^=$/ /' > $debian/patches/$patch_path || exit
		else
			cp -p $base_dir/_$package_name/$patch_file $debian/patches/$patch_path || exit
		fi
	fi

	echo $patch_path >> $patch_series_tmp

	patch_series_changed=yes
}

disable_patch()
{
	local patch_path=$1

	if [ ! -f $debian/patches/series ]
	then
		error 'disable_patch(): package lacks a patch series to amend'
	fi

	if grep -Fqx $patch_path $debian/patches/series
	then
		echo " * $patch_path  (disabled)"

		perl -pi \
			-e '$a = $_; chomp($a);' \
			-e '$a eq "'"$patch_path"'" and s/^/#xtradeb#/' \
			$debian/patches/series

		patch_series_changed=yes
	##
	elif grep -Fqx "#xtradeb#$patch_path" $debian/patches/series
	then
		error "disable_patch(): patch \"$patch_path\" already disabled"
	else
		echo " * $patch_path  (not present)"
	fi
}

finish()
{
	# Firefox packages use a generated control file
	control=control
	test ! -f $debian/control.in || control=control.in

	# We are now the maintainer
	perl -pi \
		-e '/^XSBC-Original-Maintainer:/i and $_="";' \
		-e 's/^(Maintainer): (.+)$/$1: $ENV{DEBFULLNAME} <$ENV{DEBEMAIL}>\nXSBC-Original-Maintainer: $2/;' \
		$debian/$control

	# Remove Uploaders: field (mind the multiple lines)
	perl -0777 -pi -e 's/^Uploaders:.*(\n .+)*\n//m' $debian/$control

	if [ -f $patch_series_tmp ]
	then
		(echo; echo '# XtraDeb'; cat $patch_series_tmp) >>$debian/patches/series
		rm -f $patch_series_tmp
		patch_series_changed=yes
	fi

	if [ -f $debian/patches/series ]
	then
		# Check that all referenced patches are present
		for patch in $(grep -v '^#' $debian/patches/series | grep .)
		do
			test -f $debian/patches/$patch \
			|| error "finish(): $patch: missing patch file"
		done
	fi

	# Use the same urgency as the upstream release
	urgency=$(dpkg-parsechangelog \
		--file $debian/changelog \
		--show-field Urgency)

	# Add new changelog entry
	debchange \
		--no-conf \
		--no-auto-nmu \
		--distribution $ubuntu_dist \
		--local $version_suffix \
		--urgency $urgency \
		--changelog $debian/changelog \
		"$changelog_text"

	# Drop Debian stable release from the version string, if present
	sed -i '1s/~deb[0-9][0-9]u/u/' $debian/changelog

	if [ $patch_series_changed = yes -a -f $debian/../.pc/applied-patches ]
	then
		cat <<END

Warning: Patch series has changed, please run

  \$ cd $(cd $debian/.. && pwd)
  \$ quilt pop -afq && quilt push -afq

in the top-level source directory of the package.

END
	fi
}

# end functions.sh
