# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_9 )

inherit python-single-r1 flag-o-matic linux-info rpm intel-xppsl

DESCRIPTION="Intel(R) Xeon Phi(TM) processor diagnosing tool"
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="!!sys-apps/xppsl-systools-sb
	 sys-apps/dmidecode
         ${PYTHON_DEPS}"
DEPEND="${RDEPEND}"

MY_PV=${PV%_p*}
S="${WORKDIR}/${PN:6}-${MY_PV}+xpps"

CONFIG_CHECK="~DMI_SYSFS"
ERROR_DMI_SYSFS="Certain functions are only available with DMI_SYSFS support in your kernel."

pkg_setup() {
	python_setup
}

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${PN:6}*.src.rpm)
}

src_prepare() {
	append-cflags -U_FORTIFY_SOURCE

	eapply_user
}

src_install() {
	emake DESTDIR="${D}" PREFIX="/usr" install

	python_fix_shebang "${D}"
}
