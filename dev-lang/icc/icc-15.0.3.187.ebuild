# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

INTEL_DPN=parallel_studio_xe
INTEL_DID=7538
INTEL_DPV=2015_update3
INTEL_SUBDIR=composerxe
INTEL_SINGLE_ARCH=false

inherit intel-sdp

DESCRIPTION="Intel C/C++ Compiler (classic icc)"
HOMEPAGE="https://www.intel.com/content/www/us/en/developer/tools/oneapi/dpc-compiler.html"

KEYWORDS="-* ~amd64"
SLOT="15"

RDEPEND="~dev-libs/intel-common-${PV}[compiler]
	sys-devel/mpss-k1om-compat"

INTEL_BIN_RPMS=( compilerproc compilerproc-devel )
INTEL_DAT_RPMS=( compilerproc-common compilerproc-vars )

CHECKREQS_DISK_BUILD=1G

pkg_postinst() {
	intel-sdp_pkg_postinst

	elog "icc/icpc are placed on PATH via /etc/env.d; run 'env-update && source"
	elog "/etc/profile' or start a new shell before use."
	elog "A valid classic Intel license must be present, e.g. in"
	elog "${EPREFIX}/opt/intel/licenses/."
}
