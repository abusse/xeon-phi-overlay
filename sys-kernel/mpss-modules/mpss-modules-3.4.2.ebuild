# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/em8300-modules/em8300-modules-0.18.0.ebuild,v 1.2 2010/10/20 13:31:46 ssuominen Exp $

EAPI=5
inherit eutils linux-mod

DESCRIPTION="TODO"
SRC_URI="http://registrationcenter.intel.com/irc_nas/5017/mpss-src-3.4.2.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND=""
DEPEND="virtual/linux-sources"

#MODULE_NAMES="mic(extra:)"

src_unpack() {
        unpack ${A}
        unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_prepare() {
	if [ `uname -m` = k1om ]; then
		einfo "Building card modules."
	else
		einfo "Building host modules."
		sed -i -e 's/export MIC_CARD_ARCH/export MIC_CARD_ARCH=k1om/' Makefile || die "Sed failed!"
	fi
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
