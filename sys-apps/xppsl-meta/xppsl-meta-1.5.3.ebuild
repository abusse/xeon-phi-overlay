# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="The Intel Xeon Phi Processor Software for Linux (Knights Landing)"
HOMEPAGE="https://www.intel.com/content/www/us/en/download/19144/27202/intel-xeon-phi-processor-software-x200.html"
S="${WORKDIR}"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="=sys-apps/xppsl-micperf-${PV}
	=sys-apps/xppsl-systools-sb-${PV}
	=sys-kernel/xppsl-zonesort-${PV}
	=sys-libs/xppsl-memkind-${PV}
	sys-apps/hwloc"
