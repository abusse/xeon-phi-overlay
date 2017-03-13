# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

MPSS_VER="3.4.3"

PATCH_VER=${MPSS_VER}

TOOLCHAIN_GCC_PV=${PV%_p*}

inherit toolchain

DESCRIPTION="The GNU Compiler Collection with patches for k1om (Xeon Phi) architecture"

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"
KEYWORDS="~amd64"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.8 )
	>=${CATEGORY}/binutils-2.18"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-src-${MPSS_VER}.tar"

src_unpack() {
	if has_version '<sys-libs/glibc-2.12' ; then
		ewarn "Your host glibc is too old; disabling automatic fortify."
		ewarn "Please rebuild gcc after upgrading to >=glibc-2.12 #362315"
		EPATCH_EXCLUDE+=" 10_all_default-fortify-source.patch"
	fi

	# drop the x32 stuff once 4.7 goes stable
	if [[ ${CTARGET} != x86_64* ]] || ! has x32 $(get_all_abis TARGET) ; then
		EPATCH_EXCLUDE+=" 90_all_gcc-4.7-x32.patch"
	fi

	use vanilla || die "Xeon Phi toolchain only supports a vanilla build!"
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/gcc-${PV%_p*}+mpss${MPSS_VER}.tar.bz2
	mv gcc-${PV%_p*}+mpss${MPSS_VER} ${S}

	cd ${S}
	epatch "${FILESDIR}/${PV%_p*}/gengtype.c.patch"
}

src_configure() {
	if is_crosscompile ; then
		confgcc+=( --disable-decimal-float )
	fi

	toolchain_src_configure
}
