# Copyright 1999-2021 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic cuda autotools rpm intel-xppsl

DESCRIPTION="displays the hardware topology in convenient formats"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cairo cuda debug gl +numa opencl +pci plugins svg static-libs xml X"

# TODO opencl only works with AMD so no virtual
# dev-util/nvidia-cuda-toolkit is always multilib

RDEPEND=">=sys-libs/ncurses-5.9-r3:0
	cairo? ( >=x11-libs/cairo-1.12.14-r4[X?,svg?] )
	cuda? ( >=dev-util/nvidia-cuda-toolkit-6.5.19-r1 )
	gl? ( || ( x11-drivers/nvidia-drivers[static-libs,tools] media-video/nvidia-settings ) )
	pci? (
		>=sys-apps/pciutils-3.3.0-r2
		>=x11-libs/libpciaccess-0.13.1-r1
	)
	plugins? ( dev-libs/libltdl:0 )
	numa? ( >=sys-process/numactl-2.0.10-r1 )
	xml? ( >=dev-libs/libxml2-2.9.1-r4 )
	!!sys-apps/hwloc"
DEPEND="${RDEPEND}
	>=virtual/pkgconfig-0-r1"

DOCS=( AUTHORS NEWS README VERSION )

AUTOTOOLS_AUTORECONF=1

S="${WORKDIR}/${PN#xppsl-}-${PV%_p230}+xpps"

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${PN#xppsl-}-${PV%_p230}*.src.rpm)
}

src_prepare() {
	eapply_user
	if use cuda ; then
		append-cflags -I/opt/cuda/include
		append-cppflags -I/opt/cuda/include
	fi
	eautoreconf
}
