# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1 rpm intel-mpss

DESCRIPTION="Host driver for Intel Xeon Phi coprocessor cards"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_LINUX_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# The driver calls set_fs()/KERNEL_DS, which x86 lost in 5.10, so 5.4 is a hard
# ceiling rather than a warning.  Raising it means porting the remaining uaccess
# calls in host/ to kernel_read()/kernel_write().
MODULES_KERNEL_MAX=5.4

PATCHES=(
	# Intel's last KNC release targets RHEL 7.4 (3.10).  This forward-ports it
	# over the 4.15 timer conversion (timer_setup()/from_timer(), which dropped
	# the .data member the vcons and boot timers relied on) up to 5.4.  Derived
	# from github.com/charlieporth1/mpss-modules, with that fork's bring-up
	# trace printks removed -- they included one in adapter_isr() and a "%s"
	# passed an int, and one that had swallowed the body of a braceless
	# "if (!etc_comp)" so calc_deltaf() re-ran its timed measurement loop on
	# every init.  Also corrects the get_user_pages() calls in scif_pin_pages()
	# and mic_pin_user_pages(): the fork's collapse of the pre-4.6 8-arg form
	# left current/current->mm as the start address and PROT_WRITE as gup flags,
	# so SCIF RMA registration failed with EFAULT (bring-up was unaffected --
	# only the memory-pinning/offload path pins user pages).  Maintained in a git
	# tree (pristine -> patch); regenerate with `git diff pristine <branch>`.
	"${FILESDIR}/${P}-linux-5.4.patch"
)

MIC_ARCH=k1om

src_unpack() {
	unpack ${A}
	rpm_unpack ./mpss-${PV}/src/${P/mic/mpss}-1.src.rpm
	mkdir ${P} || die
	cd ${P} && unpack ../${P/mic/mpss}.tar.bz2
}

src_compile() {
	local modlist=( mic=extra )
	local modargs=(
		KERNEL_SRC="${KV_OUT_DIR}"
		KERNEL_VERSION="${KV_FULL}"
		MIC_CARD_ARCH="${MIC_ARCH}"
	)

	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install

	# Other modules (and the card-side build) link against SCIF, so publish the
	# symbol versions and the kernel-side header alongside the module.
	insinto /lib/modules/${KV_FULL}
	newins Module.symvers scif.symvers

	insinto "${KV_DIR}"/include/modules
	newins include/scif.h scif.h

	insinto /lib/udev/rules.d
	newins udev-mic.rules 50-udev-mic.rules
}
