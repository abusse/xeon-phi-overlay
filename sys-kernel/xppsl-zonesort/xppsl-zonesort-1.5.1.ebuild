# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit linux-mod rpm intel-xppsl

DESCRIPTION="The zonesort kernel module for the Intel Knights Landing"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

SLOT="0"
KEYWORDS="~amd64"

RDEPEND=""
DEPEND="virtual/linux-sources"

MODULE_NAMES="zonesort_module(extra::xppsl-addons)"
BUILD_TARGETS="modules"

S=${WORKDIR}

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name xppsl-addons-${PV}-*.src.rpm)
}
