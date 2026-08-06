# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic intel-mpss

DESCRIPTION="Various tools to manage Intel Xeon Phi coprocessors"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"

PATCHES=(
	# mpssinfo opens these streams with popen() but closes them with
	# fclose(), which never reaps the child -- micinfo leaked a zombie
	# per host-memory query.  POSIX requires pclose().
	"${FILESDIR}/${P}-popen-pclose.patch"
)

DEPEND="app-text/asciidoc"
RDEPEND="=sys-libs/libmicmgmt-${PV} =sys-firmware/mpss-flash-${PV}"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2

	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
}

src_prepare() {
	default

	# 2013 C built by a 2026 compiler: its own -Werror promotes new
	# style diagnostics to hard errors.  Keep the warnings, drop the
	# promotion; real defects are fixed by patch instead.
	find . -name Makefile -exec sed -i 's/[[:space:]]-Werror\b//g' {} + || die
}

src_compile() {
	append-cflags -fgnu89-inline
	append-flags -Wno-error=unused-but-set-variable -Wno-error=unused-result
	emake -I "${WORKDIR}/mpss-metadata-${PV}" all
}

src_install() {
	emake -I "${WORKDIR}/mpss-metadata-${PV}" DESTDIR="${D}" install
}
