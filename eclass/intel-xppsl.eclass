# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

XPPSL_VER=${PV#*_p}

if [[ ${XPPSL_VER} =~ ^[0-9]+$ ]]; then
	XPPSL_VER=${XPPSL_VER:0:1}.${XPPSL_VER:1:1}.${XPPSL_VER:2:1}
fi

case ${XPPSL_VER} in
	1.5.3)
		# 1.5.3 is the final XPPSL release.  Intel retired the downloads with
		# the product line, and no copy is on the Internet Archive; this is a
		# mirror of Intel's own download centre, product 27202.
		XPPSL_SRC_URI="https://downloads.bl4ckb0x.de/downloadcenter.intel.com/27202/eng/xppsl-1.5.3-centos7.3.tar";
		XPPSL_HOMPAGE="https://www.intel.com/content/www/us/en/download/19144/27202/intel-xeon-phi-processor-software-x200.html"
		;;
	*)
		die "No SRC_URI for XPPSL version ${XPPSL_VER}!"
esac
