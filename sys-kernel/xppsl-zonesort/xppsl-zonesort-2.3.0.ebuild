# Copyright 1999-2021 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit linux-mod rpm intel-xppsl

DESCRIPTION="The zonesort kernel module for the Intel Knights Landing"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=""
DEPEND="virtual/linux-sources"

MODULE_NAMES="zonesort(extra::zonesort)"
BUILD_TARGETS="modules"

S="${WORKDIR}/zonesort-1.0+xpps"

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name zonesort-1.0+xpps-${PV}*.src.rpm)
}

src_prepare() {
	sed -i '1s/^/#include <linux\/io.h>/' "${S}/zonesort/zonesort.c"
	default
}
