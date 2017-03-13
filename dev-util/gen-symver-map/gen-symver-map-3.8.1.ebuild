# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit intel-mpss

DESCRIPTION="Utility for generating maps of symbols (System.map)"
HOMEPAGE="https://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI=${MPSS_SRC_SRC_URI}

SLOT="0"
KEYWORDS="~amd64"

src_unpack() {
    unpack ${A}
    unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_install() {
    mkdir -p ${D}/usr/bin
    cp ${WORKDIR}/${P}/${PN} ${D}/usr/bin
}
