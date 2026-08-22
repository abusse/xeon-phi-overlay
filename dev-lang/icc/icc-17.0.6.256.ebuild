# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit check-reqs

MY_TARBALL="intel-compilers_and_libraries_2017.6.256-icc-icpc-ifort.tar.xz"
DESCRIPTION="Intel C/C++ Compiler (classic icc)"
HOMEPAGE="https://www.intel.com/content/www/us/en/developer/tools/oneapi/dpc-compiler.html"
SRC_URI="https://distfiles.invalid/xeon-phi-overlay/${MY_TARBALL}"

LICENSE="Intel-SDP"
SLOT="17"
KEYWORDS="-* ~amd64"

# Prebuilt Intel binaries.
RESTRICT="fetch mirror strip binchecks"

S="${WORKDIR}"

INTEL_SDP_EDIR="${EROOT}/opt/intel/compilers_and_libraries_2017.6.256"
QA_PREBUILT="opt/intel/*"

CHECKREQS_DISK_BUILD=3G

pkg_nofetch() {
	einfo "Place the tarball into ${DISTDIR}:"
	einfo "    ${MY_TARBALL}"
}

pkg_pretend() {
	check-reqs_pkg_pretend

	if [[ ${INTEL_LICENSE_FILE} == *@* ]]; then
		einfo "Using license server: ${INTEL_LICENSE_FILE}"
		return 0
	fi
	local dir found=
	for dir in "${INTEL_SDP_EDIR}"/licenses "${EPREFIX}/opt/intel/licenses"; do
		ebegin "Checking for a license in: ${dir}"
		if compgen -G "${dir}/*lic" > /dev/null 2>&1; then
			eend 0; found=1; break
		fi
		eend 1
	done
	if [[ -z ${found} ]]; then
		ewarn "No Intel license found; install one in /opt/intel/licenses/ or set"
		ewarn "INTEL_LICENSE_FILE before using icc."
		die "Could not find an Intel license file"
	fi
}

src_install() {
	cd "${S}/intel" || die

	rm -rf ism uninstall* *.db licenses || die
	find . -maxdepth 1 -name '.*.log' -delete || die

	dodir /opt/intel
	cp -a . "${ED}/opt/intel/" || die

	keepdir /opt/intel/licenses
}

pkg_postinst() {
	elog "Set up your environment before use:"
	elog "    source ${INTEL_SDP_EDIR}/linux/bin/compilervars.sh intel64"
	elog "A valid classic Intel license must be present, e.g. in"
	elog "${EPREFIX}/opt/intel/licenses/ (searched by default)."
}
