# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit intel-mpss

DESCRIPTION="Intel MPSS Management Daemon"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+firmware +modules ssh1"

PATCHES=(
	"${FILESDIR}/${P}.patch"
	"${FILESDIR}/passwd-array-fix.patch"

	# getcwd() signals failure with NULL, so the original
	# "getcwd(...) < 0" test could never fire and cwd was then
	# used uninitialised.
	"${FILESDIR}/${P}-getcwd-null.patch"

	# micctrl/mpssd probe for RedHat/SUSE/Ubuntu network dirs and abort
	# on anything else. Teach them about Gentoo so they work without
	# MPSS_DIST= being set by hand.
	"${FILESDIR}/${P}-gentoo-distro.patch"

	# Restore PersistentFS (virtblk-backed root): re-add the RootDevice
	# "PFS"/"PersistentFS" parser case dropped in 3.8.6, and have mpssd
	# assign the virtblk_file backing store at boot for that root type.
	"${FILESDIR}/${P}-restore-pfs.patch"
)

DEPEND="=sys-libs/mpss-headers-${PV}
		=sys-libs/libscif-${PV}"
RDEPEND="${DEPEND}
	modules? ( =sys-kernel/mpss-modules-${PV} )
	firmware? ( =sys-kernel/mic-image-${PV} )
	=sys-apps/mpss-micmgmt-${PV}
	ssh1? ( net-misc/openssh[ssh1] )"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_prepare() {
	default

	use ssh1 || eapply "${FILESDIR}/no-ssh1.patch"

	# 2013 C built by a 2026 compiler: keep the warnings, drop the
	# -Werror promotion.  Real defects are fixed by patch.
	find . -name Makefile -exec sed -i 's/[[:space:]]-Werror//g' {} + || die
}

src_install() {
	emake DESTDIR="${D}" install

	doenvd "${FILESDIR}/90mpssd" || die
	doinitd "${FILESDIR}/mpss" || die
}

pkg_postinst() {
	elog "Upstream micctrl/mpssd only know RedHat, SUSE and Ubuntu, and abort on"
	elog "anything else with \"Distribution from system probe unknown\"."
	elog "${P}-gentoo-distro.patch adds a native Gentoo case, so no"
	elog "MPSS_DIST= workaround is needed."
	elog
	elog "OpenRC has no per-interface network config directory (it is all"
	elog "config_micX= in /etc/conf.d/net), so there is no layout micctrl could"
	elog "write that OpenRC would read.  It therefore writes the card network"
	elog "files to:"
	elog "    /etc/mpss/network"
	elog "Treat those as templates to translate into /etc/conf.d/net, not as"
	elog "live configuration."
	elog
	elog "Bring a card up with:"
	elog "    modprobe mic"
	elog "    micctrl --initdefaults"
	elog "    rc-service mpss start"
}
