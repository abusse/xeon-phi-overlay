# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCHVER="1.0"
ELF2FLT_VER=""
inherit toolchain-binutils intel-mpss

KEYWORDS="~amd64"

SRC_URI=${MPSS_SRC_SRC_URI}

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