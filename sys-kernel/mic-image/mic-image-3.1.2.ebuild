# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit rpm

SRC_URI="http://registrationcenter.intel.com/irc_nas/3778/mpss-${PV}-suse-11.3.tar"
DESCRIPTION="Boot image for Xeon Phi card"

LICENSE="GPL-2 public-domain"
SLOT="0"
KEYWORDS="~amd64 ~x86"

src_unpack () {
	unpack ${A}
	rpm_unpack ./mpss-${PV}/mpss-boot-files-${PV}-1.glibc2.12.2.x86_64.rpm
	rm -rf ./mpss-${PV}
}

src_install () {
	cp -r * ${D}
}
