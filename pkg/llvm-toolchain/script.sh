# pkg/llvm-toolchain/script.sh
#
# https://packages.ubuntu.com/source/llvm-toolchain-NN (pattern)
# https://packages.ubuntu.com/source/llvm-toolchain-20
# https://packages.ubuntu.com/source/llvm-toolchain-21
# https://packages.ubuntu.com/source/llvm-toolchain-22
#

################################################################

xd_convert() {

dpkg --compare-versions $deb_version ge 1:20.0.0 \
|| error 'version < 20 is not supported'

################

# Don't use the alternative "| hello" build dependencies, so that we
# have better control over how the package is built.
sed -i '/^BD_ALT_HELLO = yes/ s/yes/xtradeb_no/' $debian/rules

# Delete the "| hello" comment verbiage, as it no longer applies.
sed -i \
	-e '/^# .* is for older buster.bionic distros / d' \
	-e '/^# We need to keep the constraints coherent / d' \
	-e '/^# hello would get installed unexpectedly / d' \
	$debian/control.in

# Don't skip the build of common packages (like libc++1).
sed -i '/^SKIP_COMMON_PACKAGES = yes/ s/yes/xtradeb_no/' $debian/rules

# Don't use dependencies from other llvm-toolchain-NN builds...
sed -ri '/^\s+llvm-spirv-[0-9]+ [^,]+,$/ d' $debian/control.in

# ...including lld. (Note that jammy on riscv64 has no "lld" package.)
sed -ri '/^\s+/ s/, lld [^,]+,/,/' $debian/control.in
sed -ri \
	-e 's/^(LLD_BUILD_ARCHS :=)/\1 #xtradeb#/' \
	-e '/^BINUTILS_ARCHS :=/ { s/^/#xtradeb#/' \
	-e 'a BINUTILS_ARCHS := $(LLD_ARCHS) # XtraDeb' -e '}' \
	$debian/rules

# Don't build Windows support, as the MinGW libraries may not be
# up to snuff (e.g. missing InitOnceExecuteOnce() in jammy).
sed -ri '/^\s+mingw-w64-common,$/d' $debian/control.in
zap_control_package 'libclang-rt-\@\w+\@-dev-win' $debian/control.in

if ubuntu_dist jammy noble
then
	# Avoid compile error on ppc64el related to
	# the IBM-to-IEEE "long double" transition:
	# https://developers.redhat.com/articles/2023/05/16/benefits-fedora-38-long-double-transition-ppc64le
	sed -i \
		-e '/^OFFLOAD_ARCHS *=/ { s/ppc64el//' \
		-e '  i # XtraDeb: Drop ppc64el due to' \
		-e '  i # https://github.com/llvm/llvm-project/issues/184994' \
		-e '}' \
		$debian/rules
fi

# Allow the creation of stamps/preconfigure to fail, in case
# the source-package tree outside of debian/ is read-only during
# the regeneration step below.
sed -ri '/^\s+if ! dh_listpackages/,/^\S+:/ s/^(\s+)(@mkdir|touch)\b/\1-\2/' \
	$debian/rules

# Neutralize a couple of checks in the rules file so that we don't
# need a full development setup for the regeneration step below.
sed -ri 's/^(\s+if) (! (dh_listpackages|dpkg -l)\|grep -q )/\1 false XtraDeb \&\& \2/' \
	$debian/rules

# Disable the protection against modifying e.g. debian/control,
# since that's exactly what we want to do.
sed -ri '/^\s+..(snapshot|verify)_generated_tracked_files./ s/^/#XtraDeb#/' \
	$debian/rules

##
## Patch series modifications
##

# Don't use the RISC-V RVA23 profile prior to 25.10/questing.
rva23_patch=ubuntu-clang-use-RVA23U64-profile.patch
if ubuntu_dist jammy noble && grep -Fqx $rva23_patch $debian/patches/series
then
	disable_patch $rva23_patch
fi

} # xd_convert()

################################################################

xd_convert_post() {

# Abbreviate an Ubuntu bit in the version string
sed -ri '1s/(-[0-9]+)ubuntu([0-9]+)/\1u\2/' $debian/changelog

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
