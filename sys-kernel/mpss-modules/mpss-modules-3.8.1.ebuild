# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils rpm linux-mod intel-mpss

DESCRIPTION="Kernel modules for Intel(R) Xeon Phi(TM) coprocessor hosts"
HOMEPAGE="https://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI=${MPSS_LINUX_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=""
DEPEND="virtual/linux-sources"

PATCHES=(
	"${FILESDIR}/mic_blk.patch"
)

MODULE_NAMES="mic(extra:)"
BUILD_TARGETS="modules"

MIC_ARCH=k1om

pkg_setup() {
	linux-mod_pkg_setup

	BUILD_PARAMS="KERNEL_SRC=${KV_DIR} KERNEL_VERSION=${KV_MAJOR}.${KV_MINOR}.${KV_PATCH} V=1 KBUILD_VERBOSE=1 MIC_CARD_ARCH=${MIC_ARCH}"
}

src_unpack() {
	unpack ${A}
	rpm_unpack ./mpss-${PV}/src/${P/mic/mpss}-1.src.rpm
	mkdir ${P}
	cd ${P} && unpack ../${P/mic/mpss}.tar.bz2
}

src_prepare() {
	if kernel_is -ge 4 5 0 ; then
		ewarn "The MIC kernel module is only provided for kernel version 4.4 and below."
		ewarn "It might fail to build for the current kernel version ${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}"
	fi

	default
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
