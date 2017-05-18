# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MPSS_VER=${PV#*_p}

if [[ ${MPSS_VER} =~ ^[0-9]+$ ]]; then
	MPSS_VER=${MPSS_VER:0:1}.${MPSS_VER:1:1}.${MPSS_VER:2:1}
fi

case ${MPSS_VER} in
	3.8.1)
		MPSS_URI="https://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss";
		MPSS_LINUX_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss-3.8.1-linux.tar";
		MPSS_K1OM_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss-3.8.1-k1om.tar";
		MPSS_SRC_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss-src-3.8.1.tar";
		;;
        3.8.2)
		MPSS_URI="https://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss";
              	MPSS_LINUX_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11518/mpss-3.8.2-linux.tar";
                MPSS_K1OM_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11518/mpss-3.8.2-k1om.tar";
                MPSS_SRC_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11518/mpss-src-3.8.2.tar";
                ;;
	*)
		die "No SRC_URI for MPSS version ${MPSS_VER}!"
esac
