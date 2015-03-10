# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit rpm

SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-3.4.3-linux.tar"
DESCRIPTION="Bootloader and firmware for Intel(R) Xeon Phi(TM) coprocessors."

LICENSE="GPL-2 public-domain"
SLOT="0"
KEYWORDS="~amd64"

src_unpack () {
	unpack ${A}
	rpm_unpack ./mpss-${PV}/glibc2.12.2pkg-${P}-1.glibc2.12.2.x86_64.rpm
	rm -rf ./mpss-${PV}
}

src_install () {
	cp -r * ${D}
}
