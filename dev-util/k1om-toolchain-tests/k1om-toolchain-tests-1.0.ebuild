# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Card tests for the k1om (Xeon Phi KNC) cross toolchain"
HOMEPAGE="https://github.com/abusse/xeon-phi-overlay"
S=${WORKDIR}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	app-arch/tar
	app-arch/gzip
	sys-apps/diffutils
	sys-devel/binutils
	virtual/openssh
"

src_install() {
	local f=${FILESDIR}/${P}
	dobin "${f}"/k1om-toolchain-test
	insinto /usr/share/${PN}
	doins "${f}"/run-on-card.sh
	doins -r "${f}"/tests
	insinto /etc
	doins "${f}"/k1om-toolchain-test.conf
}

pkg_postinst() {
	elog "Run the tests with: k1om-toolchain-test --card root@<card> [--via <host>]"
	elog "The card needs root ssh access by key; see k1om-toolchain-test --help."
}
