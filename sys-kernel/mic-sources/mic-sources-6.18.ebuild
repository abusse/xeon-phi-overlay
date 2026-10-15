# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ETYPE="sources"
K_NOSETEXTRAVERSION="1"
K_SECURITY_UNSUPPORTED="1"
inherit kernel-2
detect_version

DESCRIPTION="Linux kernel sources with the KNC (Xeon Phi x100) card support"
HOMEPAGE="https://github.com/abusse/xeon-phi-overlay"
SRC_URI="${KERNEL_URI}"

KEYWORDS="~amd64 ~arm64"

src_prepare() {
	eapply "${FILESDIR}"/${P}-knc
	kernel-2_src_prepare
}

pkg_postinst() {
	kernel-2_pkg_postinst

	elog "The card configuration is config-mic-knc-6.18 in the source tree."
	elog "Build the card kernel with the k1om cross toolchain, e.g.:"
	elog "  cp config-mic-knc-6.18 .config"
	elog "  make ARCH=k1om CROSS_COMPILE=k1om-mpss-linux-gnu- olddefconfig bzImage modules"
}
