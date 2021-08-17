# Copyright 1999-2021 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic rpm intel-xppsl

DESCRIPTION="User Extensible Heap Manager for high bandwidth memory (MCDRAM)"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="sys-process/numactl"
DEPEND="${RDEPEND}"

MY_PV=${PV%_p*}
S="${WORKDIR}/${PN:6}-${MY_PV}+xpps"

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${PN:6}*.src.rpm)
}

src_prepare() {
	echo ${MY_PV} > "${S}/jemalloc/VERSION"
	echo ${MY_PV} > "${S}/VERSION"

	./autogen.sh || die

	# TODO The package contains its own jemalloc, maybe it can replaced by the one from portage
	./build_jemalloc.sh || die

	append-cflags -U_FORTIFY_SOURCE

	eapply_user
}
