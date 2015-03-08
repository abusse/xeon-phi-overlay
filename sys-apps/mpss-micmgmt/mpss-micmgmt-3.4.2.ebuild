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
RDEPEND="=sys-libs/libmicmgmt-${PV}"

src_unpack() {
	[ `uname -m` != "x86_64" ] && die "This tool is for the Xeon Phi host not the card."

	unpack ${A}
	unpack ./mpss-${PV}/src/${P}.tar.bz2

	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
	mv mpss-metadata-${PV}/* ${P}
}

src_prepare() {
        sed -i  's/\(mpss-metadata.mk\)/$(REPOROOTDIR)\/\1/' apps/mpssinfo/Makefile || die 'sed failed'
        sed -i  's/\(mpss-metadata.mk\)/$(REPOROOTDIR)\/\1/' apps/mpssflash/Makefile || die 'sed failed'
        sed -i  's/\(mpss-metadata.mk\)/$(REPOROOTDIR)\/\1/' apps/micsmc/Makefile || die 'sed failed'
#        sed -i  's/\(mpss-metadata.mk\)/$(REPOROOTDIR)\/\1/' apps/micconfig/Makefile || die 'sed failed'

        sed -i  's/-Werror//' apps/mpssinfo/Makefile || die 'sed failed'
        sed -i  's/-Werror//' apps/mpssflash/Makefile || die 'sed failed'
        sed -i  's/-Werror//' apps/micsmc/Makefile || die 'sed failed'
#        sed -i  's/-Werror//' apps/micconfig/Makefile || die 'sed failed'

#        sed -i  's/.*micparse.*//' apps/micconfig/Makefile || die 'sed failed'
}

src_compile() {
        emake all || die "emake failed"
#        emake all_oem || die "emake failed"
}

src_install() {
        emake DESTDIR="${D}" install
#        emake DESTDIR="${D}" install_oem
}

