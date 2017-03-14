# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

MPSS_VER=3.8.1

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

SRC_URI="http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss-src-${MPSS_VER}.tar"
KEYWORDS="~amd64"

DEPEND="app-arch/xz-utils
	dev-lang/perl"
RDEPEND="!!media-sound/alsa-headers"

S=${WORKDIR}/linux-${PV%_p*}+mpss${MPSS_VER}

src_unpack() {
        unpack ${A}
        unpack ./mpss-${MPSS_VER}/src/linux-${PV%_p*}+mpss${MPSS_VER}.tar.bz2
}

src_install() {
	kernel-2_src_install

	# hrm, build system sucks
	find "${ED}" '(' -name '.install' -o -name '*.cmd' ')' -delete
	find "${ED}" -depth -type d -delete 2>/dev/null
}

src_test() {
	# Make sure no uapi/ include paths are used by accident.
	egrep -r \
		-e '# *include.*["<]uapi/' \
		"${D}" && die "#include uapi/xxx detected"

	einfo "Possible unescaped attribute/type usage"
	egrep -r \
		-e '(^|[[:space:](])(asm|volatile|inline)[[:space:](]' \
		-e '\<([us](8|16|32|64))\>' \
		.

	einfo "Missing linux/types.h include"
	egrep -l -r -e '__[us](8|16|32|64)' "${ED}" | xargs grep -L linux/types.h

	emake ARCH=$(tc-arch-kernel) headers_check
}
