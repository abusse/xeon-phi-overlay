# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit intel-mpss

DESCRIPTION="Intel Xeon Phi Compiler Offload Infrastructure (COI)"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="LGPL-2.1
		 BSD
		 tutorials? ( Intel-Sample-Code )"
SLOT="0"
KEYWORDS="~amd64"
IUSE="tutorials"

RDEPEND="=sys-libs/libscif-${PV}"
DEPEND="${RDEPEND} app-text/asciidoc app-doc/doxygen"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2

	mv mpss-metadata-${PV}/* ${P}
}

src_prepare() {
	if ! use tutorials ; then
		sed -i '/tutorials/d' "${S}/Makefile"
	fi

	eapply_user
}

src_compile() {
	emake MPSS_METADATA_C="mpss-metadata.c"
}
