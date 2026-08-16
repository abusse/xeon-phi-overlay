# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1 rpm intel-xppsl

DESCRIPTION="The zonesort kernel module for the Intel Knights Landing"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=""
DEPEND=""

S="${WORKDIR}"

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name xppsl-addons-${PV}-*.src.rpm)
}

src_compile() {
	# The upstream Makefile takes its kernel tree from
	# /lib/modules/$(uname -r)/build -- the *running* kernel, not the one
	# being built against.  A command-line KERNEL_SRC overrides that.
	local modlist=( zonesort_module=extra:.:xppsl-addons )
	local modargs=( KERNEL_SRC="${KV_OUT_DIR}" )
	linux-mod-r1_src_compile
}
