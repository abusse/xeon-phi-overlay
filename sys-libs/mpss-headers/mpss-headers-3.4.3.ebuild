# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/em8300-modules/em8300-modules-0.18.0.ebuild,v 1.2 2010/10/20 13:31:46 ssuominen Exp $

EAPI=5

DESCRIPTION="TODO"
#SRC_URI="http://registrationcenter.intel.com/irc_nas/5017/mpss-src-3.4.2.tar"
SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-src-3.4.3.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND=""
DEPEND=""

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/mpss-modules-${PV}.tar.bz2
	mv mpss-modules-${PV} ${P}
}

src_prepare() {
	if [ `uname -m` = k1om ]; then
		einfo "Preparing card headers."
	else
		einfo "Preparing host headers."
		sed -i -e 's/export MIC_CARD_ARCH/export MIC_CARD_ARCH=k1om/' Makefile || die "Sed failed!"
	fi
}

src_compile() {
	true;
}

src_install() {
        emake DESTDIR="${D}" dev_install || die "Failed to install modules."
}
