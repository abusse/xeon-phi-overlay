# $Header: $

EAPI=5

inherit eutils

DESCRIPTION="TODO"
HOMEPAGE="http://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
#SRC_URI="http://registrationcenter.intel.com/irc_nas/3778/mpss-src-${PV}.tar"
SRC_URI="http://registrationcenter.intel.com/irc_nas/6253/mpss-src-3.4.3.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="=sys-libs/mpss-headers-${PV}
	=sys-libs/libscif-${PV}"

src_unpack() {
	[ `uname -m` != "x86_64" ] && die "This is the daemon for the Xeon Phi host not the card"

	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2
}

src_prepare() {
	epatch "${FILESDIR}/${P}.patch"
}

src_install() {
	einstall

	doenvd ${FILESDIR}/90mpssd || die
	doinitd ${FILESDIR}/mpss || die
}
