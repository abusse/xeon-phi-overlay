# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Linux kernel headers for the k1om (Xeon Phi) card OS"
HOMEPAGE="https://www.kernel.org/"
PATCH_VER="1"
PATCH_DEV="sam"
SRC_URI="
	mirror://kernel/linux/kernel/v6.x/linux-${PV}.tar.xz
	https://dev.gentoo.org/~${PATCH_DEV}/distfiles/sys-kernel/linux-headers/gentoo-headers-${PV}-${PATCH_VER}.tar.xz
"
S="${WORKDIR}/linux-${PV}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# The card kernel is arch/x86, so k1om takes the plain x86 uapi headers.

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl
	net-misc/rsync
"

src_prepare() {
	eapply "${WORKDIR}"/${PV}
	default
}

src_compile() { :; }

src_install() {
	local ddir=/usr/include
	[[ ${CTARGET} != ${CHOST} ]] && ddir=/usr/${CTARGET}/usr/include

	emake \
		ARCH=x86 \
		HOSTCC="$(tc-getBUILD_CC)" \
		INSTALL_HDR_PATH="${ED}${ddir}/.." \
		headers_install

	find "${ED}" '(' -name '.install' -o -name '*.cmd' ')' -delete || die
	find "${ED}" -depth -type d -empty -delete || die
}
