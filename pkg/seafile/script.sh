# pkg/seafile/script.sh
#
# https://packages.debian.org/source/sid/seafile#pdownload
# https://packages.ubuntu.com/source/seafile
#

################################################################

xd_convert() {

if ubuntu_dist jammy
then
	# Downgrade a couple of build dependencies
	sed -ri \
		-e '/^\s+dpkg-dev / s/\(>= .+\)/(>= 1.21.1)/' \
		-e '/^\s+libwebsockets-dev / s/\(>= .+\)/(>= 4.0.20)/' \
		$debian/control
fi

if ubuntu_dist jammy noble
then
	# Not the only questionable item from lintian on these releases,
	# but only this one is a hard error
	cat > $debian/libseafile0t64.lintian-overrides << END
# seemingly spurious diagnostic
library-not-linked-against-libc [usr/lib/*/libseafile.so.*]
END
fi

} # xd_convert()

################################################################

# end pkg/seafile/script.sh
