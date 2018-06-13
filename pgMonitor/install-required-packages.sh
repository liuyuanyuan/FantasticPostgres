#!/usr/bin/env bash

export PATH="${PATH}:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
export LC_ALL=C

# Be nice on production environments
renice 19 $$ >/dev/null 2>/dev/null

ME="${0}"

if [ "${BASH_VERSINFO[0]}" -lt "4" ]
then
	echo >&2 "Sorry! This script needs BASH version 4+, but you have BASH version ${BASH_VERSION}"
	exit 1
fi

# These options control which packages we are going to install
# They can be pre-set, but also can be controlled with command line options
PACKAGES_NETDATA=${PACKAGES_NETDATA-0}
PACKAGES_NETDATA_NODEJS=${PACKAGES_NETDATA_NODEJS-0}
PACKAGES_NETDATA_PYTHON=${PACKAGES_NETDATA_PYTHON-0}
PACKAGES_NETDATA_PYTHON3=${PACKAGES_NETDATA_PYTHON3-0}
PACKAGES_NETDATA_PYTHON_MYSQL=${PACKAGES_NETDATA_PYTHON_MYSQL-0}
PACKAGES_NETDATA_PYTHON_POSTGRES=${PACKAGES_NETDATA_PYTHON_POSTGRES-0}
PACKAGES_DEBUG=${PACKAGES_DEBUG-0}
PACKAGES_IPRANGE=${PACKAGES_IPRANGE-0}
PACKAGES_FIREHOL=${PACKAGES_FIREHOL-0}
PACKAGES_FIREQOS=${PACKAGES_FIREQOS-0}
PACKAGES_UPDATE_IPSETS=${PACKAGES_UPDATE_IPSETS-0}
PACKAGES_NETDATA_DEMO_SITE=${PACKAGES_NETDATA_DEMO_SITE-0}
PACKAGES_NETDATA_SENSORS=${PACKAGES_NETDATA_SENSORS-0}

# needed commands
lsb_release=$(which lsb_release 2>/dev/null || command -v lsb_release 2>/dev/null)

# Check which package managers are available
apk=$(which apk 2>/dev/null || command -v apk 2>/dev/null)
apt_get=$(which apt-get 2>/dev/null || command -v apt-get 2>/dev/null)
dnf=$(which dnf 2>/dev/null || command -v dnf 2>/dev/null)
emerge=$(which emerge 2>/dev/null || command -v emerge 2>/dev/null)
equo=$(which equo 2>/dev/null || command -v equo 2>/dev/null)
pacman=$(which pacman 2>/dev/null || command -v pacman 2>/dev/null)
yum=$(which yum 2>/dev/null || command -v yum 2>/dev/null)
zypper=$(which zypper 2>/dev/null || command -v zypper 2>/dev/null)

distribution=
version=
codename=
package_installer=
tree=
detection=
NAME=
ID=
ID_LIKE=
VERSION=
VERSION_ID=

usage() {
	cat <<EOF
OPTIONS:

${ME} [--dont-wait] [--non-interactive] \\
  [distribution DD [version VV] [codename CN]] [installer IN] [packages]

Supported distributions (DD):

    - arch           (all Arch Linux derivatives)
    - centos         (all CentOS derivatives)
    - gentoo         (all Gentoo Linux derivatives)
    - sabayon        (all Sabayon Linux derivatives)
    - debian, ubuntu (all Debian and Ubuntu derivatives)
    - redhat, fedora (all Red Hat and Fedora derivatives)
    - suse, opensuse (all SuSe and openSuSe derivatives)

Supported installers (IN):

    - apt-get        all Debian / Ubuntu Linux derivatives
    - dnf            newer Red Hat / Fedora Linux
    - emerge         all Gentoo Linux derivatives
    - equo           all Sabayon Linux derivatives
    - pacman         all Arch Linux derivatives
    - yum            all Red Hat / Fedora / CentOS Linux derivatives
    - zypper         all SuSe Linux derivatives
    - apk            all Alpine derivatives

Supported packages (you can append many of them):

    - netdata-all    all packages required to install netdata
                     including mysql client, postgres client,
                     node.js, python, sensors, etc

    - netdata        minimum packages required to install netdata
                     (no mysql client, no nodejs, includes python)

    - nodejs         install nodejs
                     (required for monitoring named and SNMP)

    - python         install python
                     (including python-yaml, for config files parsing)

    - python3        install python3
                     (including python3-yaml, for config files parsing)

    - python-mysql   install MySQLdb
                     (for monitoring mysql, will install python3 version
                     if python3 is enabled or detected)

    - python-postgres install psycopg2
                     (for monitoring postgres, will install python3 version
                     if python3 is enabled or detected)

    - sensors        install lm_sensors for monitoring h/w sensors

    - firehol-all    packages required for FireHOL, FireQoS, update-ipsets
    - firehol        packages required for FireHOL
    - fireqos        packages required for FireQoS
    - update-ipsets  packages required for update-ipsets

    - demo           packages required for running a netdata demo site
                     (includes nginx and various debugging tools)


If you don't supply the --dont-wait option, the program
will ask you before touching your system.

EOF
}

release2lsb_release() {
	# loads the given /etc/x-release file
	# this file is normaly a single line containing something like
	#
	# X Linux release 1.2.3 (release-name)
	#
	# It attempts to parse it
	# If it succeeds, it returns 0
	# otherwise it returns 1

	local file="${1}" x DISTRIB_ID= DISTRIB_RELEASE= DISTRIB_CODENAME= DISTRIB_DESCRIPTION=
	echo >&2 "Loading ${file} ..."


	x="$(cat "${file}" | grep -v "^$" | head -n 1)"

	if [[ "${x}" =~ ^.*[[:space:]]+Linux[[:space:]]+release[[:space:]]+.*[[:space:]]+(.*)[[:space:]]*$ ]]
		then
		eval "$(echo "${x}" | sed "s|^\(.*\)[[:space:]]\+Linux[[:space:]]\+release[[:space:]]\+\(.*\)[[:space:]]\+(\(.*\))[[:space:]]*$|DISTRIB_ID=\"\1\"\nDISTRIB_RELEASE=\"\2\"\nDISTRIB_CODENAME=\"\3\"|g" | grep "^DISTRIB")"
	elif [[ "${x}" =~ ^.*[[:space:]]+Linux[[:space:]]+release[[:space:]]+.*[[:space:]]+$ ]]
		then
		eval "$(echo "${x}" | sed "s|^\(.*\)[[:space:]]\+Linux[[:space:]]\+release[[:space:]]\+\(.*\)[[:space:]]*$|DISTRIB_ID=\"\1\"\nDISTRIB_RELEASE=\"\2\"|g" | grep "^DISTRIB")"
	elif [[ "${x}" =~ ^.*[[:space:]]+release[[:space:]]+.*[[:space:]]+(.*)[[:space:]]*$ ]]
		then
		eval "$(echo "${x}" | sed "s|^\(.*\)[[:space:]]\+release[[:space:]]\+\(.*\)[[:space:]]\+(\(.*\))[[:space:]]*$|DISTRIB_ID=\"\1\"\nDISTRIB_RELEASE=\"\2\"\nDISTRIB_CODENAME=\"\3\"|g" | grep "^DISTRIB")"
	elif [[ "${x}" =~ ^.*[[:space:]]+release[[:space:]]+.*[[:space:]]+$ ]]
		then
		eval "$(echo "${x}" | sed "s|^\(.*\)[[:space:]]\+release[[:space:]]\+\(.*\)[[:space:]]*$|DISTRIB_ID=\"\1\"\nDISTRIB_RELEASE=\"\2\"|g" | grep "^DISTRIB")"
	fi

	distribution="${DISTRIB_ID}"
	version="${DISTRIB_RELEASE}"
	codename="${DISTRIB_CODENAME}"

	[ -z "${distribution}" ] && echo >&2 "Cannot parse this lsb-release: ${x}" && return 1
	detection="${file}"
	return 0
}

get_os_release() {
	# Loads the /etc/os-release file
	# Only the required fields are loaded
	#
	# If it manages to load /etc/os-release, it returns 0
	# otherwise it returns 1
	#
	# It searches the ID_LIKE field for a compatible distribution

	local x
	if [ -f "/etc/os-release" ]
		then
		echo >&2 "Loading /etc/os-release ..."

		eval "$(cat /etc/os-release | grep -E "^(NAME|ID|ID_LIKE|VERSION|VERSION_ID)=")"
		for x in "${ID}" ${ID_LIKE}
		do
			case "${x,,}" in
				alpine|arch|centos|debian|fedora|gentoo|sabayon|rhel|ubuntu|suse|sles)
					distribution="${x}"
					version="${VERSION_ID}"
					codename="${VERSION}"
					detection="/etc/os-release"
					break
					;;
				*)
					echo >&2 "Unknown distribution ID: ${x}"
					;;
			esac
		done
		[ -z "${distribution}" ] && echo >&2 "Cannot find valid distribution in: ${ID} ${ID_LIKE}" && return 1
	else
		echo >&2 "Cannot find /etc/os-release" && return 1
	fi

	[ -z "${distribution}" ] && return 1
	return 0
}

get_lsb_release() {
	# Loads the /etc/lsb-release file
	# If it fails, it attempts to run the command: lsb_release -a
	# and parse its output
	#
	# If it manages to find the lsb-release, it returns 0
	# otherwise it returns 1

	if [ -f "/etc/lsb-release" ]
	then
		echo >&2 "Loading /etc/lsb-release ..."
		local DISTRIB_ID= ISTRIB_RELEASE= DISTRIB_CODENAME= DISTRIB_DESCRIPTION=
		eval "$(cat /etc/lsb-release | grep -E "^(DISTRIB_ID|DISTRIB_RELEASE|DISTRIB_CODENAME)=")"
		distribution="${DISTRIB_ID}"
		version="${DISTRIB_RELEASE}"
		codename="${DISTRIB_CODENAME}"
		detection="/etc/lsb-release"
	fi

	if [ -z "${distribution}" -a ! -z "${lsb_release}" ]
		then
		echo >&2 "Cannot find distribution with /etc/lsb-release"
		echo >&2 "Running command: lsb_release ..."
		eval "declare -A release=( $(lsb_release -a 2>/dev/null | sed -e "s|^\(.*\):[[:space:]]*\(.*\)$|[\1]=\"\2\"|g") )"
		distribution="${release[Distributor ID]}"
		version="${release[Release]}"
		codename="${release[Codename]}"
		detection="lsb_release"
	fi

	[ -z "${distribution}" ] && echo >&2 "Cannot find valid distribution with lsb-release" && return 1
	return 0
}

find_etc_any_release() {
	# Check for any of the known /etc/x-release files
	# If it finds one, it loads it and returns 0
	# otherwise it returns 1

	if [ -f "/etc/arch-release" ]
		then
		release2lsb_release "/etc/arch-release" && return 0
	fi

	if [ -f "/etc/centos-release" ]
		then
		release2lsb_release "/etc/centos-release" && return 0
	fi

	if [ -f "/etc/redhat-release" ]
		then
		release2lsb_release "/etc/redhat-release" && return 0
	fi

	if [ -f "/etc/SuSe-release" ]
		then
		release2lsb_release "/etc/SuSe-release" && return 0
	fi

	return 1
}

autodetect_distribution() {
	# autodetection of distribution
	get_os_release || get_lsb_release || find_etc_any_release
}

user_picks_distribution() {
	# let the user pick a distribution

	echo >&2
	echo >&2 "I NEED YOUR HELP"
	echo >&2 "It seems I cannot detect your system automatically."
	if [ -z "${equo}" -a -z "${emerge}" -a -z "${apt_get}" -a -z "${yum}" -a -z "${dnf}" -a -z "${pacman}" -a -z "${apk}" ]
		then
		echo >&2 "And it seems I cannot find a known package manager in this system."
		echo >&2 "Please open a github issue to help us support your system too."
		exit 1
	fi

	local opts=
	echo >&2 "I found though that the following installers are available:"
	echo >&2
	[ ! -z "${apt_get}" ] && echo >&2 " - Debian/Ubuntu based (installer is: apt-get)" && opts="${opts} apt-get"
	[ ! -z "${yum}"     ] && echo >&2 " - Redhat/Fedora/Centos based (installer is: yum)" && opts="${opts} yum"
	[ ! -z "${dnf}"     ] && echo >&2 " - Redhat/Fedora/Centos based (installer is: dnf)" && opts="${opts} dnf"
	[ ! -z "${zypper}"  ] && echo >&2 " - SuSe based (installer is: zypper)" && opts="${opts} zypper"
	[ ! -z "${pacman}"  ] && echo >&2 " - Arch Linux based (installer is: pacman)" && opts="${opts} pacman"
	[ ! -z "${emerge}"  ] && echo >&2 " - Gentoo based (installer is: emerge)" && opts="${opts} emerge"
	[ ! -z "${equo}"    ] && echo >&2 " - Sabayon based (installer is: equo)" && opts="${opts} equo"
	[ ! -z "${apk}"     ] && echo >&2 " - Alpine Linux based (installer is: apk)" && opts="${opts} apk"
	echo >&2

	REPLY=
	while [ -z "${REPLY}" ]
	do
		read -p "To proceed please write one of these:${opts}: "
		[ $? -ne 0 ] && continue

		if [ "${REPLY}" = "yum" -a -z "${distribution}" ]
			then
			REPLY=
			while [ -z "${REPLY}" ]
				do
				read -p "yum in centos, rhel or fedora? > "
				[ $? -ne 0 ] && continue

				case "${REPLY,,}" in
					fedora|rhel)
						distribution="rhel"
						;;
					centos)
						distribution="centos"
						;;
					*)
						echo >&2 "Please enter 'centos', 'fedora' or 'rhel'."
						REPLY=
						;;
				esac
			done
			REPLY="yum"
		fi
		check_package_manager "${REPLY}" || REPLY=
	done
}

detect_package_manager_from_distribution() {
	case "${1,,}" in
		arch*|manjaro*)
			package_installer="install_pacman"
			tree="arch"
			if [ ${IGNORE_INSTALLED} -eq 0 -a -z "${pacman}" ]
				then
				echo >&2 "command 'pacman' is required to install packages on a '${distribution} ${version}' system."
				exit 1
			fi
			;;

		sabayon*)
			package_installer="install_equo"
			tree="sabayon"
			if [ ${IGNORE_INSTALLED} -eq 0 -a -z "${equo}" ]
				then
				echo >&2 "command 'equo' is required to install packages on a '${distribution} ${version}' system."
				# Maybe offer to fall back on emerge? Both installers exist in Sabayon...
				exit 1
			fi
			;;

		alpine*)
			package_installer="install_apk"
			tree="alpine"
			if [ ${IGNORE_INSTALLED} -eq 0 -a -z "${apk}" ]
				then
				echo >&2 "command 'apk' is required to install packages on a '${distribution} ${version}' system."
				exit 1
			fi
			;;

		gentoo*)
			package_installer="install_emerge"
			tree="gentoo"
			if [ ${IGNORE_INSTALLED} -eq 0 -a -z "${emerge}" ]
				then
				echo >&2 "command 'emerge' is required to install packages on a '${distribution} ${version}' system."
				exit 1
			fi
			;;

		debian*|ubuntu*)
			package_installer="install_apt_get"
			tree="debian"
			if [ ${IGNORE_INSTALLED} -eq 0 -a -z "${apt_get}" ]
				then
				echo >&2 "command 'apt-get' is required to install packages on a '${distribution} ${version}' system."
				exit 1
			fi
			;;

		centos*|clearos*)
			echo >&2 "You should have EPEL enabled to install all the prerequisites."
			echo >&2 "Check: http://www.tecmint.com/how-to-enable-epel-repository-for-rhel-centos-6-5/"
			package_installer="install_yum"
			tree="centos"
			if [ ${IGNORE_INSTALLED} -eq 0 -a -z "${yum}" ]
				then
				echo >&2 "command 'yum' is required to install packages on a '${distribution} ${version}' system."
				exit 1
			fi
			;;

		fedora*|redhat*|red\ hat*|rhel*)
			package_installer=
			tree="rhel"
			[ ! -z "${yum}" ] && package_installer="install_yum"
			[ ! -z "${dnf}" ] && package_installer="install_dnf"
			if [ ${IGNORE_INSTALLED} -eq 0 -a -z "${package_installer}" ]
				then
				echo >&2 "command 'yum' or 'dnf' is required to install packages on a '${distribution} ${version}' system."
				exit 1
			fi
			;;

		suse*|opensuse*|sles*)
			package_installer="install_zypper"
			tree="suse"
			if [ ${IGNORE_INSTALLED} -eq 0 -a -z "${zypper}" ]
				then
				echo >&2 "command 'zypper' is required to install packages on a '${distribution} ${version}' system."
				exit 1
			fi
			;;

		*)
			# oops! unknown system
			user_picks_distribution
			;;
	esac
}

check_package_manager() {
	# This is called only when the user is selecting a package manager
	# It is used to verify the user selection is right

	echo >&2 "Checking package manager: ${1}"

	case "${1}" in
		apt-get)
			[ ${IGNORE_INSTALLED} -eq 0 -a -z "${apt_get}" ] && echo >&2 "${1} is not available." && return 1
			package_installer="install_apt_get"
			tree="debian"
			detection="user-input"
			return 0
			;;

		dnf)
			[ ${IGNORE_INSTALLED} -eq 0 -a -z "${dnf}" ] && echo >&2 "${1} is not available." && return 1
			package_installer="install_dnf"
			tree="rhel"
			detection="user-input"
			return 0
			;;

		apk)
			[ ${IGNORE_INSTALLED} -eq 0 -a -z "${apk}" ] && echo >&2 "${1} is not available." && return 1
			package_installer="install_apk"
			tree="alpine"
			detection="user-input"
			return 0
			;;

		equo)
			[ ${IGNORE_INSTALLED} -eq 0 -a -z "${equo}" ] && echo >&2 "${1} is not available." && return 1
			package_installer="install_equo"
			tree="sabayon"
			detection="user-input"
			return 0
			;;

		emerge)
			[ ${IGNORE_INSTALLED} -eq 0 -a -z "${emerge}" ] && echo >&2 "${1} is not available." && return 1
			package_installer="install_emerge"
			tree="gentoo"
			detection="user-input"
			return 0
			;;

		pacman)
			[ ${IGNORE_INSTALLED} -eq 0 -a -z "${pacman}" ] && echo >&2 "${1} is not available." && return 1
			package_installer="install_pacman"
			tree="arch"
			detection="user-input"
			return 0
			;;

		zypper)
			[ ${IGNORE_INSTALLED} -eq 0 -a -z "${zypper}" ] && echo >&2 "${1} is not available." && return 1
			package_installer="install_zypper"
			tree="suse"
			detection="user-input"
			return 0
			;;

		yum)
			[ ${IGNORE_INSTALLED} -eq 0 -a -z "${yum}" ] && echo >&2 "${1} is not available." && return 1
			package_installer="install_yum"
			if [ "${distribution}" = "centos" ]
				then
				tree="centos"
			else
				tree="rhel"
			fi
			detection="user-input"
			return 0
			;;

		*)
			echo >&2 "Invalid package manager: '${1}'."
			return 1
			;;
	esac
}

require_cmd() {
	# check if any of the commands given as argument
	# are present on this system
	# If any of them is available, it returns 0
	# otherwise 1

	[ ${IGNORE_INSTALLED} -eq 1 ] && return 1

	local wanted found
	for wanted in "${@}"
	do
		found="$(which "${wanted}" 2>/dev/null)"
		[ -z "${found}" ] && found="$(command -v "${wanted}" 2>/dev/null)"
		[ ! -z "${found}" -a -x "${found}" ] && return 0
	done

	return 1
}

declare -A pkg_distro_sdk=(
	 ['alpine']="alpine-sdk"
	['default']="NOTREQUIRED"
	)

declare -A pkg_autoconf=(
	 ['gentoo']="sys-devel/autoconf"
	['default']="autoconf"
	)

# required to compile netdata with --enable-sse
# https://github.com/firehol/netdata/pull/450
declare -A pkg_autoconf_archive=(
	 ['gentoo']="sys-devel/autoconf-archive"
	 ['alpine']="WARNING|"
	['default']="autoconf-archive"

	# exceptions
       ['centos-6']="WARNING|"
       ['centos-7']="WARNING|"
         ['rhel-6']="WARNING|"
         ['rhel-7']="WARNING|"
	)

declare -A pkg_autogen=(
	 ['gentoo']="sys-devel/autogen"
	 ['alpine']="WARNING|"
	['default']="autogen"

	# exceptions
       ['centos-6']="WARNING|"
         ['rhel-6']="WARNING|"
	)

declare -A pkg_automake=(
	 ['gentoo']="sys-devel/automake"
	['default']="automake"
	)

declare -A pkg_bridge_utils=(
	 ['gentoo']="net-misc/bridge-utils"
	['default']="bridge-utils"
	)

declare -A pkg_chrony=(
	['default']="chrony"
	)

declare -A pkg_curl=(
	 ['gentoo']="net-misc/curl"
	['sabayon']="net-misc/curl"
	['default']="curl"
	)

declare -A pkg_git=(
	 ['gentoo']="dev-vcs/git"
	['default']="git"
	)

declare -A pkg_gcc=(
	 ['gentoo']="sys-devel/gcc"
	['default']="gcc"
	)

declare -A pkg_gdb=(
	 ['gentoo']="sys-devel/gdb"
	['default']="gdb"
	)

declare -A pkg_iotop=(
	['default']="iotop"
	)

declare -A pkg_iproute2=(
	 ['alpine']="iproute2"
	 ['debian']="iproute2"
	 ['gentoo']="sys-apps/iproute2"
	['sabayon']="sys-apps/iproute2"
	['default']="iproute"

	# exceptions
	['ubuntu-12.04']="iproute"
	)

declare -A pkg_ipset=(
	 ['gentoo']="net-firewall/ipset"
	['default']="ipset"
	)

declare -A pkg_jq=(
	 ['gentoo']="app-misc/jq"
	['default']="jq"
	)

declare -A pkg_iptables=(
	 ['gentoo']="net-firewall/iptables"
	['default']="iptables"
	)

declare -A pkg_libz_dev=(
	 ['alpine']="zlib-dev"
	   ['arch']="zlib"
	 ['centos']="zlib-devel"
	 ['debian']="zlib1g-dev"
	 ['gentoo']="sys-libs/zlib"
	['sabayon']="sys-libs/zlib"
	   ['rhel']="zlib-devel"
	   ['suse']="zlib-devel"
	['default']=""
	)

declare -A pkg_libuuid_dev=(
	 ['alpine']="util-linux-dev"
	   ['arch']="util-linux"
	 ['centos']="libuuid-devel"
	 ['debian']="uuid-dev"
	 ['gentoo']="sys-apps/util-linux"
	['sabayon']="sys-apps/util-linux"
	   ['rhel']="libuuid-devel"
	   ['suse']="libuuid-devel"
	['default']=""
	)

declare -A pkg_libmnl_dev=(
	 ['alpine']="libmnl-dev"
	   ['arch']="libmnl"
	 ['centos']="libmnl-devel"
	 ['debian']="libmnl-dev"
	 ['gentoo']="net-libs/libmnl"
	['sabayon']="net-libs/libmnl"
	   ['rhel']="libmnl-devel"
	   ['suse']="libmnl0"
	['default']=""
	)

declare -A pkg_lm_sensors=(
     ['alpine']="lm_sensors"
	   ['arch']="lm_sensors"
	 ['centos']="lm_sensors"
	 ['debian']="lm-sensors"
	 ['gentoo']="sys-apps/lm_sensors"
	['sabayon']="sys-apps/lm_sensors"
	   ['rhel']="lm_sensors"
	   ['suse']="sensors"
	['default']="lm_sensors"
	)

declare -A pkg_logwatch=(
	['default']="logwatch"
	)

declare -A pkg_lxc=(
	['default']="lxc"
	)

declare -A pkg_mailutils=(
	['default']="mailutils"
	)

declare -A pkg_make=(
	 ['gentoo']="sys-devel/make"
	['default']="make"
	)

declare -A pkg_netcat=(
	 ['alpine']="netcat-openbsd"
	   ['arch']="netcat"
	 ['centos']="nmap-ncat"
	 ['debian']="netcat"
	 ['gentoo']="net-analyzer/netcat"
	['sabayon']="net-analyzer/gnu-netcat"
	   ['rhel']="nmap-ncat"
	   ['suse']="netcat-openbsd"
	['default']="netcat"

	# exceptions
     ['centos-6']="nc"
       ['rhel-6']="nc"
	)

declare -A pkg_nginx=(
	 ['gentoo']="www-servers/nginx"
	['default']="nginx"
	)

declare -A pkg_nodejs=(
	 ['gentoo']="net-libs/nodejs"
	['default']="nodejs"

	# exceptions
	  ['rhel-6']="WARNING|To install nodejs check: https://nodejs.org/en/download/package-manager/"
	  ['rhel-7']="WARNING|To install nodejs check: https://nodejs.org/en/download/package-manager/"
	['centos-6']="WARNING|To install nodejs check: https://nodejs.org/en/download/package-manager/"
	['debian-6']="WARNING|To install nodejs check: https://nodejs.org/en/download/package-manager/"
	['debian-7']="WARNING|To install nodejs check: https://nodejs.org/en/download/package-manager/"
	)

declare -A pkg_postfix=(
	['default']="postfix"
	)

declare -A pkg_pkg_config=(
	 ['alpine']="pkgconfig"
	   ['arch']="pkgconfig"
	 ['centos']="pkgconfig"
	 ['debian']="pkg-config"
	 ['gentoo']="dev-util/pkgconfig"
	['sabayon']="virtual/pkgconfig"
	   ['rhel']="pkgconfig"
	   ['suse']="pkg-config"
	['default']="pkg-config"
	)

declare -A pkg_python=(
	 ['gentoo']="dev-lang/python"
	['sabayon']="dev-lang/python:2.7"
	['default']="python"
	)

declare -A pkg_python_mysqldb=(
	 ['alpine']="py-mysqldb"
	   ['arch']="mysql-python"
	 ['centos']="MySQL-python"
	 ['debian']="python-mysqldb"
	 ['gentoo']="dev-python/mysqlclient"
	['sabayon']="dev-python/mysqlclient"
	   ['rhel']="MySQL-python"
	   ['suse']="python-PyMySQL"
	['default']="python-mysql"

	# exceptions
  ['fedora-24']="python2-mysql"
	)

declare -A pkg_python3_mysqldb=(
	 ['alpine']="WARNING|"
	   ['arch']="WARNING|"
	 ['centos']="WARNING|"
	 ['debian']="python3-mysqldb"
	 ['gentoo']="dev-python/mysqlclient"
	['sabayon']="dev-python/mysqlclient"
	   ['rhel']="WARNING|"
	   ['suse']="WARNING|"
	['default']="WARNING|"

	# exceptions
	['debian-6']="WARNING|"
	['debian-7']="WARNING|"
	['debian-8']="WARNING|"
   ['ubuntu-12.04']="WARNING|"
   ['ubuntu-12.10']="WARNING|"
   ['ubuntu-13.04']="WARNING|"
   ['ubuntu-13.10']="WARNING|"
   ['ubuntu-14.04']="WARNING|"
   ['ubuntu-14.10']="WARNING|"
   ['ubuntu-15.04']="WARNING|"
   ['ubuntu-15.10']="WARNING|"
	)

declare -A pkg_python_psycopg2=(
	 ['alpine']="py-psycopg2"
	   ['arch']="python2-psycopg2"
	 ['centos']="python-psycopg2"
	 ['debian']="python-psycopg2"
	 ['gentoo']="dev-python/psycopg"
	['sabayon']="dev-python/psycopg:2"
	   ['rhel']="python-psycopg2"
	   ['suse']="python-psycopg2"
	['default']="python-psycopg2"
	)

declare -A pkg_python3_psycopg2=(
	 ['alpine']="py3-psycopg2"
	   ['arch']="python-psycopg2"
	 ['centos']="WARNING|"
	 ['debian']="WARNING|"
	 ['gentoo']="dev-python/psycopg"
	['sabayon']="dev-python/psycopg:2"
	   ['rhel']="WARNING|"
	   ['suse']="WARNING|"
	['default']="WARNING|"
	)

declare -A pkg_python_pip=(
	 ['alpine']="py-pip"
	 ['gentoo']="dev-python/pip"
	['sabayon']="dev-python/pip"
	['default']="python-pip"
	)

declare -A pkg_python3_pip=(
	 ['alpine']="py3-pip"
	   ['arch']="python-pip"
	 ['centos']="WARNING|"
	 ['gentoo']="dev-python/pip"
	['sabayon']="dev-python/pip"
	   ['rhel']="WARNING|"
	['default']="python3-pip"
	)

declare -A pkg_python_pymongo=(
	 ['alpine']="WARNING|"
	   ['arch']="python2-pymongo"
	 ['centos']="WARNING|"
	 ['debian']="python-pymongo"
	 ['gentoo']="dev-python/pymongo"
	   ['suse']="python-pymongo"
	['default']="python-pymongo"
	)

declare -A pkg_python3_pymongo=(
	 ['alpine']="WARNING|"
	   ['arch']="python-pymongo"
	 ['centos']="WARNING|"
	 ['debian']="python3-pymongo"
	 ['gentoo']="dev-python/pymongo"
	   ['suse']="python3-pymongo"
	['default']="python3-pymongo"
	)

declare -A pkg_python_requests=(
	 ['alpine']="py-requests"
	   ['arch']="python2-requests"
	 ['centos']="python-requests"
	 ['debian']="python-requests"
	 ['gentoo']="dev-python/requests"
	['sabayon']="dev-python/requests"
	   ['rhel']="python-requests"
	   ['suse']="python-requests"
	['default']="python-requests"

   ['alpine-3.1.4']="WARNING|"
   ['alpine-3.2.3']="WARNING|"
	)

declare -A pkg_python3_requests=(
	 ['alpine']="py3-requests"
	   ['arch']="python-requests"
	 ['centos']="WARNING|"
	 ['debian']="WARNING|"
	 ['gentoo']="dev-python/requests"
	['sabayon']="dev-python/requests"
	   ['rhel']="WARNING|"
	   ['suse']="WARNING|"
	['default']="WARNING|"
	)

declare -A pkg_python_yaml=(
	 ['alpine']="py-yaml"
	   ['arch']="python2-yaml"
	 ['gentoo']="dev-python/pyyaml"
	['sabayon']="dev-python/pyyaml"
	 ['centos']="PyYAML"
	   ['rhel']="PyYAML"
	   ['suse']="python-PyYAML"
	['default']="python-yaml"
	)

declare -A pkg_python3_yaml=(
	 ['alpine']="py3-yaml"
	   ['arch']="python-yaml"
	 ['centos']="python3-PyYAML"
	 ['centos']="WARNING|"
	 ['debian']="python3-yaml"
	 ['gentoo']="dev-python/pyyaml"
	['sabayon']="dev-python/pyyaml"
	   ['rhel']="WARNING|"
	   ['suse']="python3-PyYAML"
	['default']="python3-yaml"
	)

declare -A pkg_python3=(
	 ['gentoo']="dev-lang/python"
	['sabayon']="dev-lang/python:3.4"
	['default']="python3"

	# exceptions
	['centos-6']="WARNING|"
	)

declare -A pkg_screen=(
	 ['gentoo']="app-misc/screen"
	['sabayon']="app-misc/screen"
	['default']="screen"
	)

declare -A pkg_sudo=(
	['default']="sudo"
	)

declare -A pkg_sysstat=(
	['default']="sysstat"
	)

declare -A pkg_tcpdump=(
	 ['gentoo']="net-analyzer/tcpdump"
	['default']="tcpdump"
	)

declare -A pkg_traceroute=(
	 ['alpine']=" "
	 ['gentoo']="net-analyzer/traceroute"
	['default']="traceroute"
	)

declare -A pkg_valgrind=(
	 ['gentoo']="dev-util/valgrind"
	['default']="valgrind"
	)

declare -A pkg_ulogd=(
	 ['centos']="WARNING|"
	   ['rhel']="WARNING|"
	 ['gentoo']="app-admin/ulogd"
	['default']="ulogd2"
	)

declare -A pkg_unzip=(
	 ['gentoo']="app-arch/unzip"
	['default']="unzip"
	)

declare -A pkg_zip=(
	 ['gentoo']="app-arch/zip"
	['default']="zip"
	)

validate_installed_package() {
	validate_${package_installer} "${p}"
}

suitable_package() {
	local package="${1//-/_}" p= v="${version//.*/}"

	# echo >&2 "Searching for ${package}..."

	eval "p=\${pkg_${package}['${distribution,,}-${version,,}']}"
	[ -z "${p}" ] && eval "p=\${pkg_${package}['${distribution,,}-${v,,}']}"
	[ -z "${p}" ] && eval "p=\${pkg_${package}['${distribution,,}']}"
	[ -z "${p}" ] && eval "p=\${pkg_${package}['${tree}-${version}']}"
	[ -z "${p}" ] && eval "p=\${pkg_${package}['${tree}-${v}']}"
	[ -z "${p}" ] && eval "p=\${pkg_${package}['${tree}']}"
	[ -z "${p}" ] && eval "p=\${pkg_${package}['default']}"

	if [[ "${p/|*}" =~ ^(ERROR|WARNING|INFO)$ ]]
		then
		echo >&2 "${p/|*/}"
		echo >&2 "package ${1} is not available in this system."
		if [ -z "${p/*|/}" ]
		then
			echo >&2 "You may try to install without it."
		else
			echo >&2 "${p/*|/}"
		fi
		echo >&2
		return 1
	elif [ "${p}" = "NOTREQUIRED" ]
		then
		return 0
	elif [ -z "${p}" ]
		then
		echo >&2 "WARNING"
		echo >&2 "package ${1} is not availabe in this system."
		echo >&2
		return 1
	else
		if [ ${IGNORE_INSTALLED} -eq 0 ]
			then
			validate_installed_package "${p}"
		else
			echo "${p}"
		fi
		return 0
	fi
}

packages() {
	# detect the packages we need to install on this system

	# -------------------------------------------------------------------------
	# basic build environment

	suitable_package distro-sdk

	require_cmd git          || suitable_package git

	require_cmd gcc          || \
	require_cmd gcc-multilib || suitable_package gcc

	require_cmd make         || suitable_package make
	require_cmd autoconf     || suitable_package autoconf
	suitable_package autoconf-archive
	require_cmd autogen      || suitable_package autogen
	require_cmd automake     || suitable_package automake
	require_cmd pkg-config   || suitable_package pkg-config

	# -------------------------------------------------------------------------
	# debugging tools for development

	if [ ${PACKAGES_DEBUG} -ne 0 ]
		then
		require_cmd traceroute || suitable_package traceroute
		require_cmd tcpdump    || suitable_package tcpdump
		require_cmd screen     || suitable_package screen

		if [ ${PACKAGES_NETDATA} -ne 0 ]
			then
			require_cmd gdb        || suitable_package gdb
			require_cmd valgrind   || suitable_package valgrind
		fi
	fi

	# -------------------------------------------------------------------------
	# common command line tools

	if [ ${PACKAGES_NETDATA} -ne 0 ]
		then
		require_cmd curl || suitable_package curl
		require_cmd nc   || suitable_package netcat
	fi

	# -------------------------------------------------------------------------
	# firehol/fireqos/update-ipsets command line tools

	if [ ${PACKAGES_FIREQOS} -ne 0 ]
		then
		require_cmd ip || suitable_package iproute2
	fi

	if [ ${PACKAGES_FIREHOL} -ne 0 ]
		then
		require_cmd iptables     || suitable_package iptables
		require_cmd ipset        || suitable_package ipset
		require_cmd ulogd ulogd2 || suitable_package ulogd
		require_cmd traceroute   || suitable_package traceroute
		require_cmd bridge       || suitable_package bridge-utils
	fi

	if [ ${PACKAGES_UPDATE_IPSETS} -ne 0 ]
		then
		require_cmd ipset    || suitable_package ipset
		require_cmd zip      || suitable_package zip
		require_cmd funzip   || suitable_package unzip
	fi

	# -------------------------------------------------------------------------
	# netdata libraries

	if [ ${PACKAGES_NETDATA} -ne 0 ]
		then
		suitable_package libz-dev
		suitable_package libuuid-dev
		suitable_package libmnl-dev
	fi

	# -------------------------------------------------------------------------
	# sensors

	if [ ${PACKAGES_NETDATA_SENSORS} -ne 0 ]
		then
		require_cmd sensors || suitable_package lm_sensors
	fi

	# -------------------------------------------------------------------------
	# scripting interpreters for netdata plugins

	if [ ${PACKAGES_NETDATA_NODEJS} -ne 0 ]
		then
		require_cmd nodejs node js || suitable_package nodejs
	fi

	# -------------------------------------------------------------------------
	# python2

	if [ ${PACKAGES_NETDATA_PYTHON} -ne 0 ]
		then
		require_cmd python || suitable_package python

		suitable_package python-yaml
		suitable_package python-pymongo
		# suitable_package python-requests
		# suitable_package python-pip

		[ ${PACKAGES_NETDATA_PYTHON_MYSQL}    -ne 0 ] && suitable_package python-mysqldb
		[ ${PACKAGES_NETDATA_PYTHON_POSTGRES} -ne 0 ] && suitable_package python-psycopg2
	fi

	# -------------------------------------------------------------------------
	# python3

	if [ ${PACKAGES_NETDATA_PYTHON3} -ne 0 ]
		then
		require_cmd python3 || suitable_package python3

		suitable_package python3-yaml
		suitable_package python3-pymongo
		# suitable_package python3-requests
		# suitable_package python3-pip

		[ ${PACKAGES_NETDATA_PYTHON_MYSQL}    -ne 0 ] && suitable_package python3-mysqldb
		[ ${PACKAGES_NETDATA_PYTHON_POSTGRES} -ne 0 ] && suitable_package python3-psycopg2
	fi

	# -------------------------------------------------------------------------
	# applications needed for the netdata demo sites

	if [ ${PACKAGES_NETDATA_DEMO_SITE} -ne 0 ]
		then
		require_cmd sudo       || suitable_package sudo
		require_cmd jq         || suitable_package jq
		require_cmd nginx      || suitable_package nginx
		require_cmd postconf   || suitable_package postfix
		require_cmd lxc-create || suitable_package lxc
		require_cmd logwatch   || suitable_package logwatch
		require_cmd mail       || suitable_package mailutils
		require_cmd iostat     || suitable_package sysstat
		require_cmd iotop      || suitable_package iotop
	fi
}

DRYRUN=0
run() {

	printf >&2 "%q " "${@}"
	printf >&2 "\n"

	if [ ! "${DRYRUN}" -eq 1 ]
		then
		"${@}"
		return $?
	fi
	return 0
}

sudo=
if [ ${UID} -ne 0 ]
	then
	sudo="sudo"
fi

# -----------------------------------------------------------------------------
# debian / ubuntu

validate_install_apt_get() {
	echo >&2 " > Checking if package '${*}' is installed..."
	[ "$(dpkg-query -W --showformat='${Status}\n' "${*}")" = "install ok installed" ] || echo "${*}"
}

install_apt_get() {
	# download the latest package info
	if [ "${DRYRUN}" -eq 1 ]
		then
		echo >&2 " >> IMPORTANT << "
		echo >&2 "    Please make sure your system is up to date"
		echo >&2 "    by running:  ${sudo} apt-get update  "
		echo >&2 
	fi

	local opts=
	if [ ${NON_INTERACTIVE} -eq 1 ]
		then
		# http://serverfault.com/questions/227190/how-do-i-ask-apt-get-to-skip-any-interactive-post-install-configuration-steps
		export DEBIAN_FRONTEND="noninteractive"
		opts="-yq"
	fi

	# install the required packages
	run ${sudo} apt-get ${opts} install "${@}"
}


# -----------------------------------------------------------------------------
# centos / rhel

validate_install_yum() {
	echo >&2 " > Checking if package '${*}' is installed..."
	yum list installed "${*}" >/dev/null 2>&1 || echo "${*}"
}

install_yum() {
	# download the latest package info
	if [ "${DRYRUN}" -eq 1 ]
		then
		echo >&2 " >> IMPORTANT << "
		echo >&2 "    Please make sure your system is up to date"
		echo >&2 "    by running:  ${sudo} yum update  "
		echo >&2 
	fi

	local opts=
	if [ ${NON_INTERACTIVE} -eq 1 ]
		then
		# http://unix.stackexchange.com/questions/87822/does-yum-have-an-equivalent-to-apt-aptitudes-debian-frontend-noninteractive
		opts="-y"
	fi

	# install the required packages
	run ${sudo} yum ${opts} install "${@}" # --enablerepo=epel-testing
}


# -----------------------------------------------------------------------------
# fedora

validate_install_dnf() {
	echo >&2 " > Checking if package '${*}' is installed..."
	dnf list installed "${*}" >/dev/null 2>&1 || echo "${*}"
}

install_dnf() {
	# download the latest package info
	if [ "${DRYRUN}" -eq 1 ]
		then
		echo >&2 " >> IMPORTANT << "
		echo >&2 "    Please make sure your system is up to date"
		echo >&2 "    by running:  ${sudo} dnf update  "
		echo >&2 
	fi

	local opts=
	if [ ${NON_INTERACTIVE} -eq 1 ]
		then
		# man dnf
		opts="-y"
	fi

	# install the required packages
	# --setopt=strict=0 allows dnf to proceed
	# installing whatever is available
	# even if a package is not found
	run ${sudo} dnf ${opts} install "${@}"
}

# -----------------------------------------------------------------------------
# gentoo

validate_install_emerge() {
	echo "${*}"
}

install_emerge() {
	# download the latest package info
	# we don't do this for emerge - it is very slow
	# and most users are expected to do this daily
	# emerge --sync
	if [ "${DRYRUN}" -eq 1 ]
		then
		echo >&2 " >> IMPORTANT << "
		echo >&2 "    Please make sure your system is up to date"
		echo >&2 "    by running:  ${sudo} emerge --sync  or  ${sudo} eix-sync  "
		echo >&2 
	fi

	local opts="--ask"
	if [ ${NON_INTERACTIVE} -eq 1 ]
		then
		opts=""
	fi

	# install the required packages
	run ${sudo} emerge ${opts} -v --noreplace "${@}"
}


# -----------------------------------------------------------------------------
# alpine

validate_install_apk() {
	echo "${*}"
}

install_apk() {
	# download the latest package info
	if [ "${DRYRUN}" -eq 1 ]
		then
		echo >&2 " >> IMPORTANT << "
		echo >&2 "    Please make sure your system is up to date"
		echo >&2 "    by running:  ${sudo} apk update  "
		echo >&2 
	fi

	local opts="-i"
	if [ ${NON_INTERACTIVE} -eq 1 ]
		then
		opts=""
	fi

	# install the required packages
	run ${sudo} apk add ${opts} "${@}"
}

# -----------------------------------------------------------------------------
# sabayon

validate_install_equo() {
	echo >&2 " > Checking if package '${*}' is installed..."
	equo s --installed "${*}" >/dev/null 2>&1 || echo "${*}"
}

install_equo() {
	# download the latest package info
	if [ "${DRYRUN}" -eq 1 ]
		then
		echo >&2 " >> IMPORTANT << "
		echo >&2 "    Please make sure your system is up to date"
		echo >&2 "    by running:  ${sudo} equo up  "
		echo >&2 
	fi

	local opts="-av"
	if [ ${NON_INTERACTIVE} -eq 1 ]
		then
		opts="-v"
	fi

	# install the required packages
	run ${sudo} equo i ${opts} "${@}"
}

# -----------------------------------------------------------------------------
# arch

validate_install_pacman() {
	echo >&2 " > Checking if package '${*}' is installed..."

	local x=$(pacman -Qs "${*}")
	[ ! -n "${x}" ] && echo "${*}"
}

install_pacman() {
	# download the latest package info
	if [ "${DRYRUN}" -eq 1 ]
		then
		echo >&2 " >> IMPORTANT << "
		echo >&2 "    Please make sure your system is up to date"
		echo >&2 "    by running:  ${sudo} pacman -Syu  "
		echo >&2 
	fi

	# install the required packages
	if [ ${NON_INTERACTIVE} -eq 1 ]
		then
		# http://unix.stackexchange.com/questions/52277/pacman-option-to-assume-yes-to-every-question/52278
		yes | run ${sudo} pacman --needed -S "${@}"
	else
		run ${sudo} pacman --needed -S "${@}"
	fi
}

# -----------------------------------------------------------------------------
# suse / opensuse

validate_install_zypper() {
	rpm -q "${*}" >/dev/null 2>&1 || echo "${*}"
}

install_zypper() {
	# download the latest package info
	if [ "${DRYRUN}" -eq 1 ]
		then
		echo >&2 " >> IMPORTANT << "
		echo >&2 "    Please make sure your system is up to date"
		echo >&2 "    by running:  ${sudo} zypper update  "
		echo >&2 
	fi

	local opts=""
	if [ ${NON_INTERACTIVE} -eq 1 ]
		then
		# http://unix.stackexchange.com/questions/82016/how-to-use-zypper-in-bash-scripts-for-someone-coming-from-apt-get
		opts="--non-interactive"
	fi

	# install the required packages
	run ${sudo} zypper ${opts} install "${@}"
}

install_failed() {
	local ret="${1}"
	cat <<EOF



We are very sorry!

Installation of required packages failed.

What to do now:

  1. Make sure your system is updated.
     Most of the times, updating your system will resolve the issue.

  2. If the error message is about a specific package, try removing
     that package from the command and run it again.
     Depending on the broken package, you may be able to continue.

  3. Let us know. We may be able to help.
     Open a github issue with the above log, at:

           https://github.com/firehol/netdata/issues


EOF
	remote_log "FAILED" ${ret}
	exit 1
}

remote_log() {
	# log success or failure on our system
	# to help us solve installation issues
	curl >/dev/null 2>&1 -Ss --max-time 3 "https://registry.my-netdata.io/log/installer?status=${1}&error=${2}&distribution=${distribution}&version=${version}&installer=${package_installer}&tree=${tree}&detection=${detection}&netdata=${PACKAGES_NETDATA}&nodejs=${PACKAGES_NETDATA_NODEJS}&python=${PACKAGES_NETDATA_PYTHON}&python3=${PACKAGES_NETDATA_PYTHON3}&mysql=${PACKAGES_NETDATA_PYTHON_MYSQL}&postgres=${PACKAGES_NETDATA_PYTHON_POSTGRES}&sensors=${PACKAGES_NETDATA_SENSORS}&firehol=${PACKAGES_FIREHOL}&fireqos=${PACKAGES_FIREQOS}&iprange=${PACKAGES_IPRANGE}&update_ipsets=${PACKAGES_UPDATE_IPSETS}&demo=${PACKAGES_NETDATA_DEMO_SITE}"
}

if [ -z "${1}" ]
	then
	usage
	exit 1
fi

# parse command line arguments
DONT_WAIT=0
NON_INTERACTIVE=0
IGNORE_INSTALLED=0
while [ ! -z "${1}" ]
do
	case "${1}" in
		distribution)
			distribution="${2}"
			shift
			;;

		version)
			version="${2}"
			shift
			;;

		codename)
			codename="${2}"
			shift
			;;

		installer)
			check_package_manager "${2}" || exit 1
			shift
			;;

		dont-wait|--dont-wait|-n)
			DONT_WAIT=1
			;;

		non-interactive|--non-interactive|-y)
			NON_INTERACTIVE=1
			;;

		ignore-installed|--ignore-installed|-i)
			IGNORE_INSTALLED=1
			;;

		netdata-all)
			PACKAGES_NETDATA=1
			PACKAGES_NETDATA_NODEJS=1
			PACKAGES_NETDATA_PYTHON=1
			PACKAGES_NETDATA_PYTHON_MYSQL=1
			PACKAGES_NETDATA_PYTHON_POSTGRES=1
			PACKAGES_NETDATA_SENSORS=1
			;;

		netdata)
			PACKAGES_NETDATA=1
			PACKAGES_NETDATA_PYTHON=1
			;;

		python|python-yaml|yaml-python|pyyaml|netdata-python)
			PACKAGES_NETDATA_PYTHON=1
			;;

		python3|python3-yaml|yaml-python3|netdata-python3)
			PACKAGES_NETDATA_PYTHON3=1
			;;

		python-mysql|mysql-python|mysqldb|netdata-mysql)
			PACKAGES_NETDATA_PYTHON=1
			PACKAGES_NETDATA_PYTHON_MYSQL=1
			;;

		python-postgres|postgres-python|psycopg2|netdata-postgres)
			PACKAGES_NETDATA_PYTHON=1
			PACKAGES_NETDATA_PYTHON_POSTGRES=1
			;;

		nodejs|netdata-nodejs)
			PACKAGES_NETDATA=1
			PACKAGES_NETDATA_NODEJS=1
			;;

		sensors|netdata-sensors)
			PACKAGES_NETDATA=1
			PACKAGES_NETDATA_PYTHON=1
			PACKAGES_NETDATA_SENSORS=1
			;;

		firehol|update-ipsets|firehol-all|fireqos)
			PACKAGES_IPRANGE=1
			PACKAGES_FIREHOL=1
			PACKAGES_FIREQOS=1
			PACKAGES_IPRANGE=1
			PACKAGES_UPDATE_IPSETS=1
			;;

		demo|all)
			PACKAGES_NETDATA=1
			PACKAGES_NETDATA_NODEJS=1
			PACKAGES_NETDATA_PYTHON=1
			PACKAGES_NETDATA_PYTHON3=1
			PACKAGES_NETDATA_PYTHON_MYSQL=1
			PACKAGES_NETDATA_PYTHON_POSTGRES=1
			PACKAGES_DEBUG=1
			PACKAGES_IPRANGE=1
			PACKAGES_FIREHOL=1
			PACKAGES_FIREQOS=1
			PACKAGES_UPDATE_IPSETS=1
			PACKAGES_NETDATA_DEMO_SITE=1
			;;

		help|-h|--help)
			usage
			exit 1
			;;

		*)
			echo >&2 "ERROR: Cannot understand option '${1}'"
			echo >&2 
			usage
			exit 1
			;;
	esac
	shift
done

if [ -z "${package_installer}" -o -z "${tree}" ]
	then
	if [ -z "${distribution}" ]
		then
		# we dont know the distribution
		autodetect_distribution || user_picks_distribution
	fi

	detect_package_manager_from_distribution "${distribution}"
fi

pv=$(python --version 2>&1)
if [[ "${pv}" =~ ^Python\ 2.* ]]
then
	pv=2
elif [[ "${pv}" =~ ^Python\ 3.* ]]
then
	pv=3
	PACKAGES_NETDATA_PYTHON3=1
else
	pv=2
fi

[ "${detection}" = "/etc/os-release" ] && cat <<EOF

/etc/os-release information:
NAME            : ${NAME}
VERSION         : ${VERSION}
ID              : ${ID}
ID_LIKE         : ${ID_LIKE}
VERSION_ID      : ${VERSION_ID}
EOF

cat <<EOF

We detected these:
Distribution    : ${distribution}
Version         : ${version}
Codename        : ${codename}
Package Manager : ${package_installer}
Packages Tree   : ${tree}
Detection Method: ${detection}
Default Python v: ${pv} $([ ${pv} -eq 2 -a ${PACKAGES_NETDATA_PYTHON3} -eq 1 ] && echo "(will install python3 too)")

EOF

PACKAGES_TO_INSTALL=( $(packages | sort -u) )

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]
	then
	echo >&2
	echo >&2 "The following command will be run:"
	echo >&2
	DRYRUN=1
	${package_installer} "${PACKAGES_TO_INSTALL[@]}"
	DRYRUN=0
	echo >&2
	echo >&2

	if [ ${DONT_WAIT} -eq 0 -a ${NON_INTERACTIVE} -eq 0 ]
		then
		read -p "Press ENTER to run it > " || exit 1
	fi

	${package_installer} "${PACKAGES_TO_INSTALL[@]}" || install_failed $?

	echo >&2
	echo >&2 "All Done! - Now proceed to the next step."
	echo >&2

else
	echo >&2
	echo >&2 "All required packages are already installed. Now proceed to the next step."
	echo >&2
fi

remote_log "OK"

exit 0
