# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils flag-o-matic intel-mpss

DESCRIPTION="Various tools to manage Intel Xeon Phi coprocessors"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="app-text/asciidoc"
RDEPEND="=sys-libs/libmicmgmt-${PV} =sys-firmware/mpss-flash-${PV}"

src_unpack() {
    unpack ${A}
    unpack ./mpss-${PV}/src/${P}.tar.bz2

    unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
}

src_compile() {
    append-cflags -fgnu89-inline
    append-flags -Wno-error=unused-but-set-variable -Wno-error=unused-result
    emake -I ${WORKDIR}/mpss-metadata-${PV} all
}

src_install() {
    emake -I ${WORKDIR}/mpss-metadata-${PV} DESTDIR="${D}" install
}

