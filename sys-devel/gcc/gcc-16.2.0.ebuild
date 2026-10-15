# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# ::gentoo's gcc-16.2.0.ebuild, plus the k1om series for k1om targets.
# Other targets build exactly as from ::gentoo.

TOOLCHAIN_HAS_TESTS=1
PATCH_GCC_VER="16.1.0"
PATCH_VER="3"
MUSL_VER="1"
MUSL_GCC_VER="16.1.0"
PYTHON_COMPAT=( python3_{11..14} )

inherit toolchain

KEYWORDS="~amd64 ~arm64"

if [[ ${CATEGORY} != cross-* ]] ; then
	RDEPEND="elibc_glibc? ( sys-libs/glibc[cet(-)?] )"
	DEPEND="${RDEPEND}"
fi

src_prepare() {
	toolchain_src_prepare
	eapply "${FILESDIR}"/${PN}-13-fix-cross-fixincludes.patch
	[[ ${CTARGET} == k1om-* ]] && eapply "${FILESDIR}"/${P}-k1om
	eapply_user
}
