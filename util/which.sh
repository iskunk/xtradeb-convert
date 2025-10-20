#!/bin/sh
# which.sh
#
# Script to identify which conversion script (under pkg/) should be used
# for a given source package. The output is the basename of the script,
# without the .sh filename extension.
#

package=$1
version=$2

top=$(cd $(dirname $0)/.. && pwd)

script_name=$package

case "$package" in
	firefox-esr) script_name=firefox ;;
	llvm-toolchain-*) script_name=llvm-toolchain ;;
	rustc-[1-9].[0-9]*) script_name=rustc ;;
	ungoogled-chromium) script_name=chromium ;;
	wxwidgets[3-9].*) script_name=wxwidgets ;;

	firefox)
	case "$version" in
		*~mt[1-9]) script_name=firefox-mt ;;
		'')
		echo 'error: version must be specified for firefox package' >&2
		exit 1
		;;
	esac
	;;

	node-cjs-module-lexer | node-undici | pkg-js-tools)
	script_name=nodejs
	;;
esac

test -f $top/pkg/$script_name.sh || script_name=generic

echo $script_name

exit 0

# end which.sh
