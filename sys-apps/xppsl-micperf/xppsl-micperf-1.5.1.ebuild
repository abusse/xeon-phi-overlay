# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit python-single-r1 flag-o-matic rpm intel-xppsl

DESCRIPTION="Performance benchmarks for the Intel(R) Xeon Phi(TM) X200 Processor."
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

SLOT="0"
KEYWORDS="~amd64"

RDEPEND="sci-libs/mkl
         sys-libs/xppsl-memkind
	 sys-apps/dmidecode
	 ${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	>=dev-libs/intel-common-16.0[mpi]
        dev-lang/icc"

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${P}-*.src.rpm)
}

src_prepare() {
	# shoc_download and shoc_readback are not supported on KNL SB remove before building micperf
	rm ${S}/micp/micp/kernels/shoc_download.py
	rm ${S}/micp/micp/kernels/shoc_readback.py
	rm ${S}/ut/micp_ut/micp_kernels_shoc_test.py

	# we have to fix up python to use version 2
	sed -i 's/python/python2/g' ${S}/micp/Makefile
	for file in `find ${S} -type f`; do
		sed -i -e 's/\(#!\/usr\/bin\/env python\)/\12/g' $file
	done

	eapply_user
}

src_compile() {
	emake VERSION="${PV}" knlsb
}

src_install() {
	emake DESTDIR="${D}" VERSION="${PV}" install-knlsb
}
