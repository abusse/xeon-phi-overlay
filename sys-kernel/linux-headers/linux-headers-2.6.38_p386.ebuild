# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs intel-mpss

DESCRIPTION="Linux kernel headers for the k1om (Xeon Phi) card OS"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# A headers-only install, done directly rather than through an eclass.  Build it
# with ARCH=x86: Intel's tree has no arch/k1om, the card OS is arch/x86.

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl
"

MY_P="linux-${PV%_p*}+mpss${MPSS_VER}"
S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/${MY_P}.tar.bz2
}

src_compile() { :; }

src_install() {
	local ddir=/usr/include
	[[ ${CTARGET} != ${CHOST} ]] && ddir=/usr/${CTARGET}/usr/include

	# scripts/unifdef.c (2.6.38) uses "constexpr" as an identifier, which C23
	# -- GCC >= 15's default -- turned into a keyword.
	emake \
		ARCH=x86 \
		HOSTCC="$(tc-getBUILD_CC)" \
		HOSTCFLAGS="-std=gnu17 -O2" \
		INSTALL_HDR_PATH="${ED}${ddir}/.." \
		headers_install

	find "${ED}" '(' -name '.install' -o -name '*.cmd' ')' -delete || die
	find "${ED}" -depth -type d -empty -delete 2>/dev/null
}
