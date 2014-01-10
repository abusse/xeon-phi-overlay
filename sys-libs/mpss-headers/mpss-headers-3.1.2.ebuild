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
	unpack ./mpss-${PV}/src/mpss-modules-${PV}.tar.bz2
	mv mpss-modules-${PV} ${S}
}

src_compile() { 
	return 0
}

src_install() {
	cd ${S}
	MIC_CARD_ARCH=k1om DESTDIR=${D} make dev_install
}