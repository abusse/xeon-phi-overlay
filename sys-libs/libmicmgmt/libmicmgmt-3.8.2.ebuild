# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils intel-mpss

DESCRIPTION="C-library to access and update Intel Xeon Phi Coprocessor parameters"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="app-text/asciidoc"
RDEPEND="=sys-kernel/mic-rasmm-kernel-${PV}"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/mpss-micmgmt-${PV}.tar.bz2
	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
	mv mpss-micmgmt-${PV} ${P}
}

src_compile() {
	emake -I "${WORKDIR}/mpss-metadata-${PV}" lib
}

src_install() {
	emake -I "${WORKDIR}/mpss-metadata-${PV}" DESTDIR="${D}" install_lib
}
