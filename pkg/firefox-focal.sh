#!/bin/bash
# firefox-focal.sh
#
# This script operates on the debian/ subdirectory of an
# Ubuntu 20.04 (focal) firefox source package, as available from
# https://launchpad.net/ubuntu/focal/+source/firefox#files
#

debian="$1"
ubuntu_dist="$2"

base_dir=$(dirname $0)
. $base_dir/_common/functions.sh

initialize firefox --multi-dist

# Need cdbs to regenerate the control file
dpkg --status cdbs >/dev/null \
|| error '"cdbs" package is required to regenerate files'

grep -Fqx 'Source: firefox' $debian/control 2>/dev/null \
|| error "$debian: not a firefox source package debian/ subdirectory"

head -n 1 $debian/changelog 2>/dev/null | grep -q '.-0ubuntu0\.20\.04\.' \
|| error "$debian: not an Ubuntu 20.04 (focal) firefox source package debian/ subdirectory"

################################################################

# https://wiki.mozilla.org/Distribution_INI_File

# Add Ubuntu and XtraDeb bookmarks
cat >>$debian/distribution.ini <<END

[BookmarksToolbar]
item.1.description=Ubuntu website
item.1.title=Ubuntu
item.1.link=https://www.ubuntu.com
item.1.icon=https://www.ubuntu.com/favicon.ico
item.1.iconData=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACSklEQVQ4jX1TXWhSYRj+ZMxRN7vpZuwiRrBREchgxS6CQXTn1EULyWiFdIQQRCu6yI0Yg4KUJIOhNCSiusqLbmSMLroQ2WgRw5Oxc456NHeOOmPqMX/W4ekm/46uF76bl/d53p/n+QhRRImLjWf9Djdvm9xmZ1UyO6uSedvkdtbvcJe42LiyvisKQZedMQzWWC1Bv8cYBmuFoMveA6RpWv3z0aWNo4CslqDOx9BIMw1Wp5IzzsvrNE2rWwSi59arLoBOhZzHitLGW5Q/vYewNIc6t4NGhgOrU4HVEmT9DjchhBBpd0vD6lRyE5yyTkNcMaGyuY5m1PkYhKU5JG+e6mwil5mvZ4jopXzNZPzaCVS/b6KeoBE3jiB5ewKJ66PIeayQpSL+HOTB3znXIskFHj4hSfMY10wUXi8DAPKrD3pukHVRAAAp/LGVS1omYoTVEvx69xTybwl7Tj3qfAzx+eEeAu7KcRRDARwEX7ZV0Q80CKMfaBTWFiFLRaTtMzjMpsAZ1H2VSNsugrdoOkiPVUh8YTTdWmFtEQCw59T3gu0zAIBiKNC9gvjM9KZ1xPlh1H58QTUaQdw4gsSNk+AMagjLRjQyHA73M11KCF7LKqlEw1OdncQVE7IuCuXPH9oycjsQHl9F0nxaIeO3s4QQQoTnCwHlyPkXNhRDARRDAaTunkc1GkE1Gmk38lK+lhMZhhlK37sQ+Z+V/60ms1qC9P3pcJeVmyT9JlE+0Uv5GIYZOvJHVqLhKdFL+ToNljSPcaKX8km7Wxpl/V9ZLTo82gQ36wAAAABJRU5ErkJggg==
item.2.description=XtraDeb website
item.2.title=XtraDeb
item.2.link=https://xtradeb.net
item.2.icon=https://xtradeb.net/favicon.ico
item.2.iconData=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACkUlEQVQ4jY2TX2jNYRjHP8/7vme//TlYOgodMhobWtyQuxOZ3Yhku3Eh1ERKSlyQCFdEiIiliIZyoYgVm1JbQtr2syQzjSaMcHZ2/vze93Ux/yLyvXl6+n6/z/P0rQf+A5dBA3RCVTd0hND+BCoBzB/ienT9O0TaiNILqQ0CtjpPWa6IlmfXSIyB+Rr4CJuAzX8MaLiC/dHEWG0CFuNg2DK5qJST6Qw5BS4HHQDyq9nvZrwrY5kzdEaPidkBrirFZ+v5II6kGk//xy5aC4MUEtU8ibdwwXgQUmhpI7Kl7NIlbFAWqOKI66XWlvAq3sJgZj1zcewsn0iDSTLWRpSl63j/4wJ/jKpomC5ThNgCfdqzRLbx/DsfHWKp3sKtoRSrYiU0KUFyjlBlapmUraNx+BFzlSbEoJ3joGzjuW8kBpA+zhwf8VmEfPwuZ/OeDuvBCk3KCeeUYpPtY130hmZXYIiI+x6EU0SdZayxl7iYbWO2/5ZZzHDeCrvG3OSwAaoLjoeiqPBphryngB0R7gHZWElKvaPaaaYJeA/SfZ1BB28BlHM0GkGrgDOmghodUE7AHAE/U5BxlWxnKqdVwAKfwgh4YIOGoz0w/WeIJ5gaDRGaGLGoQGjy1MkOBgBeTKE4UUUoir3hDZ6WQ4uCeA7aFSAelGykVzzNxNBmNDW2mGMhxPuTlFT0kZU8+3yeA3HN1QDiHvDQZEbqCHSenVYo1oZMrp92C9e/vKK4G1723mHGlHkkEtUMvO+h1Vru10DTvx6oqAsevgX/GnwIfmAGbdl60pkVPM3UMh9A/W70IK0pTAPkDez/BD2foD+C5tIkb0hi9Sy0C5j+1+2/4h6MegATdoPKLGJldi23/SmWf+e/AvzuCKinXVlBAAAAAElFTkSuQmCC
END

cat >$debian/xtradeb.tmp <<'END'

# Enable native Wayland support (https://launchpad.net/bugs/1916469)
# only in Wayland sessions (https://launchpad.net/bugs/1923116)
if [ "_$XDG_SESSION_TYPE" = "_wayland" ] ; then
    export MOZ_ENABLE_WAYLAND=1
fi
END
(cd $debian && \
	sed -i '/^export MOZ_APP_LAUNCHER/ r xtradeb.tmp' firefox.sh.in)
rm -f $debian/xtradeb.tmp

################################################################
##
## Modifications to allow building on Ubuntu jammy and later
##
################################################################

# Note: Modify "control.in", not "control". The latter will be regenerated
# after changes to the former are complete.

# Bump up debhelper compat level to 10 (quells warnings)
sed -i -r '/^\s+debhelper \(>= 9\),/s/9/10/' $debian/control.in

# Also needed for debhelper
echo 10 >$debian/compat

# rustc-1.80 is not available in plucky, use 1.84
if ubuntu_dist plucky
then
	sed -i -r 's/\b(cargo|rustc)-1.80,/\1-1.84,/' $debian/control.in
	sed -i -r '/^RUSTC_VERSIONS =/s/1.80/1.84/' $debian/build/rules.mk
fi

# Depend on the regular nodejs package instead of nodejs-mozilla. (Note
# that on jammy, a backported version of nodejs is needed)
perl -pi -e 's/\b(nodejs)-mozilla\b/$1/;' \
	$debian/control.in
perl -pi -e '/\bNODEJS=/ and s/^/#xtradeb#/' \
	$debian/config/mozconfig.in

##
## Patch series modifications
##

# (none at present)

################################################################

finish

# Add a "1:" epoch prefix to the version (so that the firefox snap package
# isn't outright considered newer), and remove the Ubuntu release part
perl -pi \
	-e 'if (/^firefox / && $. == 1) {' \
	-e '  s/\((.+)\)/(1:$1)/;' \
	-e '  s/0ubuntu0\.20\.04\.//;' \
	-e '}' \
	$debian/changelog

# Regenerate control file
ln -s . $debian/debian || exit
(unset MAKEFLAGS; cd $debian && set -x && debian/rules debian/control) \
|| error 'failed to regenerate debianization files'
rm $debian/debian

echo "Firefox package conversion for Ubuntu $ubuntu_ver/$ubuntu_dist complete."

# end firefox-focal.sh
