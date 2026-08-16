# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic linux-info rpm intel-xppsl

DESCRIPTION="A collection of tools to manage Intel(R) Xeon Phi(TM) processor"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="Intel-XPPSL"
SLOT="0"
KEYWORDS="~amd64"

# The sysdiag script is Python 2 and has never been ported upstream, so depend
# on the 2.7 slot directly.  python-single-r1 cannot express this: python2_7 is
# a historical implementation there and the eclass refuses it.
RDEPEND="sys-apps/dmidecode
	dev-lang/python:2.7"
DEPEND=""

CONFIG_CHECK="~DMI_SYSFS"
ERROR_DMI_SYSFS="Certain functions are only available with DMI_SYSFS support in your kernel."

S="${WORKDIR}"

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${P}-*.src.rpm)
}

src_prepare() {
	default

	sed -i -e 's:\(#!/usr/bin/\)python:\1env python2:g' "${S}"/apps/sysdiag/sysdiag || die

    # 2016 C under a 2026 compiler
	append-cflags -Wno-error=unused-result
}
