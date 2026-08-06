# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils rpm linux-mod intel-mpss

DESCRIPTION="Host driver for Intel Xeon Phi coprocessor cards"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_LINUX_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=""
DEPEND="virtual/linux-sources"

PATCHES=(
	# Intel's last KNC release targets RHEL 7.4 (3.10).  This forward-ports it
	# over the 4.15 timer conversion (timer_setup()/from_timer(), which dropped
	# the .data member the vcons and boot timers relied on) up to 5.4.  Derived
	# from github.com/charlieporth1/mpss-modules, with that fork's bring-up
	# trace printks removed -- they included one in adapter_isr() and a "%s"
	# passed an int, and one that had swallowed the body of a braceless
	# "if (!etc_comp)" so calc_deltaf() re-ran its timed measurement loop on
	# every init.
	"${FILESDIR}/${P}-linux-5.4.patch"
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
	if kernel_is -ge 5 10 0 ; then
		ewarn "This driver still calls set_fs()/KERNEL_DS, which was removed from"
		ewarn "x86 in 5.10, so it is not expected to build on kernel"
		ewarn "${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}. Use a 5.4 LTS kernel, or port the"
		ewarn "remaining uaccess calls in host/ over to kernel_read()/kernel_write()."
	elif kernel_is -gt 5 4 0 ; then
		ewarn "The patched module is only tested up to kernel 5.4."
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
