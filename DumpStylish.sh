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

(sqlite3 "${i}" "SELECT id FROM styles" | while read id; do
	sqlite3 "${i}" "SELECT name FROM styles WHERE id=${id}" | while read name; do
		mkdir -p "${o}/${name}"
		echo "${id}" > "${o}/${name}/.styles"
		
		sqlite3 "${i}" "SELECT url FROM styles WHERE id=${id}" | while read url; do
			echo "${url}" >> "${o}/${name}/.styles"
		done
		sqlite3 "${i}" "SELECT updateUrl FROM styles WHERE id=${id}" | while read updateUrl; do
			echo "${updateUrl}" >> "${o}/${name}/.styles"
		done
		sqlite3 "${i}" "SELECT md5Url FROM styles WHERE id=${id}" | while read md5Url; do
			echo "${md5Url}" >> "${o}/${name}/.styles"
		done
		echo "${name}" >> "${o}/${name}/.styles"
		sqlite3 "${i}" "SELECT enabled FROM styles WHERE id=${id}" | while read enabled; do
			echo "${enabled}" >> "${o}/${name}/.styles"
		done
		sqlite3 "${i}" "SELECT originalCode FROM styles WHERE id=${id}" | while read originalCode; do
			echo "${originalCode}" >> "${o}/${name}/.styles"
		done
		sqlite3 "${i}" "SELECT idUrl FROM styles WHERE id=${id}" | while read idUrl; do
            echo "${idUrl}" >> "${o}/${name}/.styles"
        done
		sqlite3 "${i}" "SELECT applyBackgroundUpdates FROM styles WHERE id=${id}" | while read applyBackgroundUpdates; do
            echo "${applyBackgroundUpdates}" >> "${o}/${name}/.styles"
        done
		sqlite3 "${i}" "SELECT originalMd5 FROM styles WHERE id=${id}" | while read originalMd5; do
            echo "${originalMd5}" >> "${o}/${name}/.styles"
        done
		sqlite3 "${i}" "SELECT code FROM styles WHERE id=${id}" | while read code; do
			echo "${code}" >> "${o}/${name}/${name}.css"
		done
	done
done) >> /dev/null

echo "s = ${i}"
echo "p = ${o}"
