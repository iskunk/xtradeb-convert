#!/bin/sh
# hybrid-amd64-setup.sh

export DEBIAN_FRONTEND=noninteractive

set -e

arch=$(dpkg --print-architecture)
suite=$(lsb_release -cs 2>/dev/null)

case "$arch" in
	amd64 | i[3-6]86)
	echo 'Not applicable to this architecture'
	exit 0
	;;
esac

if [ "_$QEMU_BINFMT" = _dummy ]
then
	echo 'Not applicable as no emulation is active'
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

if [ "_$(lsb_release -is)" = _Ubuntu ]
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

	test "_$suite" != _jammy || cat >> $x << END

Types: deb
URIs: https://ppa.launchpadcontent.net/xtradeb/deps/ubuntu
Architectures: $arch amd64
Suites: $suite
Components: main
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

# LLVM (need both native + amd64 packages for this one)

case "$suite" in
	jammy | noble | oracular) N=18 ;;
	plucky) N=20 ;;
	*) N=19 ;;
esac

case "$suite,$arch,$N" in
	jammy,*,*) t64= ;;
	*,armhf,* | *,i386,*) t64= ;;
	*,*,1[67]) t64=t64 ;;
esac

llvm_pkgs=$(echo \
	clang-$N \
	clang-format-$N \
	libclang-common-$N-dev:all \
	libclang-cpp$N$t64 \
	$(test $N -lt 16 && echo libclang-$N-dev || echo libclang-rt-$N-dev) \
	libclang1-$N$t64 \
	libllvm$N \
	lld-$N \
	llvm-$N-linker-tools \
)

# Temporarily install this subset so its amd64 dependencies get pulled in
#
llvm_dep_pkgs="libllvm$N"

pkgs=$(add_arch_suffix amd64 $llvm_dep_pkgs)
run_cmd apt-get -y install $pkgs
run_cmd apt-get -y remove  $pkgs

run_cmd apt-get -y install $llvm_pkgs

########

# Workaround for
#   https://bugs.debian.org/1106209
#   https://bugs.launchpad.net/bugs/2111189
run_cmd apt-get -y install node-corepack node-minimatch
tmp_nodejs_deps='node-corepack:amd64 (= 9.9.9), node-minimatch:amd64 (= 9.9.9)'

ctl_file=/tmp/hybrid-hack-tools.ctl
cat > $ctl_file << END
Package: hybrid-hack-tools
Provides: $(make_provides $arch $tool_pkgs nodejs), $tmp_nodejs_deps
Architecture: $arch
Multi-Arch: same
Description: Hybrid $arch/amd64 system hack - dependencies
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

########

# The amd64 LLVM toolchain needs to be installed outside of the package
# system; too much breaks otherwise.

mkdir /tmp/llvm-pkgs

(cd /tmp/llvm-pkgs && run_cmd apt-get download \
	$(add_arch_suffix amd64 $llvm_pkgs))

run_cmd mkdir /opt/llvm-amd64

for deb in /tmp/llvm-pkgs/*.deb
do
	run_cmd dpkg-deb -x $deb /opt/llvm-amd64
done

rm -r /tmp/llvm-pkgs

# Create compiler wrapper script

target=$(clang-$N -print-target-triple)

x=/opt/llvm-amd64/wrap.sh
echo "Creating $x to set --target=$target ..."

cat > $x << END
#!/bin/bash

name=\${0##*/}
name=\${name%%-$N}

case "\$name" in
	ld.lld) target_opt= ;;
	*)      target_opt=--target=$target ;;
esac

export LD_LIBRARY_PATH=/opt/llvm-amd64/lib/x86_64-linux-gnu

exec -a \$0 /opt/llvm-amd64/lib/llvm-$N/bin/\$name \$target_opt "\$@"
END
run_cmd chmod 755 /opt/llvm-amd64/wrap.sh

# Set up the /opt area

(set -ex
 cd /opt/llvm-amd64
 mv usr/* . && rmdir usr
 mv bin bin.orig && mkdir bin
 rm -rf include
 rm -rf lib/clang
 rm -rf lib/cmake
 rm -rf lib/llvm-*/lib/clang
 rm -rf lib/llvm-*/lib/cmake
 rm -rf lib/llvm-*/share
 rm -rf share
)

# Make the amd64 LLVM programs accessible under /opt/llvm-amd64/bin/
# and /usr/bin/
#
for name in $(cd /opt/llvm-amd64/bin.orig && find * -type l)
do
	ln -s ../wrap.sh /opt/llvm-amd64/bin/$name
	run_cmd mv -f /usr/bin/$name /usr/bin/$name.$arch
	run_cmd ln -s /opt/llvm-amd64/bin/$name /usr/bin
done

# This library may be needed for some things, but cannot be installed
# natively (at least for N=11) due to lack of multi-arch support
#
x=/opt/llvm-amd64/lib/x86_64-linux-gnu/libclang-cpp.so.$N
y=/usr/lib/x86_64-linux-gnu/libclang-cpp.so.$N
if [ -f $x -a ! -f $y ]
then
	run_cmd ln -s $x $y
fi

# end hybrid-amd64-setup.sh
