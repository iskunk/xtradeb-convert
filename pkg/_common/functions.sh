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

get_resource_name()
{
	local name="$1"

	# Map the Source: name of a package to the name of its resource
	# directory (which may or may not be present) under pkg/. Note
	# that if there is no match below, then the names are the same.
	case "$name" in
		firefox-esr) name=firefox ;;
		llvm-toolchain-*) name=llvm-toolchain ;;
		qt6-base) name=qt6 ;;
		rustc-[1-9].[0-9]*) name=rustc ;;
		ungoogled-chromium) name=chromium ;;
		wxwidgets[3-9].*) name=wxwidgets ;;

		firefox)
		case "$deb_version" in
			*~mt[1-9]) name=firefox-mt ;;
		esac
		;;

		node-cjs-module-lexer | node-undici | pkg-js-tools)
		name=nodejs
		;;
	esac

	echo "$name"
}

not_applicable()
{
	local message="${1:-}"
	test -n "$message" || message='package can be built without modifications'
	if [ -z "$ubuntu_ver" ]
	then
		echo "$0: not applicable: $message"
	else
		echo "$0: not applicable to Ubuntu $ubuntu_ver/$ubuntu_dist: $message"
	fi
	exit 2
}

not_supported()
{
	local message="${1:-}"
	test -n "$message" || message='package cannot be built for this release'
	if [ -z "$ubuntu_ver" ]
	then
		echo "$0: not supported: $message"
	else
		echo "$0: not supported on Ubuntu $ubuntu_ver/$ubuntu_dist: $message"
	fi
	exit 3
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

add_to_package_description()
{
	local package_name=$1	# can be a Perl regex
	cat > $debian/xtradeb.tmp

	test "_$package_name" != _ALL || package_name='.+'

	perl -pi -0777 -e 's/^(Package: '"$package_name"'\n(?:[\t ]*\S.*\n)*Description:.*\n(?: .+\n)*)/${1} .\n\@XTRADEB_APPEND_DESC\@\n/gm' \
		$debian/control

	(cd $debian && sed -i \
		-e '/^@XTRADEB_APPEND_DESC@$/{r xtradeb.tmp' \
		-e 'd}' \
		control
	)

	rm $debian/xtradeb.tmp
}

get_rust_version()
{
	# Look here to see available versions for each release:
	# https://packages.ubuntu.com/search?suite=default&section=all&arch=any&keywords=rustc-1&searchon=names

	case $ubuntu_dist in
		jammy | noble | plucky)
		rust_version=1.85
		;;

		questing)
		rust_version=1.88
		;;

		*)
		error "$FUNCNAME(): unhandled Ubuntu release \"$ubuntu_dist\""
		;;
	esac

	echo "Available Rust version: $rust_version"
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
			cp -p $resource_dir/$patch_file $debian/patches/$patch_path || exit
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

zap_control_field()
{
	local field_name="$1"	# can be a Perl regex
	local file="$2"

	perl -0777 -pi -e "s/^$field_name:.*(?:\\n[\\t ].+)*\\n//m" $file
}

zap_control_package()
{
	local package_name="$1"	# can be a Perl regex
	local file="$2"

	perl -0777 -pi -e "s/^\\nPackage: $package_name(?:\\n.+)*\\n//m" $file

	# Also remove any Depends: references to this package
	perl -pi -e "/^\\s+$package_name \\(= .+\\),/ and \$_ = \"\"" $file
}

zap_rules_target()
{
	local target_name="$1"
	local file="$2"

	perl -pi -e "s!^($target_name) *:!XTRADEB-DISABLED.\$1:!" $file
}

# Can be overridden in script.sh
xd_convert()
{
	if [ $have_xtradeb_patch = no ]
	then
		control_contact_edits=no
		echo "No-change version tweak for Ubuntu $ubuntu_ver/$ubuntu_dist." > $changelog_add_file
	fi
}

# Can be overridden in script.sh
xd_convert_post()
{
	true
}

# Utility function for xd_check()
check_no_shared_libs()
{
	for deb in "$@"
	do
		! dpkg-deb -c "$deb" | grep -E '\.so(\.[0-9]+)*$' \
		|| error 'package contains shared libraries'
	done
}

default_check()
{
	$base_dir/util/can-install.sh $ubuntu_dist "$@"
}

# Can be overridden in script.sh
xd_check()
{
	default_check "$@"
}

# end functions.sh
