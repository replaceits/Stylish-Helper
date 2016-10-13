#!/bin/bash
#
# A simple shell script that is used to dump the stylish.sqlite database from
# the broswer plugin Stylish. This will let you edit the CSS files in your own
# editor/IDE and be able to more easily share/copy your styles than it currently
# is through the plugin.
#
# Created by replaceits

#########################
# Display basic usage
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   1
#########################
usage() { 
	echo "Usage: $0 [-v {0-3}] [-q] [-h] -i InputStylish.sqlite -o OutputDirectory" 1>&2; 
	exit 1; 
}

##############################################
# Display an extended version of the usage
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   1
##############################################
usageHelp() {
	echo "Usage: $0 [-v {0-3}] [-q] [-h] -i InputStylish.sqlite -o OutputDirectory" 1>&2;
	echo -e "\t-i\t[InputStylish.sqlite]\tSelect the stylish.sqlite file to dump\n" 1>&2;
	echo -e "\t-o\t[OutputDirectory]\tSelect the output directory to dump the contents, if the directory doesn't exist it will be made\n" 1>&2;
	echo -e "\t-v\t[verbose level 0-3]" 1>&2;
	echo -e "\t\t0\t quiet (no) output" 1>&2;
	echo -e "\t\t1\t normal level of output" 1>&2;
	echo -e "\t\t2\t a bit more information" 1>&2;
	echo -e "\t\t3\t a ton of information\n" 1>&2;
	echo -e "\t-q\tQuiet (no) output (same as -v 0)\n" 1>&2;
	echo -e "\t-h\tDisplay help" 1>&2;
	exit 1;
}

###################################################
# Display an error with a line number and exit.
# Globals:
#   None
# Arguments:
#   line_number
#	error_message
# Returns:
#   1
###################################################
errorExit() {
	echo "Error (line ${1:-"Unknown line"}): ${2:-"Unknown error"}" 1>&2
	exit 1;
}

# Initialize the 'v' variable which will be used to determine the level of 
# verbosity that the program will output. This can be set between (or equal to)
# 0 through 3 with '0' being no output and '3' being the most output.
v="1"

# Loop through command line options/arguments. Assign arguments to their variables
# however we don't parse them yet until we pass this block. If an unknown argument
# is passed we will display the usage guide. Options '-i' and '-o' are required to
# be set and passed with an argument. Options '-h', '-v', and '-q' are all optional.
# The option '-v' requires an integer argument between (or equal to) 0 through 3.
# If option '-q' is passed it will take precedent over '-v'.
while getopts ":i:o:h :v: :q " a; do
	case "${a}" in
		# The variable 'i' will be used as the location for the stylish.sqlite
		# database. Must be a properly formatted sqlite3 database.
		i)
			i=${OPTARG}
			;;
		# The variable 'o' will be used as the location to output the dumped
		# stylish.sqlite database. Must be a directory.
		o)
			o=${OPTARG}
			;;
		# The argument of option '-v' will set the variable 'v' to the desired
		# level of verbosity. If the verbosity is already set to '0' (as is set
		# by the '-q' option) then we will level the variable as-is to ensure
		# that the '-q' option takes precedent.
		v)
			if [ "${v}" -ne 0 ] ; then
				v=${OPTARG}
			fi
			;;
		# The '-q' option will set the 'v' variable to '0'. This will cause the
		# program to output nothing (or as little as possible). This option will
		# take precedent over the '-v' option if it was set.
		q)
			v="0"
			;;
		# When the '-h' option is passed we will display the extended usage help
		# guide and exit the program regardless of what other options were passed.
		h)
			usageHelp
			;;
		# TODO(replaceits): Output an error stating the option is invalid/unknown.
		#
		# Any unknown option passed will cause us to display the usage guide and
		# exit the program regardless of what other options were passed.
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

# TODO(replaceits): Output an error showing the invalid options/arguments.
#
# Check to make sure the options/arguments passed to the program are correct.
# First we need to make sure that both the arguments passed to '-i' and '-o'
# are not empty strings. Next if the output directory already exists make sure
# it is not actually a file instead of a directory. Check the input database 
# and determine if it is an actual sqlite3 database or not. Finally we check
# if the '-v' argument is an integer and that its between (or equal to) 0 through 3.
if [ -z "${i}" ] || [ -z "${o}" ] \
	|| [ -e "${o}" ] && [ -f "${o}" ] \
	|| [ ! -f "${i}" ] \
	|| !(file -ib ${i} | grep -Fxq "application/x-sqlite3; charset=binary") \
	||  ! [[ "$v" =~ ^-?[0-9]*$ ]] || [ "$v" -lt 0 ] || [ "$v" -gt 3 ] ; then
	usage
fi

# Check and make sure that the tables 'styles' and 'style_meta' both
# exist inside the database. If they don't we will exit with an error.
if [ -z "$(sqlite3 ${i} "SELECT name FROM sqlite_master WHERE type='table' AND name='style_meta';")" ] ; then
	errorExit $LINENO "The style_meta table doesn't exist"
elif [ -z "$(sqlite3 ${i} "SELECT name FROM sqlite_master WHERE type='table' AND name='styles';")" ] ; then
	errorExit $LINENO "The 'styles' table doesn't exist"
fi

# Counter used to determine the amount of columns within a table
counter=0

# Arrays that store how the tables should be setup in the database
styles_info=(
	"0|id|INTEGER|1||1"
	"1|url|TEXT|0||0"
	"2|updateUrl|TEXT|0||0"
	"3|md5Url|TEXT|0||0"
	"4|name|TEXT|1||0"
	"5|code|TEXT|1||0"
	"6|enabled|INTEGER|1||0"
	"7|originalCode|TEXT|0||0"
	"8|idUrl|TEXT|0||0"
	"9|applyBackgroundUpdates|INTEGER|1|1|0"
	"10|originalMd5|TEXT|0||0"
)

style_meta_info=(
	"0|id|INTEGER|1||1"
	"1|style_id|INTEGER|1||0"
	"2|name|TEXT|1||0"
	"3|value|TEXT|1||0"
)

# Loop through the info of columns and compare them to how they should be setup.
# If we find a row that doesn't match or if there are more or less columns then 
# there should be then we will exit with an error. We do this for both tables.
sqlite3 "${i}" "PRAGMA table_info(styles);" | (while read column; do
	if [ "${column}" != "${styles_info[${counter}]}" ] ; then
		errorExit $LINENO "Improperly formatted 'styles' table: column '${column}' is not valid"
	fi
	(( counter += 1 ))
done

if [ "${counter}" -ne 11 ] ; then
	errorExit $LINENO "Improperly formatted 'styles' table: invalid number of columns"
fi)

counter=0

sqlite3 "${i}" "PRAGMA table_info(style_meta);" | (while read column; do
	if [ "${column}" != "${style_meta_info[${counter}]}" ] ; then
		errorExit $LINENO "Improperly formatted 'style_meta' table: column '${column}' is not valid"
	fi
	(( counter += 1 ))
done

if [ "${counter}" -ne 4 ] ; then
	errorExit $LINENO "Improperly formatted 'style_meta' table: invalid number of columns"
fi)

#Create the output directory if it doesn't exist
mkdir -p "${o}"

#Loop through styles in the inputed database
sqlite3 "${i}" "SELECT id FROM styles" | while read id; do
	name="$(sqlite3 "${i}" "SELECT name FROM styles WHERE id=${id}")"

	# Make a directory in the output directory with the name of ${name} which
	# we will use to store all of the current styles data from the database.
	mkdir -p "${o}/${name}"

	# Ouput the contentes of the 'styles' table to '.styles'.
	echo "${id}" > "${o}/${name}/.styles"

	url="$(sqlite3 "${i}" "SELECT url FROM styles WHERE id=${id}")" \
		&& echo "${url}" >> "${o}/${name}/.styles"

	updateUrl="$(sqlite3 "${i}" "SELECT updateUrl FROM styles WHERE id=${id}")" \
		&& echo "${updateUrl}" >> "${o}/${name}/.styles"

	md5Url="$(sqlite3 "${i}" "SELECT md5Url FROM styles WHERE id=${id}")" \
		&& echo "${md5Url}" >> "${o}/${name}/.styles"

	echo "${name}" >> "${o}/${name}/.styles"

	enabled="$(sqlite3 "${i}" "SELECT enabled FROM styles WHERE id=${id}")" \
		&& echo "${enabled}" >> "${o}/${name}/.styles"

	originalCode="$(sqlite3 "${i}" "SELECT originalCode FROM styles WHERE id=${id}")" \
		&& echo "${originalCode}" >> "${o}/${name}/.styles"

	idUrl="$(sqlite3 "${i}" "SELECT idUrl FROM styles WHERE id=${id}")" \
		&& echo "${idUrl}" >> "${o}/${name}/.styles"

	applyBackgroundUpdates="$(sqlite3 "${i}" "SELECT applyBackgroundUpdates FROM styles WHERE id=${id}")" \
		&& echo "${applyBackgroundUpdates}" >> "${o}/${name}/.styles"

	originalMd5="$(sqlite3 "${i}" "SELECT originalMd5 FROM styles WHERE id=${id}")" \
		&& echo "${originalMd5}" >> "${o}/${name}/.styles"

	# Output the CSS code to '${name}.css'.
	code="$(sqlite3 "${i}" "SELECT code FROM styles WHERE id=${id}")" \
		&& echo "${code}" > "${o}/${name}/${name}.css"

	# Output the contents of the 'style_meta' table to '.style_meta'.
	style_meta_id="$(sqlite3 "${i}" "SELECT id FROM style_meta WHERE style_id=${id}")" \
		&& echo "${style_meta_id}" > "${o}/${name}/.style_meta"

	echo "${id}" >> "${o}/${name}/.style_meta"

	style_meta_name="$(sqlite3 "${i}" "SELECT name FROM style_meta WHERE style_id=${id}")" \
		&& echo "${style_meta_name}" >> "${o}/${name}/.style_meta"

	style_meta_value="$(sqlite3 "${i}" "SELECT value FROM style_meta WHERE style_id=${id}")" \
		&& echo "${style_meta_value}" >> "${o}/${name}/.style_meta"

	# Output information about what has been done depending on the level of 
	# verbosity. A level of '3' will display all the data thats been exported
	# excluding the CSS files.
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

exit 0
