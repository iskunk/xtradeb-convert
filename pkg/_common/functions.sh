# functions.sh

initialize()
{
	package_name="$1"
	shift

	multi_dist=no

	while [ -n "$1" ]
	do
		case "$1" in
			--multi-dist) multi_dist=yes ;;
			*) echo "$0: error: initialize(): unrecognized option \"$1\""; exit 1 ;;
		esac
		shift
	done

	if [ -z "$BASH_VERSION" ]
	then
		echo "$0: error: script must run under bash(1)"
		exit 1
	fi

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
		echo "$0: error: $debian: not a source package debian/ subdirectory"
		exit 1
	fi

	if [ -z "$ubuntu_dist" -a $(lsb_release -is) = Ubuntu ]
	then
		ubuntu_dist=$(lsb_release -cs)
	fi
	test -n "$ubuntu_dist" || ubuntu_dist=jammy

	case "$ubuntu_dist" in
		jammy)  ubuntu_ver=22.04 ;;
		mantic) ubuntu_ver=23.10 ;;
		noble)  ubuntu_ver=24.04 ;;
		*) echo "$0: error: invalid Ubuntu distribution \"$ubuntu_dist\""; exit 1 ;;
	esac

	version_suffix="xtradeb1.${ubuntu_ver/./}."

	# Verify that these packages are installed
	dpkg --status dpkg-dev devscripts quilt >/dev/null || exit

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

	# Firefox packages use a generated control file
	control=control
	test ! -f $debian/control.in || control=control.in

	perl -pi \
		-e 's/^(Maintainer): (.+)$/$1: $ENV{DEBFULLNAME} <$ENV{DEBEMAIL}>\nXSBC-Original-Maintainer: $2/;' \
		$debian/$control

	# In case there are now multiple XSBC-Original-Maintainer: fields
	perl -pi -e '/^XSBC-Original-Maintainer:/ && !/\b(debian\.(net|org))\b/ and $_=""' \
		$debian/$control

	# Remove Uploaders: field (mind the multiple lines)
	perl -0777 -pi -e 's/^Uploaders:.*(\n .+)*\n//m' $debian/$control

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
	local patch_path=$1
	local patch_file=$(echo $patch_path | tr / _)

	if [ ! -f $debian/patches/series ]
	then
		echo "$0: error: package lacks a patch series to amend"
		exit 1
	fi

	if [ -f $patch_series_tmp ] && \
	   grep -Fqx $patch_path $patch_series_tmp
	then
		echo "$0: error: patch \"$patch_path\" already added"
		exit 1
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
		cp -p $base_dir/_$package_name/$patch_file $debian/patches/$patch_path || exit
	fi

	echo $patch_path >> $patch_series_tmp

	patch_series_changed=yes
}

disable_patch()
{
	local patch_path=$1

	if [ ! -f $debian/patches/series ]
	then
		echo "$0: error: package lacks a patch series to amend"
		exit 1
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
		echo "$0: error: patch \"$patch_path\" already disabled"
	else
		echo " * $patch_path  (not present)"
	fi
}

finish()
{
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
			if [ ! -f $debian/patches/$patch ]
			then
				echo "error: $patch: missing patch file"
				exit 1
			fi
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
