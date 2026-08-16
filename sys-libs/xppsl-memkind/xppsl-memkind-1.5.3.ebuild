# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

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
	default

	echo ${PV} > "${S}/jemalloc/VERSION"
	echo ${PV} > "${S}/VERSION"

	# TODO The package contains its own jemalloc, maybe it can replaced by the one from portage
	./build_jemalloc.sh || die

	append-cflags -U_FORTIFY_SOURCE
}

src_configure() {
	# The static_lib target is part of 'all': it runs ar -M to fuse
	# .libs/libmemkind.a together with jemalloc's libjemalloc_pic.a into one
	# archive.  econf disables static libraries by default, which leaves that
	# input missing and the build dies with "ar: .libs/libmemkind.a: No such
	# file or directory".
	econf --enable-static
}
