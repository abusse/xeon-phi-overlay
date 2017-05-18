# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit intel-mpss python-r1

DESCRIPTION="Automatically generates a version script from macro annotations in the code."
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="dev-python/configparser"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_prepare() {
	# The script is written for Python v2
	sed -i -e 's/\(#!\/usr\/bin\/env python\)/\12/g' ${WORKDIR}/${P}/${PN}

	eapply_user
}

src_install() {
	mkdir -p ${D}/usr/bin
	cp ${WORKDIR}/${P}/${PN} ${D}/usr/bin
}
