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

# Forward-ported and RMA-tested on every kernel from 4.19 through 6.18.  Beyond
# 6.18 is untested, so cap it here; bump after validating a newer kernel per
# PORTING.md in the source git tree.
MODULES_KERNEL_MAX=6.18

PATCHES=(
	# Intel's last KNC release targets RHEL 7.4 (3.10).  This single patch
	# carries the whole forward-port from there to Linux 6.18, every hunk
	# version- or feature-guarded (see the added include/mic/mic_compat.h) so
	# one source still builds -- warning-clean -- on 4.19 through 6.18.  It
	# covers, among others: the 4.15 timer_setup() conversion; the timer rename
	# (del_timer_sync/from_timer -> timer_delete_sync/timer_container_of);
	# mm->mmap_sem -> mmap_lock; proc_ops; ioremap_nocache -> ioremap; the
	# pci_*() -> dma_*() DMA API; get_user_pages() losing its vmas arg (and a
	# corrected arg bug that made scif_pin_pages() fail with EFAULT); read-only
	# vma->vm_flags; const dev_addr / bin_attribute / tty set_termios;
	# MAX_ORDER -> MAX_PAGE_ORDER; struct file f_count -> f_ref; and a private
	# struct mic_vmcore after the kernel's left the public headers.  Maintained
	# in a git tree (tag `pristine` -> per-kernel `port-*` branches); regenerate
	# with `git diff pristine <tag>` -- see PORTING.md there.
	"${FILESDIR}/${P}-linux-5.4-6.18.patch"
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
