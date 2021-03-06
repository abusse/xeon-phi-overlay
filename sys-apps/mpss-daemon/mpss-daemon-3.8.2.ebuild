# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils intel-mpss

DESCRIPTION="Intel MPSS Management Daemon"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+firmware +modules ssh1"

PATCHES=(
	"${FILESDIR}/${P}.patch"
	"${FILESDIR}/passwd-array-fix.patch"
)

DEPEND="=sys-libs/mpss-headers-${PV}
		=sys-libs/libscif-${PV}"
RDEPEND="${DEPEND}
	modules? ( =sys-kernel/mpss-modules-${PV} )
	firmware? ( =sys-kernel/mic-image-${PV} )
	=sys-apps/mpss-micmgmt-${PV}
	ssh1? ( net-misc/openssh[ssh1] )"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_prepare() {
	default

	use ssh1 || epatch "${FILESDIR}/no-ssh1.patch"
}

src_install() {
	emake DESTDIR="${D}" install

	doenvd "${FILESDIR}/90mpssd" || die
	doinitd "${FILESDIR}/mpss" || die
}
