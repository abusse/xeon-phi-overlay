# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit intel-mpss

DESCRIPTION="C-library to access and update Intel Xeon Phi Coprocessor parameters"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"

PATCHES=(
	# set_power_limit0/1 pass *(uint32_t *)&ptrig to scif_request without
	# zeroing the struct first, so the command word can carry uninitialised
	# stack.  Modern GCC catches it as -Werror=uninitialized.  Every other
	# use of mr_rsp_ptrig in this file memsets it.
	"${FILESDIR}/${P}-uninit-ptrig.patch"
)

# miclib.h includes scif.h and the library links -lscif
DEPEND="app-text/asciidoc
	=sys-libs/libscif-${PV}"
RDEPEND="=sys-kernel/mic-rasmm-kernel-${PV}
	=sys-libs/libscif-${PV}"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/mpss-micmgmt-${PV}.tar.bz2
	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
	mv mpss-micmgmt-${PV} ${P}
}

src_prepare() {
	default

	# This is 2013 C++ built by a 2026 compiler: its own -Werror turns a pile
	# of new style diagnostics (misleading-indentation, deprecated-copy, ...)
	# into hard errors.  Keep the warnings, drop the promotion -- the one
	# genuine defect this surfaced (uninitialised mr_rsp_ptrig) is fixed by
	# ${P}-uninit-ptrig.patch instead of being silenced.
	find . -name Makefile -exec sed -i 's/[[:space:]]-Werror\b//g' {} + || die
}

src_compile() {
	emake -I "${WORKDIR}/mpss-metadata-${PV}" lib
}

src_install() {
	emake -I "${WORKDIR}/mpss-metadata-${PV}" DESTDIR="${D}" install_lib
}
