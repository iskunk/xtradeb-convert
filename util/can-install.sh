#!/bin/bash
#
# Script to check that XtraDeb packages can be installed on a given Ubuntu
# release, verifying that all the required dependencies are available.
#

release="$1"
shift

chdist_data=${XDG_CACHE_HOME:-$HOME/.cache}/xtradeb/caninst

test -n "$UBUNTU_APT_URL"  || UBUNTU_APT_URL=https://mirrors.wikimedia.org/ubuntu
test -n "$XTRADEB_APT_URL" || XTRADEB_APT_URL=https://ppa.launchpadcontent.net/xtradeb/@AREA@/ubuntu

dist_release=$release
destin_release=
xtradeb_area=

set -o pipefail

print_xtradeb_sources()
{
	local area="$1"
	local suite="$2"

	cat <<END
Types: deb
URIs: $(echo "$XTRADEB_APT_URL" | sed "s,@AREA@,$area,")
Suites: $suite
Components: main
Architectures: amd64
Signed-By:
 -----BEGIN PGP PUBLIC KEY BLOCK-----
 Version: Hockeypuck 2.1.1-10-gec3b0e7
 .
 xsFNBF+pJfEBEADmJ5l2tbdD1kDqOCPqPc1QVoDqj0qsQ4byihHacOXZCHhPXnu3
 422//21fi5PvLvb+m2IqhMxXvHMW5XwScEWdNYpD3JhMmZHsk/Oe8b214Z88+LGf
 HoCDyT3fO331vN5fmVpC6AxiszwM9HY/oXfb/VPYZ6nRPyBtU7JPqNtOMLe2RWQo
 WpYGhyCQtn44GQZccw17paQSuC4Y1lY5eb7KpPiPhU8Nm623XnydJd7LNq+MZh+A
 57SXft4oZTclWnYDDWbk0b1L9R1AND9igkI0V00aKs/sj6tVweNS+HsqoSpmwpRt
 /PSC/UZ++KNBnub0Jw2kuO54o3tzeA6sy0Q7Hbz+nFWcI+oxjVofa+TRZSR/3c3R
 ZHnk90GnhVw4lIdVzPvde/rsXhwQMjqdesmW1sM+oOF/Mh9ZUBmyypOd83j4oKyf
 eSQ7E9JEb/kPzpKOkZydnsrjGq/TWNZoaf4U7DJvZ+Y6a2MC55L7en2HuI5HNyFQ
 V2O/IuHUxoINlEuT/oCI0yNg+B8Og5L0+9HOw+YggDLASGpwao8hPOIRgixL9XCU
 Z4CTdPgQLxwAo/1TySO0WKc8rxubSXXydNi4s5iicVRbECbQurLc1Y9ssNXkB4kf
 8KEznGahO1dTEZ+XtIuyXInB3WbxN3bbV6Cs/tUkJ0KuzungEPG4LzpVWQARAQAB
 zSVMYXVuY2hwYWQgUFBBIGZvciB4dHJhZGViIFVidW50dSB0ZWFtwsGOBBMBCgA4
 FiEEUwH6T9kyRPvG9hSZgrtoUcZPaIAFAl+pJfECGwMFCwkIBwIGFQoJCAsCBBYC
 AwECHgECF4AACgkQgrtoUcZPaIBwfRAAvFV6+Ff7zN5Eti/N9XJ7O8lv8UEUUDPp
 rDLiGoSeJQaeay/JYWRg96r2XSkw3tSWeBk/EixR5onOFGK/rT+6QlB9nqug+fQI
 ZpDybTRBYHETAYStkYYDHTBhsPpKnBFilei232Z1C3cMniIGTgtYZYcM3MH92fVd
 /7SCy4tPUvLSdAmzmGQzLX+qEXJO/u3i+4Vc1dbu6GdPeEhXGwQLmlnPmdXbGipa
 +Bpd+DB7++xMJMwBoHIT+8Nh9HMguxNycCy6Iz3O29Onl0QYkMnhy6mKl5z/Pqqm
 T9V1K9YZlme11+RSGJMBj6pJkCqh60LjcBxIsN62EMASCTCyyC5syWy5vMpek2Ji
 CjJorm3+WsT8iDJgxaSakXEzfvX8QWMK56hgpAAZFpl6EQm514qEHGKvrR2enwTW
 mRziYjrOdCNk76flVom+1Gns+F21pM6toxxUH4ESE+isvQGpnTLz+hDrqZkoVupn
 CCEnobsyYcT7U9l4DgksWHJZiP7Ht+/VmC87SP0B4ATg1ysHZrpBfV/7ddoyJ+6N
 v1rr9mcSXofUZVYgIG2q0NW9hRObHunWs3gkzjpAQ+Vp6syvCV0BA2QnX1RmImqt
 drCV7If++7t19PUmEjDHzK4QpFbpPmQ0APjkzQ7SP6qQsd6Ftdlu1muhCGOBbUxE
 +2FGi8kHKqg=
 =3I/o
 -----END PGP PUBLIC KEY BLOCK-----
END
}

case "$release" in
	xtradeb-*)
	IFS=- read x xtradeb_area dist_release destin_release <<<$release
	case "$xtradeb_area" in
		apps|deps|play|test) ;;
		*) echo "error: invalid XtraDeb area \"$xtradeb_area\""; exit 1 ;;
	esac
	;;
esac

case "$dist_release" in
	-h | --help | '')
	cat <<END

usage: $0 RELEASE PACKAGE ...
       $0 xtradeb-AREA-RELEASE {PACKAGE ... | --all}
       $0 xtradeb-AREA-RELEASE-DESTRELEASE {PACKAGE ... | --all}

(DEST)RELEASE is an Ubuntu release name like "jammy", "noble", etc.
AREA is "apps", "deps", "play", or "test"
PACKAGE is an existing package name, or a binary .deb file

Environment variables used in first-time initialization:

* ARCH: Debian architecture name to use; currently $(dpkg --print-architecture)

* UBUNTU_APT_URL: Location of your Ubuntu mirror; currently
  $UBUNTU_APT_URL

* XTRADEB_APT_URL: Location of the XtraDeb PPAs; currently
  $XTRADEB_APT_URL

END
	exit 0
	;;
esac

check_release()
{
	local rel="$1"
	case "$rel" in
		jammy | kinetic | lunar | mantic | noble | oracular) ;;
		plucky) ;;
		*) echo "error: unrecognized Ubuntu release \"$rel\""; exit 1 ;;
	esac
}

check_release "$dist_release"
test -z "$destin_release" || check_release "$destin_release"

mkdir -p $chdist_data

chdist="chdist --data-dir $chdist_data"

if [ -n "$ARCH" ]
then
	chdist+=" -a $ARCH"
	release+="-$ARCH"
fi

if [ ! -d $chdist_data/$release ]
then
	$chdist create $release \
		$UBUNTU_APT_URL \
		$(test -n "$destin_release" \
			&& echo "$destin_release" \
			|| echo "$dist_release") \
		main universe multiverse

	if [ -n "$xtradeb_area" ]
	then
		print_xtradeb_sources \
			$xtradeb_area \
			$dist_release \
			>$chdist_data/$release/etc/apt/sources.list.d/xtradeb-$xtradeb_area-$dist_release.sources
	fi

	# Give greater preference to XtraDeb packages
	cat >$chdist_data/$release/etc/apt/preferences.d/xtradeb.pref <<END
Package: *
Pin: release o=LP-PPA-xtradeb-*
Pin-Priority: 990
END

	# Don't need Translation-xx files
	(echo; echo 'Acquire::Languages { "none"; }') \
		>>$chdist_data/$release/etc/apt/apt.conf

	# Don't need source packages
	perl -pi -e '/^deb-src / and s/^/#/' \
		$chdist_data/$release/etc/apt/sources.list{,.d/*.list} \
		2>/dev/null

	$chdist apt-get $release update --error-on=any || exit
fi

# Update the APT index if it's over an hour old
#
cache=$chdist_data/$release/var/cache/apt/pkgcache.bin
if ! find $cache -mmin -60 | grep -q .
then
	$chdist apt-get $release update || exit
fi

filter_apt_get_output()
{
	grep -Ev '^(Conf|Inst) ' \
	| grep -Ev '^(given|when) is deprecated at '
}

target=${destin_release:+-t $dist_release}

if [ "_$1" = _--all ]
then
	if [ -z "$xtradeb_area" ]
	then
		echo 'error: --all is only supported for XtraDeb repos'
		exit 1
	fi

	failed_packages=

	for pkg in $(sed -n 's/^Package: //p' \
		$chdist_data/$release/var/lib/apt/lists/*_xtradeb_*_Packages)
	do
		echo "==== Checking $pkg ===="
		if $chdist apt-get $release -s $target install $pkg 2>&1 \
		| filter_apt_get_output
		then
			echo "Success: $pkg"
		else
			echo "FAILED: $pkg"
			failed_packages+=" $pkg"
		fi
		echo
	done

	if [ -z "$failed_packages" ]
	then
		echo 'All packages can be installed.'
		exit 0
	fi

	echo "The following package(s) cannot be installed${destin_release:+ on $destin_release}:"

	for pkg in $failed_packages
	do
		echo "  $pkg"
	done

	exit 1
fi

packages=

for pkg in "$@"
do
	# When installing local .deb files with apt-get(8),
	# a directory prefix is needed
	#
	case "$pkg" in
		/* | ./* | ../*) ;;
		*.deb) pkg="./$pkg" ;;
	esac
	packages+=" $pkg"
done

echo + apt-get -s $target install $packages

$chdist apt-get $release -s $target install $packages 2>&1 \
| filter_apt_get_output \
|| exit

echo
echo 'Package can-install check successful.'

# EOF
