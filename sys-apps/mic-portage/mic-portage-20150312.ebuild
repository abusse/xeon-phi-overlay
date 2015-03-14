# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

DESCRIPTION="Several settings and patches to use the default portage tree on Intel Xeon Phi cards"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

src_unpack() {
	[ `uname -m` != "k1om" ] && die "This set is for the Xeon Phi card itself and not the host."

	mkdir ${P}
}

src_install() {
	dodir /etc/portage/package.env
	insinto /etc/portage/package.env
	newins "${FILESDIR}/${PV}/x86_64-k1om-linux-gnu.env" x86_64-k1om-linux-gnu

	dodir /etc/portage/env
	cp -r "${FILESDIR}"/${PV}/env/* "${D}"/etc/portage/env/

	dodir /etc/portage/patches
	cp -r "${FILESDIR}"/${PV}/patches/* "${D}"/etc/portage/patches/
}
