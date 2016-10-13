#!/bin/bash

usage() { 
	echo "Usage: $0 [-v {0-3}] [-q] [-h] -i InputDirectory -o OutputStylish.sqlite" 1>&2; 
	exit 1; 
}

usageHelp() {
	echo "Usage: $0 [-v {0-3}] [-q] [-h] -i InputDirectory -o OutputStylish.sqlite" 1>&2;
	echo -e "\t-i\t[InputDirectory]\tSelect the directory to repack into the database\n" 1>&2;
	echo -e "\t-o\t[OutputStylish.sqlite]\tSelect the database to output to, if the database doesn't exist it will be made\n" 1>&2;	
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

# Hell if I know why this has to be on its own line to work but it does
if [ -z "${o}" ] || [ -z "${i}" ] ; then
	usage
fi

if [ ! -e "${i}" ] || [ -f "${i}" ] || [ -e "${o}" ] && !(file -ib ${o} | grep -Fxq "application/x-sqlite3; charset=binary") ||  ! [[ "$v" =~ ^-?[0-9]*$ ]] || [ "$v" -lt 0 ] || [ "$v" -gt 3 ] ; then
	usage
fi

if [ ! -e "${o}" ] ; then
	sqlite3 "${o}" "CREATE TABLE styles (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, url TEXT, updateUrl TEXT, md5Url TEXT, name TEXT NOT NULL, code TEXT NOT NULL, enabled INTEGER NOT NULL, originalCode TEXT NULL, idUrl TEXT NULL, applyBackgroundUpdates INTEGER NOT NULL DEFAULT 1, originalMd5 TEXT NULL);"
	sqlite3 "${o}" "CREATE TABLE style_meta (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, style_id INTEGER NOT NULL, name TEXT NOT NULL, value TEXT NOT NULL);"
	sqlite3 "${o}" "CREATE INDEX style_meta_style_id ON style_meta (style_id);"
	if [ "$v" -ge 1 ] ; then
		echo -n "Created database"
		if [ "$v" -ge 2 ] ; then
			echo -n " at ${o}"
			if [ "$v" -ge 3 ] ; then
				echo -n -e "\n${o}"
				echo -n -e "\n\tstyles"
				echo -n -e "\n\t\tid INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"
				echo -n -e "\n\t\turl TEXT"
				echo -n -e "\n\t\tupdateUrl TEXT"
				echo -n -e "\n\t\tmd5Url TEXT"
				echo -n -e "\n\t\tname TEXT NOT NULL"
				echo -n -e "\n\t\tcode TEXT NOT NULL"
				echo -n -e "\n\t\tenabled INTEGER NOT NULL"
				echo -n -e "\n\t\toriginalCode TEXT NULL"
				echo -n -e "\n\t\tidUrl TEXT NULL"
				echo -n -e "\n\t\tapplyBackgroundUpdates INTEGER NOT NULL DEFAULT 1"
				echo -n -e "\n\t\toriginalMd5 TEXT NULL"
				echo -n -e "\n\tstyle_meta"
				echo -n -e "\n\t\tid INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"
				echo -n -e "\n\t\tstyle_id INTEGER NOT NULL"
				echo -n -e "\n\t\tname TEXT NOT NULL"
				echo -n -e "\n\t\tvalue TEXT NOT NULL"
			fi
		fi
		echo ""
	fi
fi

exit 0
