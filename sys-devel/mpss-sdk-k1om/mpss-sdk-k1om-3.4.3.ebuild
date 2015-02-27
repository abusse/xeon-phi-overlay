# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit rpm

#SRC_URI="http://registrationcenter.intel.com/irc_nas/5017/mpss-3.4.2-linux.tar"
#SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-3.4.3-k1om.tar"
SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-3.4.3-linux.tar"
DESCRIPTION="SDK for Intel Xeon Phi."

LICENSE="GPL-2 public-domain"
SLOT="0"
KEYWORDS="~amd64"

src_unpack () {
	unpack ${A}
	rpm_unpack ./mpss-${PV}/${P}-1.x86_64.rpm
	rm -rf ./mpss-${PV}
}

src_install () {
	cp -r * ${D}

	doenvd ${FILESDIR}/36mpss-skd-k1om-${PV} || die
}
