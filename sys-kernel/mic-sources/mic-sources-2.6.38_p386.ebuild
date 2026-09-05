# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

K_DEBLOB_AVAILABLE="0"
ETYPE="sources"
inherit kernel-2 intel-mpss
detect_version

DESCRIPTION="Full sources of the Linux kernel for the Xeon Phi card"
SRC_URI=${MPSS_SRC_SRC_URI}

KEYWORDS="~amd64"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/linux-${PV%_p*}+mpss${MPSS_VER}.tar.bz2
	mv linux-${PV%_p*}+mpss${MPSS_VER} linux-${PV}-mic

	# kernel/timeconst.pl uses the Perl-4 idiom defined(@array), removed in
	# modern Perl (>=5.22); it aborts the build on a current host.  Patch it so
	# the card kernel builds with today's host Perl.
	pushd linux-${PV}-mic > /dev/null || die
	eapply "${FILESDIR}/mic-sources-${PV}-timeconst-perl.patch"
	popd > /dev/null || die
}
