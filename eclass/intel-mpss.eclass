# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

case ${PV} in
	3.5)
		MPSS_LINUX_SRC_URI="http://registrationcenter.intel.com/irc_nas/7445/mpss-3.5-linux.tar";
		MPSS_K1OM_SRC_URI="http://registrationcenter.intel.com/irc_nas/7445/mpss-3.5-k1om.tar";
		MPSS_SRC_SRC_URI="http://registrationcenter.intel.com/irc_nas/7445/mpss-src-3.5.tar";
		;;
	3.8.1)
		MPSS_LINUX_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss-3.8.1-linux.tar";
		MPSS_K1OM_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss-3.8.1-k1om.tar";
		MPSS_SRC_SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss-src-3.8.1.tar";
		;;
	*)
		die "No SRC_URI for version ${PV}"
esac
