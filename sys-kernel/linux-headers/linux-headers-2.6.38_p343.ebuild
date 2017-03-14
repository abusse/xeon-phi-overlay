# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/linux-headers/linux-headers-3.1.ebuild,v 1.9 2012/05/12 16:14:37 armin76 Exp $

EAPI=5

MPSS_VER=${PV#*_p}
MPSS_VER=${MPSS_VER:0:1}.${MPSS_VER:1:1}.${MPSS_VER:2:1}

ETYPE="headers"
H_SUPPORTEDARCH="amd64"
inherit kernel-2

tc-arch-kernel() {
        echo "k1om"
}

tc-arch() {
        echo "amd64"
}

detect_version

SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-src-3.4.3.tar"
KEYWORDS="~amd64"

DEPEND="app-arch/xz-utils
	dev-lang/perl"
RDEPEND=""

S=${WORKDIR}/linux-${PV%_p*}+mpss${MPSS_VER}

src_unpack() {
        unpack ${A}
        unpack ./mpss-${MPSS_VER}/src/linux-${PV%_p*}+mpss${MPSS_VER}.tar.bz2
}

#src_prepare() {
#	has x32 $(get_all_abis) || EPATCH_EXCLUDE+=" 90_all_x32-3.1.patch"
#	[[ -n ${PATCH_VER} ]] && EPATCH_SUFFIX="patch" epatch "${WORKDIR}"/${PV}
#}

src_install() {
	kernel-2_src_install
	cd "${D}"
	egrep -r \
		-e '(^|[[:space:](])(asm|volatile|inline)[[:space:](]' \
		-e '\<([us](8|16|32|64))\>' \
		.
	headers___fix $(find -type f)

	egrep -l -r -e '__[us](8|16|32|64)' "${D}" | xargs grep -L linux/types.h

	# hrm, build system sucks
	find "${D}" '(' -name '.install' -o -name '*.cmd' ')' -print0 | xargs -0 rm -f

	# provided by libdrm (for now?)
	rm -rf "${D}"/$(kernel_header_destdir)/drm
}

src_test() {
	emake ARCH=$(tc-arch-kernel) headers_check || die
}
