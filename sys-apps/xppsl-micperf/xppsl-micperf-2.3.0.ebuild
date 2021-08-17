## Copyright 1999-2021 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_9 )

inherit python-single-r1 flag-o-matic rpm intel-xppsl

DESCRIPTION="Performance benchmarks for the Intel Xeon Phi X200 Processor (Knights Landing)."
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="Intel-XPPSL"
SLOT="0"
KEYWORDS="~amd64"

IUSE="cluster"

RDEPEND="sci-libs/mkl
	sys-libs/xppsl-memkind
	 sys-apps/dmidecode
	 ${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	>=dev-libs/intel-common-16.0
		dev-lang/icc"

MY_PV=${PV%_p*}
S="${WORKDIR}/${PN:6}-${MY_PV}+xpps"

pkg_setup() {
	die "This ebuild is currently broken. MPI is missing in latest ICC and Python2 is Deprecated"
	python_setup
}

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${PN:6}*.src.rpm)
}

foo_src_prepare() {
	# shoc_download and shoc_readback are not supported on KNL SB remove before building micperf
	rm "${S}/micp/micp/kernels/shoc_download.py"
	rm "${S}/micp/micp/kernels/shoc_readback.py"
	rm "${S}/ut/micp_ut/micp_kernels_shoc_test.py"

	# we have to fix up python to use version 2
	sed -i 's/python/python3/g' "${S}/micp/Makefile"
	for file in `find "${S}" -type f`; do
		sed -i -e 's/\(#!\/usr\/bin\/env python\)/\12/g' "$file"
	done

	if ! use cluster ; then
		sed -i '/KNL_SNC_TARGETS =/d' "${S}/gemm/Makefile"
		sed -i 's/knlsb: stream stream_mpi/knlsb: stream/g' "${S}/stream/Makefile"
		sed -i '/$(INSTALL) stream_mpi/d' "${S}/stream/Makefile"
	fi

	# MIC support was removed by Intel in the latest software Stack
	# so this might be a bug or leftover?
	sed -i 's/mkl_mic_get_device_count()/0/g' "${S}/gemm/main.c"

	# There seems to be a problem with the system math.h
	# see https://software.intel.com/en-us/forums/intel-c-compiler/topic/760979
	sed -i 's/EXTRA_CFLAGS =/EXTRA_CFLAGS = -D__PURE_INTEL_C99_HEADERS__/g' "${S}/stream/Makefile"

	# Build is currently broken due issues between ICC and glibc2.27
	# see https://software.intel.com/en-us/forums/intel-c-compiler/topic/777003
	sed -i '/deepbench intel/d' "${S}/Makefile"
	sed -i '/deepbench instal/d' "${S}/Makefile"

	eapply_user
}

src_compile() {
	emake VERSION="${PV}" MKLROOT="$(echo /opt/intel/*/linux/mkl)" knlsb
}

src_install() {
	emake DESTDIR="${D}" VERSION="${PV}" install-knlsb
}
