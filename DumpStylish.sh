#!/bin/bash

usage() { echo "Usage: $0 [-i InputStylish.sqlite] [-o OutputStylishDirectory]" 1>&2; exit 1; }

while getopts ":i:o:h:" a; do
	case "${a}" in
		i)
			i=${OPTARG}
			;;
		o)
			o=${OPTARG}
			;;
		h)
			usage
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "${i}" ] || [ -z "${o}" ] || [ -e "${o}" ] && [ -f "${o}" ] || [ ! -f "${i}" ] || !(file -ib ${i} | grep -Fxq "application/x-sqlite3; charset=binary") ; then
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
done

