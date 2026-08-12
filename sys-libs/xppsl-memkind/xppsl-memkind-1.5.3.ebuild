# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic rpm intel-xppsl

DESCRIPTION="User Extensible Heap Manager for high bandwidth memory (MCDRAM)"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="sys-process/numactl"
DEPEND="${RDEPEND}"

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${P}-*.src.rpm)
}

src_prepare() {
	echo ${PV} > "${S}/jemalloc/VERSION"
	echo ${PV} > "${S}/VERSION"

	# TODO The package contains its own jemalloc, maybe it can replaced by the one from portage
	./build_jemalloc.sh

	append-cflags -U_FORTIFY_SOURCE

	eapply_user
}
