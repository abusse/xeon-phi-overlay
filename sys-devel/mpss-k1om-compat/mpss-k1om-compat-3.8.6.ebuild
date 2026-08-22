# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Classic x86_64-k1om-linux toolchain names and layout over the MPSS SDK"
HOMEPAGE="https://github.com/abusse/xeon-phi-overlay"

LICENSE="Intel-MPSS"
SLOT="0"
KEYWORDS="-* ~amd64"

RDEPEND="~sys-devel/mpss-sdk-k1om-${PV}"

S="${WORKDIR}"

# The MPSS 3.8 SDK ships a k1om-mpss-linux / gcc-5.1.1 toolchain, but the classic
# (pre-oneAPI) icc drivers hard-code the older x86_64-k1om-linux / gcc-4.7.0 names and
# the /opt/mpss/<v>/sysroots/usr/linux-k1om-4.7 layout, and invoke the linker without a
# --sysroot.  Map the old names/paths onto the SDK so those drivers link for -mmic.
SYSROOTS="/opt/mpss/${PV}/sysroots"
TARGET="k1om-mpss-linux"
CLASSIC="x86_64-k1om-linux"
SDK_GCC_PV="5.1.1"
BINDIR="${SYSROOTS}/x86_64-mpsssdk-linux/usr/bin/${TARGET}"
COMPAT="${SYSROOTS}/usr/linux-k1om-4.7"

src_install() {
	cat > "${T}/${CLASSIC}-ld" <<-EOF || die
		#!/bin/sh
		exec "${EPREFIX}${BINDIR}/${TARGET}-ld" --sysroot="${EPREFIX}${SYSROOTS}/${TARGET}" "\$@"
	EOF
	exeinto "${BINDIR}"
	doexe "${T}/${CLASSIC}-ld"

	local t
	for t in gcc g++ as ar nm ranlib objcopy objdump strip; do
		dosym "${TARGET}-${t}" "${BINDIR}/${CLASSIC}-${t}"
	done

	dosym "${SYSROOTS}/${TARGET}/usr/lib64"   "${COMPAT}/linux-k1om/usr/lib64"
	dosym "${SYSROOTS}/${TARGET}/usr/include" "${COMPAT}/linux-k1om/usr/include"
	dosym "${SYSROOTS}/${TARGET}/lib64"       "${COMPAT}/linux-k1om/lib64"
	dosym "${SYSROOTS}/${TARGET}/usr/lib64/${TARGET}/${SDK_GCC_PV}" \
		"${COMPAT}/lib/gcc/${CLASSIC}/4.7.0"
}
