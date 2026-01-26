#!/bin/sh
# hybrid-amd64-setup.sh

export DEBIAN_FRONTEND=noninteractive

set -e

arch=$(dpkg --print-architecture)
distro=$(lsb_release -is 2>/dev/null)
suite=$(lsb_release -cs 2>/dev/null)

case "$arch" in
	amd64 | i[3-6]86)
	echo 'Not applicable to this architecture'
	exit 0
	;;
esac

if [ "_$(uname -m)" != _x86_64 ]
then
	echo 'Not applicable, not running on amd64'
	exit 0
fi

run_cmd()
{
	(set -x; "$@") || exit
}

add_arch_suffix()
{
	local suffix="$1"; shift
	for x in "$@"; do
		case "$x" in
			*:*) echo "$x" ;;
			*) echo "$x:$suffix" ;;
		esac
	done
}

comma_sep()
{
	(for arg in "$@"; do printf "$arg, "; done; echo) | sed 's/, $//'
}

make_provides()
{
	local arch="$1"
	shift

	local pkg_arch
	for pkg_arch in $(add_arch_suffix $arch "$@")
	do
		local version=$(apt-cache --no-all-versions show $pkg_arch \
			| sed -n 's/^Version: //p')
		printf '%s (= %s), ' "$pkg_arch" "$version"
	done \
	| sed 's/ (= ),/,/g; s/, $//'
}

if [ $distro = Ubuntu ]
then
	x=/etc/apt/sources.list.d/ubuntu-hybrid.sources
	echo "Creating $x ..."

	cat > $x << END
Types: deb
#URIs: http://ports.ubuntu.com/
URIs: https://mirrors.ocf.berkeley.edu/ubuntu-ports
#URIs: https://ftp.tu-chemnitz.de/pub/linux/ubuntu-ports
Architectures: $arch
Suites: $suite $suite-updates
Components: main universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
#URIs: http://archive.ubuntu.com/ubuntu
URIs: https://mirror.us.leaseweb.net/ubuntu
Architectures: amd64
Suites: $suite $suite-updates
Components: main universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
#URIs: http://security.ubuntu.com/ubuntu
URIs: https://mirror.us.leaseweb.net/ubuntu
Architectures: amd64
Suites: $suite-security
Components: main universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
END

	for x in \
		/etc/apt/sources.list \
		/etc/apt/sources.list.d/ubuntu.sources
	do
		test ! -f $x || run_cmd mv -fv $x $x.orig
	done
fi

run_cmd dpkg --add-architecture amd64

run_cmd apt-get --error-on=any update

# Start by installing something small, to pull in the (amd64) C library
# and all its associated dependencies
#
run_cmd apt-get -y install ed:amd64

# TEMPORARY 2023-11: Some massaging is needed on riscv64 due to
# package versions not matching those on amd64
#
if [ $arch = riscv64 ]
then
	script_dir=$(realpath $(dirname $0))
	(cd /tmp && run_cmd $script_dir/hybrid-match-versions.sh \
		libacl1 libattr1 libffi8 libmd0 libselinux1 libxml2 libz3-4)

	(cd /tmp && run_cmd apt-get -y install ./*_fixed.deb)
fi

# Replace some essential packages

essential_pkgs=$(echo \
	apt \
	apt-utils \
	bash \
	coreutils \
	dash \
	dpkg \
	findutils \
	gzip \
	sed \
	tar \
)

ctl_file=/tmp/hybrid-hack-essential.ctl
cat > $ctl_file << END
Package: hybrid-hack-essential
Depends: $(comma_sep $(add_arch_suffix amd64 $essential_pkgs) )
Provides: $(make_provides $arch $essential_pkgs)
Architecture: $arch
Multi-Arch: same
Description: Hybrid $arch/amd64 system hack - essential packages
 This metapackage smooths over package dependencies on the native builds
 of a number of essential packages that have been replaced with their
 amd64 counterparts.
END
(cd /tmp
 echo ----; cat $ctl_file; echo ----
 run_cmd equivs-build $ctl_file
 run_cmd apt-get -y install ./hybrid-hack-essential_*.deb
 rm hybrid-hack-essential*
)

# Hang onto the native dpkg binary, as there is no way to tell it the
# primary system architecture like there is with APT
run_cmd cp -p /usr/bin/dpkg /usr/bin/dpkg.$arch

cat > /etc/apt/apt.conf.d/02hybrid-hack << END
APT::Architecture "$arch";
Dir::Bin::dpkg "/usr/bin/dpkg.$arch";
END

# Replace dpkg first, to avoid missing-program errors
run_cmd apt-get -y \
	--allow-remove-essential \
	--no-install-recommends \
	install \
	dpkg:amd64 dpkg:$arch-

# Workaround for dpkg-architecture(1)
# (see get_raw_build_arch() in /usr/share/perl5/Dpkg/Arch.pm)
run_cmd ln -s ../../bin/dpkg.$arch /usr/local/bin/dpkg

run_cmd apt-get -y \
	--allow-remove-essential \
	--no-install-recommends \
	install \
	$(add_arch_suffix amd64  $essential_pkgs) \
	$(add_arch_suffix $arch- $essential_pkgs)

# Miscellaneous

# Note: Don't include generate-ninja, as its {host,current,target}_cpu
# variables default to its own architecture
#
tool_pkgs=$(echo \
	ccache \
	ninja-build \
	patch \
	xz-utils \
)

run_cmd apt-get -y install \
	$(add_arch_suffix amd64  $tool_pkgs) \
	$(add_arch_suffix $arch- $tool_pkgs)

########

# Workaround for
#   https://bugs.debian.org/1106209
#   https://bugs.launchpad.net/bugs/2111189
if [ $distro = Debian ]
then
	run_cmd apt-get -y install node-corepack node-minimatch
else
	run_cmd apt-get -y install node-minimatch
fi
tmp_nodejs_deps='node-corepack:amd64 (= 9.9.9), node-minimatch:amd64 (= 9.9.9)'

ctl_file=/tmp/hybrid-hack-tools.ctl
cat > $ctl_file << END
Package: hybrid-hack-tools
Provides: $(make_provides $arch $tool_pkgs nodejs node-types-node), $tmp_nodejs_deps
Architecture: $arch
Multi-Arch: same
Description: Hybrid $arch/amd64 system hack - tool packages
 This metapackage smooths over package dependencies on the native builds
 of a number of tool packages that have been replaced with their amd64
 counterparts.
END
(cd /tmp
 echo ----; cat $ctl_file; echo ----
 run_cmd equivs-build $ctl_file
 run_cmd apt-get -y install ./hybrid-hack-tools_*.deb
 rm hybrid-hack-tools*
)

########

# Node.js

run_cmd apt-get -y install nodejs:amd64
run_cmd apt-mark hold nodejs:amd64

# end hybrid-amd64-setup.sh
