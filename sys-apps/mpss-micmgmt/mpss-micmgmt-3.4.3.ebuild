# $Header: $

EAPI=5

inherit eutils

DESCRIPTION="TODO"
HOMEPAGE="http://software.intel.com/en-us/articles/intel-manycore-platform-software-stack-mpss"
SRC_URI="http://registrationcenter.intel.com/irc_nas/3778/mpss-src-${PV}.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="=sys-libs/mpss-headers-${PV}
	=sys-libs/libscif-${PV}"

src_unpack() {
	[ `uname -m` != "x86_64" ] && die "This tool is for the Xeon Phi host not the card."

    unpack $A
	unpack ./mpss-${PV}/src/${P}.tar.bz2
	unpack ./mpss-${PV}/src/mpss-metadata-${PV}.tar.bz2
    for d in $WORKDIR/$P/apps/* $WORKDIR/$P/miclib
    do
        cp $WORKDIR/mpss-metadata-$PV/mpss-metadata.* $d
        sed -E 's:^INCDIR (.*)$:INCDIR \1 -I$(REPOROOTDIR)/miclib/include: ; s:-Werror::' -i $d/Makefile
        sed -E 's:^EXTRA_CFLAGS (.*)$:EXTRA_CFLAGS \1 -L$(REPOROOTDIR)/miclib/libs:' -i $d/Makefile
        sed -E 's:^EXTRA_CPPFLAGS (.*)$:EXTRA_CPPFLAGS \1 -L$(REPOROOTDIR)/miclib/libs:' -i $d/Makefile
    done
    mkdir $WORKDIR/$P/miclib/src/mic
}

src_compile() {
	make lib
	make install_lib
	make
	make install
}

src_install() {
	make DESTDIR=${D} install
	dolib.so miclib/libs/libmicmgmt.so
	dosym libmicmgmt.so /usr/$(get_libdir)/libmicmgmt.so.0
}

