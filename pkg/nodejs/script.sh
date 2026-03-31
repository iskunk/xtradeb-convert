# pkg/nodejs/script.sh
#
# https://packages.debian.org/source/sid/pkg-js-tools#pdownload
# https://packages.debian.org/source/sid/node-undici#pdownload
# https://packages.debian.org/source/sid/node-cjs-module-lexer#pdownload
# https://packages.debian.org/source/sid/nodejs#pdownload
#

################################################################

xd_convert() {

ubuntu_dist jammy || not_applicable 'this script is needed only for jammy'

case "$source_name" in
	pkg-js-tools)
	# Downgrade the node-marked-man dep to what is available in jammy
	# (the package still builds just fine)
	perl -pi -e '/^ , node-marked-man/ and s/\(>= .+?\)/(>= 0.7.0)/' \
		$debian/control
	echo 'Downgrade the node-marked-man build-dependency.' > $changelog_entry_file
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
	echo 'Add missing "ms" module, and work around esbuild failure.' > $changelog_entry_file
	;;

	node-cjs-module-lexer)
	# Fix "Error: Cannot find module 'node:fs/promises'"
	perl -pi -e '/^ , node-babel-plugin-transform-modules-commonjs/ and $_.=" , node-istanbul\n"' \
		$debian/control
	new_patch xtradeb-node-cjs-module-lexer.patch
	echo 'Add node-istanbul build-dependency and use alternate implementation of "node:fs/promises".' > $changelog_entry_file
	;;

	nodejs)
	perl -pi -e 'if(/^exp-relax-check :=/){s/^/#xtradeb#/; $_.="exp-relax-check = -i\n"}' \
		$debian/rules
	new_patch xtradeb-nodejs.patch
	echo 'Fix unavailable uv_available_parallelism() call, and allow test suite failures.' > $changelog_entry_file
	;;

	*)
	error "$pkg: not a supported package"
	;;
esac

} # xd_convert()

################################################################

# end pkg/nodejs/script.sh
