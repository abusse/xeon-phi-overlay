# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit toolchain-funcs intel-mpss

DESCRIPTION="Shared Memory Library for MPSS stack"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="LGPL-2.1
		 BSD-2
		 tutorials? ( Intel-Sample-Code )"
SLOT="0"
KEYWORDS="~amd64"
IUSE="tutorials"

RDEPEND="=sys-libs/libscif-${PV}"
DEPEND="${RDEPEND} app-text/asciidoc"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_prepare() {
	if ! use tutorials ; then
		sed -i 's/INSTALL_TUTORIALS=1/INSTALL_TUTORIALS=0/g' "${S}/src/Makefile"
	fi

	eapply_user
}

src_compile() {
	cd "${S}/src"

	# force a "yocto host" build by defining CC
	emake CC="$(tc-getCC)"
}

src_install() {
	cd "${S}/src"

	# force a "yocto host" build by defining CC
	emake CC="$(tc-getCC)" DESTDIR="${D}" install
}
