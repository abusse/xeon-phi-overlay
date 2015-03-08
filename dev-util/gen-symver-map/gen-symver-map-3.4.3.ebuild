# $Header: $

EAPI=5

DESCRIPTION="TODO"
HOMEPAGE="http://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI="http://registrationcenter.intel.com/irc_nas/3778/mpss-src-${PV}.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_install() {
	mkdir -p ${D}/usr/bin
	cp ${WORKDIR}/${P}/${PN} ${D}/usr/bin
}
