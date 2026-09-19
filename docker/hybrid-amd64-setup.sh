#!/bin/sh
# hybrid-amd64-setup.sh

export DEBEMAIL=root@example.com
export DEBIAN_FRONTEND=noninteractive

set -e

arch=$(dpkg --print-architecture)
distro=$(lsb_release -is 2>/dev/null)
suite=$(lsb_release -cs 2>/dev/null)

case "$arch" in
	amd64 | i[3-6]86)
	echo 'Not applicable to this architecture.'
	exit 0
	;;
esac

if [ "_$CONTAINER_HOST_ARCH" != _x86_64 ]
then
	echo 'Not applicable, not running on amd64.'
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

# Replace some essential packages

essential_pkgs=$(echo \
	apt \
	apt-utils \
	bash \
	$(test -f /var/lib/dpkg/info/gnu-coreutils.list \
		&& echo gnu-coreutils || echo coreutils) \
	$(test -f /var/lib/dpkg/info/rust-coreutils.list \
		&& echo rust-coreutils || :) \
	dash \
	findutils \
	grep \
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

cat > /etc/apt/apt.conf.d/02hybrid-hack << END
APT::Architecture "$arch";
END

# Create temporary copies of some coreutils programs, as dpkg will need
# them while swapping out the coreutils package(s)
mkdir /tmp/coreutils-tmp
for x in cp mv rm
do
	cp /usr/bin/$x /tmp/coreutils-tmp/
done
cat > /etc/apt/apt.conf.d/99coretils-tmp << END
DPkg::Path "/tmp/coreutils-tmp:/usr/sbin:/usr/bin:/sbin:/bin";
END

run_cmd apt-get -y \
	--allow-remove-essential \
	--no-install-recommends \
	install \
	$(add_arch_suffix amd64  $essential_pkgs) \
	$(add_arch_suffix $arch- $essential_pkgs)

rm -r /tmp/coreutils-tmp /etc/apt/apt.conf.d/99coretils-tmp

# Miscellaneous

# Note: Don't include generate-ninja, as its {host,current,target}_cpu
# variables default to its own architecture
#
tool_pkgs=$(echo \
	ccache \
	make \
	ninja-build \
	openssh-client \
	patch \
	xz-utils \
)

ctl_file=/tmp/hybrid-hack-tools.ctl
cat > $ctl_file << END
Package: hybrid-hack-tools
Provides: $(make_provides $arch $tool_pkgs)
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

run_cmd apt-get -y install \
	$(add_arch_suffix amd64  $tool_pkgs) \
	$(add_arch_suffix $arch- $tool_pkgs)

########

# Node.js

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

ctl_file=/tmp/hybrid-hack-nodejs.ctl
cat > $ctl_file << END
Package: hybrid-hack-nodejs
Provides: $(make_provides $arch nodejs node-types-node), $tmp_nodejs_deps
Architecture: $arch
Multi-Arch: same
Description: Hybrid $arch/amd64 system hack - Node.js packages
 This metapackage smooths over package dependencies on the native builds of
 Node.js packages that have been replaced with their amd64 counterparts.
END
(cd /tmp
 echo ----; cat $ctl_file; echo ----
 run_cmd equivs-build $ctl_file
 run_cmd apt-get -y install ./hybrid-hack-nodejs_*.deb
 rm hybrid-hack-nodejs*
)

run_cmd apt-get -y install nodejs:amd64
run_cmd apt-mark hold nodejs:amd64

# end hybrid-amd64-setup.sh
