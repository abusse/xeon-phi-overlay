# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils linux-mod

DESCRIPTION="TODO"
HOMEPAGE="https://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI="http://registrationcenter.intel.com/irc_nas/3778/mpss-src-3.1.2.tar"

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
