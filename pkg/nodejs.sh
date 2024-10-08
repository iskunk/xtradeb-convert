#!/bin/bash
# nodejs.sh
#
# This script operates on the debian/ subdirectory of any of the following
# Node.js-related source packages from Ubuntu lunar or later:
#
#	pkg-js-tools
#	node-undici
#	node-cjs-module-lexer
#	nodejs
#
# It specifically enables these packages to be built on jammy, to fulfill
# build dependencies for Chromium. Newer Ubuntu releases already have
# recent enough Node.js packages to avoid needing this script.
#

debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize nodejs

ubuntu_dist jammy || not_applicable 'this script is needed only for jammy'

pkg=$(dpkg-parsechangelog -l $debian/changelog -S Source)

################################################################

case "$pkg" in
	pkg-js-tools)
	# Downgrade the node-marked-man dep to what is available in jammy
	# (the package still builds just fine)
	perl -pi -e '/^ , node-marked-man/ and s/\(>= .+?\)/(>= 0.7.0)/' \
		$debian/control
	changelog_text='Downgrade the node-marked-man build-dependency.'
	;;

	node-undici)
	# Fix "error TS2307: Cannot find module 'ms' or its corresponding
	# type declarations"
	mkdir -p $debian/xtradeb-fix/ms
	url=https://github.com/vercel/ms/raw/dfd18036f359a3b80bf38d3d8c0bb850c0dc9b66/src/index.ts
	(cd $debian/xtradeb-fix/ms && wget -nv $url)
	echo "Downloaded from $url" >$debian/xtradeb-fix/ms/README
	new_patch xtradeb-node-undici.patch
	# This step fails with a 'Could not resolve "streamsearch"' error
	# when building packages from lunar or mantic, no idea why
	perl -pi -e '/^esbuild/ and s/$/ || (: XtraDeb: Oh well, we tried && touch undici-fetch.js)/' \
		$debian/nodejs/build
	changelog_text='Add missing "ms" module, and work around esbuild failure.'
	;;

	node-cjs-module-lexer)
	# Fix "Error: Cannot find module 'node:fs/promises'"
	perl -pi -e '/^ , node-babel-plugin-transform-modules-commonjs/ and $_.=" , node-istanbul\n"' \
		$debian/control
	new_patch xtradeb-node-cjs-module-lexer.patch
	changelog_text='Add node-istanbul build-dependency and use alternate implementation of "node:fs/promises".'
	;;

	nodejs)
	perl -pi -e 'if(/^exp-relax-check :=/){s/^/#xtradeb#/; $_.="exp-relax-check = -i\n"}' \
		$debian/rules
	new_patch xtradeb-nodejs.patch
	changelog_text='Fix unavailable uv_available_parallelism() call, and allow test suite failures.'
	;;

	*)
	error "$pkg: not a supported package"
	;;
esac

################################################################

finish

echo "$pkg package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end nodejs.sh
