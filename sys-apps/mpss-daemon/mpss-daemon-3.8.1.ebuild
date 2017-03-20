# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils intel-mpss

DESCRIPTION="Daemon for starting/stopping Xeon Phi coprocessors"
HOMEPAGE="http://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI=${MPSS_SRC_SRC_URI}

SLOT="0"
KEYWORDS="~amd64"

IUSE="+firmware +modules"

PATCHES=(
	"${FILESDIR}/${P}.patch"
)

DEPEND="=sys-libs/mpss-headers-${PV}
        =sys-libs/libscif-${PV}"
RDEPEND="${DEPEND}
	modules? ( =sys-kernel/mpss-modules-${PV} )
	firmware? ( =sys-kernel/mic-image-${PV} )
	=sys-apps/mpss-micmgmt-${PV}"

src_unpack() {
    unpack ${A}
    unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_install() {
    emake DESTDIR="${D}" install

    doenvd ${FILESDIR}/90mpssd || die
    doinitd ${FILESDIR}/mpss || die
}
