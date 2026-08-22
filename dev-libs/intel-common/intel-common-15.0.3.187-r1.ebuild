# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

INTEL_DPN=parallel_studio_xe
INTEL_DID=7538
INTEL_DPV=2015_update3
INTEL_SUBDIR=composerxe
INTEL_SINGLE_ARCH=false

inherit intel-sdp

DESCRIPTION="Common libraries and utilities for the classic Intel compilers"
HOMEPAGE="https://www.intel.com/content/www/us/en/developer/tools/oneapi/dpc-compiler.html"

IUSE="+compiler"
KEYWORDS="-* ~amd64"
SLOT="0"

CHECKREQS_DISK_BUILD=1G

pkg_setup() {
	INTEL_BIN_RPMS=( openmp openmp-devel )
	INTEL_DAT_RPMS=( compilerpro-common compilerpro-common-pset )
	if use compiler; then
		INTEL_BIN_RPMS+=( compilerpro-devel sourcechecker-devel )
		INTEL_DAT_RPMS+=( compilerpro-vars sourcechecker-common ccompxe compxe fcompxe )
	fi
	intel-sdp_pkg_setup
}

src_install() {
	intel-sdp_src_install

	local arch path ldpath fenv=35intelsdp
	for arch in ${INTEL_ARCH}; do
		path+=":${INTEL_SDP_EDIR}/bin/${arch}"
		ldpath+=":${INTEL_SDP_EDIR}/compiler/lib/${arch}"
	done
	cat > "${fenv}" <<-EOF || die
		NLSPATH=${INTEL_SDP_EDIR}/lib/locale/en_US/%N
		INTEL_LICENSE_FILE=${INTEL_SDP_EDIR}/licenses:${EPREFIX}/opt/intel/licenses
		PATH=${path#:}
		ROOTPATH=${path#:}
		LDPATH=${ldpath#:}
	EOF
	doenvd "${fenv}"

	cat > "${T}/40-${PN}" <<-EOF || die
		SEARCH_DIRS_MASK="${INTEL_SDP_EDIR}"
	EOF
	insinto /etc/revdep-rebuild
	doins "${T}/40-${PN}"
}
