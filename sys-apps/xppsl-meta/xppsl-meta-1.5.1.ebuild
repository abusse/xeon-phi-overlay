# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="The Intel Xeon Phi Processor Software for Linux (Knights Landing)"
HOMEPAGE="https://software.intel.com/en-us/articles/xeon-phi-software"
SRC_URI=""

SLOT="0"
KEYWORDS="~amd64"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="=sys-apps/xppsl-micperf-${PV}
	 =sys-apps/xppsl-systools-sb-${PV}
	 =sys-kernel/xppsl-zonesort-${PV}
	 =sys-libs/xppsl-memkind-${PV}
	 =sys-apps/xppsl-hwloc-1.11.5_p151"
