# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils

DESCRIPTION="C-library to access and update Intel(R) Xeon Phi(TM) Coprocessor parameters"
HOMEPAGE="http://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-src-${PV}.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="app-text/asciidoc"
RDEPEND="=sys-kernel/mic-rasmm-kernel-${PV}"

src_unpack() {
	[ `uname -m` != "x86_64" ] && die "This tool is for the Xeon Phi host not the card."

	unpack ${A}
	unpack ./mpss-${PV}/src/mpss-micmgmt-${PV}.tar.bz2
	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
	mv mpss-micmgmt-${PV} ${P}
}

src_compile() {
	emake -I ${WORKDIR}/mpss-metadata-${PV} lib || die "emake failed"
        emake -I ${WORKDIR}/mpss-metadata-${PV} lib_oem || die "emake failed"
}

src_install() {
	emake -I ${WORKDIR}/mpss-metadata-${PV} DESTDIR="${D}" install_lib
        emake -I ${WORKDIR}/mpss-metadata-${PV} DESTDIR="${D}" install_lib_oem
}
