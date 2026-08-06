# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

TOOLCHAIN_GCC_PV=${PV%_p*}

inherit toolchain intel-mpss

DESCRIPTION="The GNU Compiler Collection with patches for k1om (Xeon Phi) architecture"

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"
KEYWORDS="~amd64"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.8 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

SRC_URI=${MPSS_SRC_SRC_URI}

EXTRA_ECONF="--disable-libitm"

src_unpack() {
	use vanilla || die "Xeon Phi toolchain only supports a vanilla build!"
	use sanitize && die "Libsanitizer not available on Xeon Phi toolchain!"
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/gcc-${PV%_p*}+mpss${MPSS_VER}.tar.bz2
	mv "gcc-${PV%_p*}+mpss${MPSS_VER}" "${S}"
}

src_configure() {
	if is_crosscompile ; then
		confgcc+=( --disable-decimal-float )
	fi

	toolchain_src_configure
}
