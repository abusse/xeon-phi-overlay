# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCHVER="1.0"
ELF2FLT_VER=""
inherit toolchain-binutils

KEYWORDS="~amd64"

MPSS_VER=3.8.1
SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss-src-${MPSS_VER}.tar"

tc-binutils_unpack() {
	case ${BTYPE} in
	cvs) cvs_src_unpack ;;
	git) git-2_src_unpack ;;
	*)   unpacker ${A} ;;
	esac
	mkdir -p "${MY_BUILDDIR}"
	[[ -d ${WORKDIR}/patch ]] && mkdir "${WORKDIR}"/patch/skip

	use vanilla || die "Xeon Phi toolchain only supports a vanilla build!"
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/binutils-${PV//_p*}+mpss${MPSS_VER}.tar.bz2
	mv binutils-${PV//_p*}+mpss${MPSS_VER} ${S}
}