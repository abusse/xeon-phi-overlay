# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/em8300-modules/em8300-modules-0.18.0.ebuild,v 1.2 2010/10/20 13:31:46 ssuominen Exp $

EAPI=5
inherit eutils linux-mod

DESCRIPTION="TODO"
#SRC_URI="http://registrationcenter.intel.com/irc_nas/3778/mpss-src-3.1.2.tar"
SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-src-3.4.3.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=""
DEPEND="virtual/linux-sources"

MODULE_NAMES="mic(extra:)"

export MIC_CARD_ARCH=k1om

src_unpack() {
        unpack ${A}
        unpack ./mpss-${PV}/src/${P/mic/mpss}.tar.bz2
	mv ${P/mic/mpss} ${P}
}

src_prepare() {
	if kernel_is ge 3 18 7; then
		epatch "${FILESDIR}/linux-3.18.7.patch"
	fi
}

src_compile() {
	set_arch_to_kernel
	emake KERNEL_LOCATION="${KERNEL_DIR}" || die
}

src_install() {
	linux-mod_src_install

	insinto /lib/modules/${KV_FULL}/
	newins Module.symvers scif.symvers
	insinto ${KERNEL_DIR}/include/modules
	newins include/scif.h scif.h

	insinto /lib/udev/rules.d
	newins udev-mic.rules 50-udev-mic.rules
}

pkg_preinst() {
	linux-mod_pkg_preinst
}
