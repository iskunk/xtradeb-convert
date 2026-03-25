# pkg/nodejs/script.sh
#
# https://packages.debian.org/source/sid/pkg-js-tools#pdownload
# https://packages.debian.org/source/sid/node-undici#pdownload
# https://packages.debian.org/source/sid/node-cjs-module-lexer#pdownload
# https://packages.debian.org/source/sid/nodejs#pdownload
#
#
# Note: To build nodejs v20 on jammy, the following packages need to be
# imported from a newer release:
#
#   node-cjs-module-lexer
#   node-llhttp
#   node-minimatch
#   node-undici
#
# On noble, only one is needed: node-minimatch
#
# To build chromium on jammy, the following additional packages need to be
# imported from a newer release:
#
#   node-ampproject-remapping (a.k.a. node-jridgewell-source-map)
#   node-glob
#   node-rollup-plugin-terser
#   node-terser
#
# (On noble, no additional packages are needed.)
#

################################################################

xd_convert() {

ubuntu_dist jammy noble VENDOR \
|| not_applicable 'this script is needed only for jammy and noble'

case "$deb_version" in
	20.*) ;;
	*) error 'only version nodejs 20.*.* is supported at this time' ;;
esac

add_to_changelog << END
NOTE: This package has been modified to provide static libraries only, and
no documentation. It is intended solely for use as a build dependency.
END

# Drop/downgrade some build dependencies
sed -ri \
	-e '/^\s+gyp / d' \
	-e '/^\s+libnghttp3-dev / s/>= .*\)/>= 0.1.1)/' \
	-e '/^\s+libngtcp2-dev / s/>= .*\)/>= 0.1.0)/' \
	-e '/^\s+libsimdjson-dev / s/>= .*\)/>= 1.0.2)/' \
	-e '/^\s+node-.* <!nodoc>,/ d' \
	$debian/control

# Upgrade these to reflect reality
sed -ri \
	-e '/^\s+libicu-dev / s/>= .*\)/>= 71.0)/' \
	$debian/control

if ubuntu_dist jammy
then
	# There is no pre-existing (older) package of nodejs for jammy on
	# riscv64, which is a problem, as a number of the build dependencies
	# require it (via Depends:, despite not actually *using* it).
	# We hack APT with a dummy package to get past that annoyance.
	perl -pi -e '/^(\s+)curl / and $_.="${1}dummy-nodejs [riscv64],\n"' \
		$debian/control

	# Pkg-config is better supported on jammy than pkgconf
	sed -ri 's/^(\s+)pkgconf,/\1pkg-config,/' $debian/control
fi

# Drop this install dependency, as it does not appear to be needed
# (and the package is not available in jammy/noble at any rate)
sed -ri '/^\s+node-corepack / d' $debian/control

# Copy over the node-* package dependencies from libnodeNNN to nodejs,
# as we will be getting rid of the former, and need those dependencies
# to take effect when the package is used.
sed -nr '/^Package: libnode[0-9]{3}/,/^Description:/ p' $debian/control \
| grep -E '^\s+node-' \
> $debian/xtradeb.tmp
(cd $debian && sed -ri -e '/^\s+libnode[0-9]{3} \([^)]+\)/ {r xtradeb.tmp' -e 'd}' control)
rm $debian/xtradeb.tmp
# Don't build the libnodeNNN package, nor its shared library
# (for better build-dep hygiene)
zap_control_package 'libnode\d{3}' $debian/control
sed -i '/^\s*--shared \\$/ d' $debian/rules

# Use the bundled libuv
sed -ri '/^\s+libuv1-dev[ :]/ d' $debian/control
sed -i '/^\s*DEB_CONFIGURE_EXTRA_FLAGS += --shared-libuv/ s/^/#xtradeb#/' \
	$debian/rules

# Don't build documentation, as this requires additional dependencies
sed -ri '/\$\(MAKE\) doc-only/ s/^/#xtradeb#/' $debian/rules
rm -v $debian/*.docs
zap_control_package nodejs-doc $debian/control
# Drop the Recommends:, too
sed -ri '/^\s+nodejs-doc$/ d' $debian/control

cat > $debian/xtradeb.tmp << END
# XtraDeb
# noble
skipTests += parallel/test-eventsource.js
skipTests += parallel/test-tls-alert.js
skipTests += parallel/test-tls-session-cache.js
# long timeouts on jammy + noble
skipTests += parallel/test-cluster-primary-error.js
skipTests += parallel/test-cluster-primary-kill.js

END
(cd $debian && sed -i -e '/^export HOME =/ {r xtradeb.tmp' -e 'N}' rules)
rm $debian/xtradeb.tmp

if ubuntu_dist jammy
then
	# Linking seems to need quite a bit more RAM on jammy
	sed -i \
		-e '/^export CPPFLAGS$/ {i # XtraDeb' \
		-e 'i LDFLAGS += -Wl,--reduce-memory-overheads\n' \
		-e '}' \
		$debian/rules

	mkdir $debian/pkgconfig
	cat > $debian/pkgconfig/simdjson.pc << END
# XtraDeb workaround for the lack of a simdjson.pc file in the
# libsimdjson-dev 1.0.2 package in jammy

Name: simdjson
Cflags: -DSIMDJSON_THREADS_ENABLED=1
Libs: -lsimdjson
END
	sed -i \
		-e '/^BRANCH :=/ {G;a # XtraDeb workaround' \
		-e 'a export PKG_CONFIG_PATH = $(CURDIR)/debian/pkgconfig' \
		-e '}' \
		$debian/rules
fi

##
## Patch series modifications
##

new_patch xtradeb-gyp-subset.patch

new_patch xtradeb-nodejs20-c-ares-downgrade.patch
new_patch xtradeb-nodejs20-no-double-build.patch

} # xd_convert()

################################################################

xd_check() {

include_xtradeb_ppa=deps

default_check "$@"

} # xd_check()

################################################################

# end pkg/nodejs/script.sh
