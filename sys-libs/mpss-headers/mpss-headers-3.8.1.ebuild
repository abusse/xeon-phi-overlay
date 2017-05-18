# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit intel-mpss

DESCRIPTION="Header files for MPSS Stack"
HOMEPAGE="https://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/mpss-modules-${PV}.tar.bz2
	mv mpss-modules-${PV} ${P}
}

src_compile() {
	true;
}

src_install() {
		emake DESTDIR="${D}" dev_install || die "Failed to install headers."
}
