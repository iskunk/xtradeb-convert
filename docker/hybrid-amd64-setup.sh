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
	echo "$@" | sed 's/ /, /g'
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

	x=/etc/apt/sources.list
	test ! -f $x || run_cmd mv -fv $x $x.orig
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
	bash \
	coreutils \
	dash \
	findutils \
	gzip \
	sed \
	tar \
)

run_cmd apt-get -y --allow-remove-essential --no-install-recommends install \
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

run_cmd apt-get -y install $(add_arch_suffix amd64 $tool_pkgs)

run_cmd apt-get -y install nodejs:amd64

# LLVM (need both native + amd64 packages for this one)

N=16

llvm_pkgs=$(echo \
	clang-$N \
	clang-format-$N \
	libclang-common-$N-dev:all \
	libclang-cpp$N \
	$(test $N -lt 16 && echo libclang-$N-dev || echo libclang-rt-$N-dev) \
	libclang1-$N \
	lld-$N \
	llvm-$N-linker-tools \
)

# Install this subset natively so we don't need to set LD_LIBRARY_PATH
#
llvm_dep_pkgs="libllvm$N"

run_cmd apt-get -y install $llvm_pkgs

run_cmd apt-get -y install $(add_arch_suffix amd64 $llvm_dep_pkgs)

########

ctl_file=/tmp/hybrid-hack-deps.ctl
cat > $ctl_file << END
Package: hybrid-hack-deps
Provides: $(comma_sep $(add_arch_suffix $arch $tool_pkgs nodejs))
Architecture: $arch
Multi-Arch: same
Description: Hybrid $arch/amd64 system hack - dependencies
 This metapackage prevents "PACKAGE:amd64" packages from being removed
 in favor of "PACKAGE" (implicitly "PACKAGE:$arch") ones.
END

(cd /tmp && run_cmd equivs-build $ctl_file)

(cd /tmp && run_cmd apt-get -y install ./hybrid-hack-deps_*.deb)

########

# The amd64 LLVM toolchain needs to be installed outside of the package
# system; too much breaks otherwise. The $llvm_dep_pkgs should make it
# unnecessary to set LD_LIBRARY_PATH, however.

mkdir /tmp/llvm-pkgs

(cd /tmp/llvm-pkgs && run_cmd apt-get download \
	$(add_arch_suffix amd64 $llvm_pkgs))

run_cmd mkdir /opt/llvm-amd64

for deb in /tmp/llvm-pkgs/*.deb
do
	run_cmd dpkg-deb -x $deb /opt/llvm-amd64
done

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
