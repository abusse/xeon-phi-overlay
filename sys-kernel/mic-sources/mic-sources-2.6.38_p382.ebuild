# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

K_DEBLOB_AVAILABLE="1"
ETYPE="sources"
inherit kernel-2 intel-mpss
detect_version

DESCRIPTION="Full sources of the Linux kernel for the Xeon Phi card"
SRC_URI=${MPSS_SRC_SRC_URI}

KEYWORDS="~amd64"
IUSE="deblob"

src_unpack() {
    unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/linux-${PV%_p*}+mpss${MPSS_VER}.tar.bz2
	mv linux-${PV%_p*}+mpss${MPSS_VER} linux-${PV}-mic
}
