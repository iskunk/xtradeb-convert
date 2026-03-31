#!/bin/bash
# setup.sh
#
# Miscellaneous container setup
#

set -eu
dir=$(dirname $0)
cd /tmp

check_for_existing_config()
{
	if [ -f $conf ]
	then
		echo "error: $conf: file already exists"
		exit 1
	fi
}

##
## Hybrid-amd64 setup
##

$dir/hybrid-amd64-setup.sh

##
## Enable package testing on real riscv64 hardware
##

x=/usr/share/perl5/Dpkg/Vendor/Ubuntu.pm

if [ -f $x -a "_$(uname -m)" = _riscv64 ]
then
	sed -ri 's/^(\s+)(.*nocheck.*riscv64)/\1#xtradeb#\2/' $x
fi

##
## ccache
##

if [ ! -f /usr/bin/ccache ]
then
	echo "error: ccache is not installed"
	exit 1
fi

conf=/etc/ccache.conf
check_for_existing_config

cat > $conf << END
cache_dir = /external/ccache
compiler_check = %compiler% -v
inode_cache = false
max_size = 20G

# Workaround for https://github.com/ninja-build/ninja/issues/1330
path = /usr/bin

sloppiness = include_file_ctime, include_file_mtime, locale, time_macros
temporary_dir = /external/tmp
END
echo "Created $conf ."

##
## quilt
##

conf=/etc/quilt.quiltrc
mv -v $conf $conf.orig

cat > $conf << 'END'
EDITOR=nano

QUILT_DIFF_ARGS="--no-index --no-timestamps --color=auto"
QUILT_DIFF_OPTS="-p"
QUILT_REFRESH_ARGS="-p ab --sort --no-index --no-timestamps"
QUILT_PATCH_OPTS="--reject-format=unified"
test -n "$QUILT_PATCHES" || QUILT_PATCHES=debian/patches
QUILT_PUSH_ARGS="--fuzz=0"
END

# end setup.sh
