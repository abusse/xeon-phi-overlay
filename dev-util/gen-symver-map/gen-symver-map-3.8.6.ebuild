# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )

inherit intel-mpss python-r1

DESCRIPTION="Automatically generates a version script from macro annotations in the code."
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

PATCHES=(
	# Intel's script is Python 2: ConfigParser, "print >>f" redirection, and
	# it feeds Popen output straight to a str regex, which is bytes on py3.
	"${FILESDIR}/${P}-python3.patch"
)

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# configparser is stdlib on python3; RDEPEND on an interpreter for the env-python3 shebang
RDEPEND="${PYTHON_DEPS}"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_prepare() {
	# Apply the Python 3 port (PATCHES); default also runs eapply_user.
	default
}

src_install() {
	mkdir -p "${D}/usr/bin"
	cp "${WORKDIR}/${P}/${PN}" "${D}/usr/bin"
}
