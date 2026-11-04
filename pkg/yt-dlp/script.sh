# pkg/yt-dlp/script.sh
#
# https://packages.debian.org/source/sid/yt-dlp#pdownload
# https://packages.ubuntu.com/source/yt-dlp
#

################################################################

xd_convert() {

if ubuntu_dist jammy
then
	# Need to use Python 3.11, not the default 3.10
	sed -ri 's/^(\s+python3)(,?)$/\1.11\2/' $debian/control
	#
	cat > $debian/xtradeb.tmp << 'END'

export PYTHON = python3.11
export PYBUILD_INTERPRETERS = $(PYTHON)
END
	(cd $debian && sed -i '/^export PYBUILD_NAME/ r xtradeb.tmp' rules)
	rm $debian/xtradeb.tmp

	sed -ri 's/\b(PYTHON)=python3$/\1=$(PYTHON)/' $debian/rules

	# A bug in the python3-py package breaks pytest:
	#
	#   make offlinetest PYTHON=python3.11
	#   make[2]: Entering directory '...'
	#   python3.11 -m pytest -m "not download"
	#   Traceback (most recent call last):
	#     File "/usr/lib/python3/dist-packages/py/_vendored_packages/apipkg/__init__.py", line 145, in __makeattr
	#       modpath, attrname = self.__map__[name]
	#                           ~~~~~~~~~~~~^^^^^^
	#   KeyError: '__spec__'
	#
	sed -ri 's/^(\s+)(make offlinetest)/\1-\2/' $debian/rules
fi

if ubuntu_dist jammy noble
then
	# Downgrade these dependencies
	sed -ri \
		-e '/^\s+python3-hatchling / s/>= .+\)/>= 0.15.0)/' \
		-e '/^\s+python3-pytest / s/>= .+\)/>= 6.2.5)/' \
		$debian/control
fi

##
## Patch series modifications
##

if ubuntu_dist jammy noble
then
	new_patch 0101-fix-hatchling-license.patch
fi

if ubuntu_dist jammy
then
	new_patch 0102-fix-urllib3-six.patch
fi

if ubuntu_dist jammy noble
then
	new_patch 0103-pytest-compat.patch
fi

} # xd_convert()

################################################################

# end pkg/yt-dlp/script.sh
