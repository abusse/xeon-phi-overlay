# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit eutils linux-mod

DESCRIPTION="Kernel modules for Intel(R) Xeon Phi(TM) coprocessor hosts"
SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-src-3.4.3.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND=""
DEPEND="virtual/linux-sources"

MODULE_NAMES="mic(extra:)"

export MIC_CARD_ARCH=k1om

src_unpack() {
	[ `uname -m` != "x86_64" ] && die "This modules are for the host. Card side modules ebuild is 'sys-kernel/micmodules'."

        unpack ${A}
        unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_compile() {
	set_arch_to_kernel

	emake KERNEL_LOCATION="${KERNEL_DIR}" || die "Failed to compile modules."
}

src_install() {
        emake KERNEL_LOCATION="${KERNEL_DIR}" DESTDIR="${D}" install || die "Failed to install modules."

	insinto /etc/modprobe.d
	doins mic.conf
}

pkg_preinst() {
	linux-mod_pkg_preinst
}
