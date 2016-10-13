#!/bin/bash

usage() { 
	echo "Usage: $0 [-v {0-3}] [-q] [-h] -i InputStylish.sqlite -o OutputDirectory" 1>&2; 
	exit 1; 
}

usageHelp() {
	echo "Usage: $0 [-v {0-3}] [-q] [-h] -i InputStylish.sqlite -o OutputDirectory" 1>&2;
	echo -e "\t-i\t[InputStylish.sqlite]\tSelect the stylish.sqlite file to dump\n" 1>&2;
	echo -e "\t-o\t[OutputDirectory]\tSelect the output directory to dump the contents, if directory doesn't exist it will be made\n" 1>&2;	
	echo -e "\t-v\t[verbose level 0-3]" 1>&2;
	echo -e "\t\t0\t quiet (no) output" 1>&2;
	echo -e "\t\t1\t normal level of output" 1>&2;
	echo -e "\t\t2\t a bit more information" 1>&2;
	echo -e "\t\t3\t a ton of information\n" 1>&2;
	echo -e "\t-q\tQuiet (no) output (same as -v 0)\n" 1>&2;
	echo -e "\t-h\tDisplay help" 1>&2;
	exit 1;
}

v="1"

while getopts ":i:o:h :v: :q " a; do
	case "${a}" in
		i)
			i=${OPTARG}
			;;
		o)
			o=${OPTARG}
			;;
		v)
			v=${OPTARG}
			;;
		q)
			v="0"
			;;
		h)
			usageHelp
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "${i}" ] || [ -z "${o}" ] || [ -e "${o}" ] && [ -f "${o}" ] || [ ! -f "${i}" ] || !(file -ib ${i} | grep -Fxq "application/x-sqlite3; charset=binary") ||  ! [[ "$v" =~ ^-?[0-9]*$ ]] || [ "$v" -lt 0 ] || [ "$v" -gt 3 ] ; then
	usage
fi

mkdir -p "${o}"

sqlite3 "${i}" "SELECT id FROM styles" | while read id; do
	name="$(sqlite3 "${i}" "SELECT name FROM styles WHERE id=${id}")"

	mkdir -p "${o}/${name}"

	echo "${id}" > "${o}/${name}/.styles"

	url="$(sqlite3 "${i}" "SELECT url FROM styles WHERE id=${id}")"
	echo "${url}" >> "${o}/${name}/.styles"

	updateUrl="$(sqlite3 "${i}" "SELECT updateUrl FROM styles WHERE id=${id}")"
	echo "${updateUrl}" >> "${o}/${name}/.styles"

	md5Url="$(sqlite3 "${i}" "SELECT md5Url FROM styles WHERE id=${id}")"
	echo "${md5Url}" >> "${o}/${name}/.styles"

	echo "${name}" >> "${o}/${name}/.styles"

	enabled="$(sqlite3 "${i}" "SELECT enabled FROM styles WHERE id=${id}")"
	echo "${enabled}" >> "${o}/${name}/.styles"

	originalCode="$(sqlite3 "${i}" "SELECT originalCode FROM styles WHERE id=${id}")"
	echo "${originalCode}" >> "${o}/${name}/.styles"

	idUrl="$(sqlite3 "${i}" "SELECT idUrl FROM styles WHERE id=${id}")"
	echo "${idUrl}" >> "${o}/${name}/.styles"

	applyBackgroundUpdates="$(sqlite3 "${i}" "SELECT applyBackgroundUpdates FROM styles WHERE id=${id}")"
	echo "${applyBackgroundUpdates}" >> "${o}/${name}/.styles"

	originalMd5="$(sqlite3 "${i}" "SELECT originalMd5 FROM styles WHERE id=${id}")"
	echo "${originalMd5}" >> "${o}/${name}/.styles"

	code="$(sqlite3 "${i}" "SELECT code FROM styles WHERE id=${id}")"
	echo "${code}" > "${o}/${name}/${name}.css"

	style_meta_id="$(sqlite3 "${i}" "SELECT id FROM style_meta WHERE style_id=${id}")"
	echo "${style_meta_id}" > "${o}/${name}/.style_meta"

	echo "${id}" >> "${o}/${name}/.style_meta"

	style_meta_name="$(sqlite3 "${i}" "SELECT name FROM style_meta WHERE style_id=${id}")"
	echo "${style_meta_name}" >> "${o}/${name}/.style_meta"

	style_meta_value="$(sqlite3 "${i}" "SELECT value FROM style_meta WHERE style_id=${id}")"
	echo "${style_meta_value}" >> "${o}/${name}/.style_meta"

	if [ "$v" -ge 1 ] ; then
		echo -n "Exported $name"
		if [ "$v" -ge 2 ] ; then
			echo -n " to ${o}/${name}"
			if [ "$v" -ge 3 ] ; then
				echo -n -e "\n\t${o}/${name}/.styles"
				echo -n -e "\n\t\t${id}"
				echo -n -e "\n\t\t${url}"
				echo -n -e "\n\t\t${updateUrl}"
				echo -n -e "\n\t\t${md5Url}"
				echo -n -e "\n\t\t${name}"
				echo -n -e "\n\t\t${enabled}"
				echo -n -e "\n\t\t${originalCode}"
				echo -n -e "\n\t\t${idUrl}"
				echo -n -e "\n\t\t${applyBackgroundUpdates}"
				echo -n -e "\n\t\t${originalMd5}"
				echo -n -e "\n\t${o}/${name}/${name}.css"
				echo -n -e "\n\t${o}/${name}/.style_meta"
				echo -n -e "\n\t\t${style_meta_id}"
				echo -n -e "\n\t\t${id}"
				echo -n -e "\n\t\t${style_meta_name}"
				echo -n -e "\n\t\t${style_meta_value}"
			fi
		fi
		echo ""
	fi
done

