#!/bin/bash
# check.sh

ubuntu_dist_raw="$1"
shift

set -eu

base_dir=$(cd $(dirname $0) && pwd)
. $base_dir/pkg/_common/functions.sh

usage()
{
	local status=$1
	echo "usage: $0 UBUNTU-RELEASE DEB_FILE ..."
	exit $status
}

case "$ubuntu_dist_raw" in
	''|*.deb)  usage 1 ;;
	-h|--help) usage 0 ;;
esac

set_ubuntu_dist "$ubuntu_dist_raw"

test $# -ne 0 || usage 1

declare -a all_deb_file_list

for arg in "$@"
do
	case "$arg" in
		*.deb)
		if [ -f "$arg" ]
		then
			all_deb_file_list+=($arg)
		else
			error "$arg: package file not found"
		fi
		;;

		*)
		error "$arg: invalid argument"
		;;
	esac
done

get_deb_source_name()
{
	local info=$(dpkg-deb --info "$1")
	local name=$(sed -n 's/^ *Source: *// p' <<< $info)
	test -n "$name" || name=$(sed -n 's/^ *Package: *// p' <<< $info)
	test -n "$name" || error 'get_deb_source_name() failed'
	echo "$name"
}

declare -A source_name_set deb_to_source_name_map

for deb in "${all_deb_file_list[@]}"
do
	source_name=$(get_deb_source_name "$deb")
	source_name_set[$source_name]=1
	deb_to_source_name_map[$deb]=$source_name
done

# Additional XtraDeb PPA for the can-install check
include_xtradeb_ppa=

for source_name in "${!source_name_set[@]}"
do
	unset deb_file_list
	declare -a deb_file_list

	for deb in "${all_deb_file_list[@]}"
	do
		if [ "_${deb_to_source_name_map[$deb]}" = "_$source_name" ]
		then
			deb_file_list+=("$deb")
		fi
	done

	echo "Source package: $source_name"

	resource_name=$(get_resource_name $source_name)
	script=$base_dir/pkg/$resource_name/script.sh

	(test ! -f $script || . $script; xd_check "${deb_file_list[@]}")

	echo ' '
done

# end check.sh
