# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit intel-mpss

DESCRIPTION="SCIF library for Intel MIC co-processors"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="app-text/asciidoc"
DEPEND="=dev-util/gen-symver-map-${PV} =sys-libs/mpss-headers-${PV}"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
	cp mpss-metadata-${PV}/* ${P}
}
