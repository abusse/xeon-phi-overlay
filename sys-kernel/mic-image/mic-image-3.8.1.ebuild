# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit rpm intel-mpss

DESCRIPTION="Boot image for Xeon Phi card"
HOMEPAGE="https://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI=${MPSS_LINUX_SRC_URI}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}"

src_unpack () {
	unpack ${A}
	rpm_unpack ./mpss-${PV}/mpss-boot-files-${PV}-1.glibc2.12.x86_64.rpm
	rm -rf ./mpss-${PV}
}

src_install () {
	cp -r * "${D}"
}
