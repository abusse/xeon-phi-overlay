# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils flag-o-matic

DESCRIPTION="Various tools to manage Intel(R) Xeon Phi(TM) coprocessors"
HOMEPAGE="http://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-src-${PV}.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="app-text/asciidoc"
RDEPEND="=sys-libs/libmicmgmt-${PV}"

src_unpack() {
	[ `uname -m` != "x86_64" ] && die "This tool is for the Xeon Phi host not the card."

	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2

	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
}

src_compile() {
	append-flags -Wno-error=unused-but-set-variable -Wno-error=unused-result

        emake -I ${WORKDIR}/mpss-metadata-${PV} all || die "emake failed"
}

src_install() {
        emake -I ${WORKDIR}/mpss-metadata-${PV} DESTDIR="${D}" install
}

