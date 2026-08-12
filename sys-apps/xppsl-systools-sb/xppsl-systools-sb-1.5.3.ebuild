# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit python-single-r1 flag-o-matic linux-info rpm intel-xppsl

DESCRIPTION="A collection of tools to manage Intel(R) Xeon Phi(TM) processor"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="Intel-XPPSL"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="sys-apps/dmidecode
		 ${PYTHON_DEPS}"
DEPEND="${RDEPEND}"

CONFIG_CHECK="~DMI_SYSFS"
ERROR_DMI_SYSFS="Certain functions are only available with DMI_SYSFS support in your kernel."

S=${WORKDIR}

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${P}-*.src.rpm)

	append-cflags -Wno-error=unused-result
}

src_prepare() {
	# The script is written for Python v2
	sed -i -e 's/\(#!\/usr\/bin\/\)python/\1env python2/g' "${S}/apps/sysdiag/sysdiag"

	eapply_user
}
