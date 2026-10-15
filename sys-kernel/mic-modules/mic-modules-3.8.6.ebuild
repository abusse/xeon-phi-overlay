# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs intel-mpss

DESCRIPTION="Card-side drivers for Intel Xeon Phi (KNC) coprocessor cards"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# Built for the card (CHOST k1om-*) against a configured and built
# sys-kernel/mic-sources tree; set KERNEL_DIR to use another one.
DEPEND="sys-kernel/mic-sources"

PATCHES=(
	# The card side of Intel's MPSS 3.8.6 drivers (SCIF, virtio block, net
	# and console, RAS, power management) forward-ported to the knc-v6.18
	# card kernel; regenerate with `git diff <pristine import> knc-v6.18` in
	# the mpss-card git tree.
	"${FILESDIR}/${P}-card-linux-6.18.patch"
)

S="${WORKDIR}/${P/mic/mpss}"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P/mic/mpss}.tar.bz2
}

pkg_setup() {
	KERNEL_DIR=${KERNEL_DIR:-${ESYSROOT}/usr/src/linux}
	[[ -r ${KERNEL_DIR}/include/config/kernel.release ]] ||
		die "KERNEL_DIR=${KERNEL_DIR} is not a configured and built card kernel tree"
	grep -q "^CONFIG_MK1OM=y" "${KERNEL_DIR}"/.config ||
		die "KERNEL_DIR=${KERNEL_DIR} is not a KNC card kernel (CONFIG_MK1OM unset)"
	MIC_KV=$(<"${KERNEL_DIR}"/include/config/kernel.release)
	einfo "Building against ${KERNEL_DIR} (${MIC_KV})"
}

mic_make() {
	# CHOST is k1om-* when cross-emerged into a card root; built on the host
	# for a card image, use the k1om cross toolchain.
	local cross=${CHOST}-
	[[ ${CHOST} == k1om-* ]] || cross=k1om-mpss-linux-gnu-
	emake ARCH=k1om CROSS_COMPILE="${cross}" MIC_CARD_ARCH= \
		KERNEL_SRC="${KERNEL_DIR}" KERNEL_VERSION="${MIC_KV}" \
		prefix="${EPREFIX}"/usr sysconfdir="${EPREFIX}"/etc "$@"
}

src_compile() {
	mic_make modules
}

src_install() {
	mic_make DESTDIR="${D}" modules_install conf_install dev_install
	# modules_install runs depmod; the index belongs to the card system.
	find "${ED}"/lib/modules -maxdepth 2 -name "modules.*" -delete || die

	# Other card modules link against SCIF.
	insinto /lib/modules/${MIC_KV}
	newins Module.symvers scif.symvers
}
