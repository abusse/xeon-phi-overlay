# $Header: $

EAPI=5

inherit eutils

DESCRIPTION="TODO"
HOMEPAGE="http://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI="http://registrationcenter.intel.com/irc_nas/3778/mpss-src-${PV}.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="app-text/asciidoc"

src_unpack() {
	[ `uname -m` != "x86_64" ] && die "This tool is for the Xeon Phi host not the card."

	unpack ${A}
	unpack ./mpss-${PV}/src/mpss-micmgmt-${PV}.tar.bz2
	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
	mv mpss-micmgmt-${PV} ${P}
	mv mpss-metadata-${PV}/* ${P}
}

src_prepare() {
	sed -i  's/\(mpss-metadata.mk\)/$(REPOROOTDIR)\/\1/' miclib/Makefile || die 'sed failed'
        sed -i  's/\(mpss-metadata.mk\)/$(REPOROOTDIR)\/\1/' miclib_oem/Makefile || die 'sed failed'
}

src_compile() {
	emake lib || die "emake failed"
        emake lib_oem || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install_lib
        emake DESTDIR="${D}" install_lib_oem
}
