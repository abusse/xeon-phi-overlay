# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/crossdev/crossdev-20120913.ebuild,v 1.1 2012/09/13 05:13:37 vapier Exp $

EAPI="4"

inherit eutils

KEYWORDS="~amd64"

DESCRIPTION="Gentoo Cross-toolchain generator"
HOMEPAGE="http://www.gentoo.org/"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

DEPEND="sys-devel/crossdev"

src_unpack(){
	mkdir ${S}
}

src_prepare(){
	mkdir ${S}
	cp "${FILESDIR}"/Makefile ${S} || die
	cp "${FILESDIR}"/cross-emerge-ng ${S} || die
	cp "${FILESDIR}"/toolchain-wrapper ${S} || die
}
