# pkg/llvm-toolchain/script.sh
#
# https://packages.ubuntu.com/source/llvm-toolchain-NN (pattern)
# https://packages.ubuntu.com/source/llvm-toolchain-20
# https://packages.ubuntu.com/source/llvm-toolchain-21
#

################################################################

xd_convert() {

dpkg --compare-versions $deb_version ge 1:19.0.0 \
|| error 'version < 19 is not supported'

dpkg --compare-versions $deb_version ge 1:19.1.7 \
|| error 'please convert version >= 19.1.7 to avoid https://bugs.launchpad.net/bugs/2097731'

################

# Don't use the alternative "| hello" build dependencies, so that we
# have better control over how the package is built.
sed -i '/^BD_ALT_HELLO = yes/ s/yes/xtradeb_no/' $debian/rules

# Delete the "| hello" comment verbiage, as it no longer applies.
sed -i \
	-e '/^# .* is for older buster.bionic distros /d' \
	-e '/^# We need to keep the constraints coherent /d' \
	-e '/^# hello would get installed unexpectedly /d' \
	$debian/control.in

# Don't skip the build of common packages (like libc++1).
sed -i '/^SKIP_COMMON_PACKAGES = yes/ s/yes/xtradeb_no/' $debian/rules

# Don't use dependencies from other llvm-toolchain-NN builds...
sed -i -r '/^\s+llvm-spirv-[0-9]+ [^,]+,$/d' $debian/control.in

# ...including lld. (Note that jammy on riscv64 has no "lld" package.)
sed -i -r '/^\s+/ s/, lld [^,]+,/,/' $debian/control.in
sed -i -r \
	-e 's/^(LLD_BUILD_ARCHS :=)/\1 #xtradeb#/' \
	-e '/^BINUTILS_ARCHS :=/ { s/^/#xtradeb#/' \
	-e 'a BINUTILS_ARCHS := $(LLD_ARCHS) # XtraDeb' -e '}' \
	$debian/rules

# Don't build Windows support, as the MinGW libraries may not be
# up to snuff (e.g. missing InitOnceExecuteOnce() in jammy).
sed -i -r '/^\s+mingw-w64-common,$/d' $debian/control.in
zap_control_package 'libclang-rt-\@\w+\@-dev-win' $debian/control.in

# Fix an incompatibility between two binary packages from 19
# (see https://bugs.launchpad.net/bugs/2139024)
sed -i -r '/^Breaks: libomp-@\w+@-dev \(<< 1:2024[0-9]+\+[0-9a-f]+\)$/d' \
	$debian/control.in

# Neutralize a couple of checks in the rules file so that we don't
# need a full development setup for the regeneration step below.
sed -i -r '/installed by another constraint|dh_listpackages;/{n;s/^(\s+)(exit 1)/\1true XtraDeb \2/}' \
	$debian/rules

} # xd_convert()

################################################################

xd_convert_post() {

# Abbreviate an Ubuntu bit in the version string
sed -i -r '1s/(-[0-9]+)ubuntu([0-9]+)/\1u\2/' $debian/changelog

# Regenerate files
if [ -f $debian/../LICENSE.TXT -a "_$(basename $debian)" = _debian ]
then
	rm -f $debian/../stamps/preconfigure

	# Regenerate files
	(unset MAKEFLAGS; cd $debian/.. && set -x && debian/rules stamps/preconfigure override_dh_auto_clean) \
	|| error 'failed to regenerate debianization files'
	echo
else
	cat <<END

Note: Please run

  \$ cd $(cd $debian/.. && pwd)
  \$ rm -f stamps/preconfigure
  \$ debian/rules stamps/preconfigure

in the LLVM source tree, to regenerate necessary files.

END
fi

} # xd_convert_post()

################################################################

# end pkg/llvm-toolchain/script.sh
