# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

XPPSL_VER=${PV#*_p}

if [[ ${XPPSL_VER} =~ ^[0-9]+$ ]]; then
	XPPSL_VER=${XPPSL_VER:0:1}.${XPPSL_VER:1:1}.${XPPSL_VER:2:1}
fi

case ${XPPSL_VER} in
        2.3.0)
		XPPSL_SRC_URI="https://downloadmirror.intel.com/27477/eng/xpps-2.3.0-rhel7.tar";
		XPPSL_HOMPAGE="https://software.intel.com/en-us/articles/xeon-phi-software"
		;;
	1.5.4)
		XPPSL_SRC_URI="https://downloadmirror.intel.com/27406/eng/xppsl-1.5.4-centos7.3.tar";
		XPPSL_HOMPAGE="https://software.intel.com/en-us/articles/xeon-phi-software"
		;;
	1.5.1)
		XPPSL_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11291/xppsl-1.5.1-centos7.3.tar";
		XPPSL_HOMPAGE="https://software.intel.com/en-us/articles/xeon-phi-software"
		;;
	*)
		die "No SRC_URI for XPPSL version ${XPPSL_VER}!"
esac
