# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: intel-sdp.eclass
# @MAINTAINER:
# Anselm Busse
# @SUPPORTED_EAPIS: 8
# @BLURB: Install Intel's classic Software Development Products from their RPM tarballs
# @DESCRIPTION:
# Handling of Intel's classic Parallel Studio XE / Composer XE products, which ship as a
# single tarball of component RPMs.  The eclass picks the requested RPMs out of the
# tarball, extracts them into the image and registers them in Intel's product database.
# It is RESTRICT="fetch": the tarball must be placed in ${DISTDIR} by hand (pkg_nofetch).

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI=${EAPI:-0} is not supported" ;;
esac

if [[ -z ${_INTEL_SDP_ECLASS} ]]; then
_INTEL_SDP_ECLASS=1

# @ECLASS_VARIABLE: INTEL_DID
# @DEFAULT_UNSET
# @DESCRIPTION:
# Intel's numeric download id for the product.  Only used to reconstruct the (dead)
# historical SRC_URI, which in turn fixes the distfile name the user must supply.

# @ECLASS_VARIABLE: INTEL_DPN
# @DEFAULT_UNSET
# @DESCRIPTION:
# Intel's download product name, e.g. ``parallel_studio_xe``.

# @ECLASS_VARIABLE: INTEL_DPV
# @DEFAULT_UNSET
# @DESCRIPTION:
# Intel's download product version, e.g. ``2015_update3``.

# @ECLASS_VARIABLE: INTEL_TARX
# @DESCRIPTION:
# The product tarball extension.
: "${INTEL_TARX:=tgz}"

# @ECLASS_VARIABLE: INTEL_SUBDIR
# @DEFAULT_UNSET
# @DESCRIPTION:
# The sub-directory of /opt/intel the product is installed into.

# @ECLASS_VARIABLE: INTEL_SINGLE_ARCH
# @DESCRIPTION:
# Set to ``false`` for products shipped as one combined tarball rather than separate
# ia32/intel64 tarballs.
: "${INTEL_SINGLE_ARCH:=true}"

# @ECLASS_VARIABLE: INTEL_SKIP_LICENSE
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set, skip the mandatory license check.  Only set this if there is genuinely no fix.

# @ECLASS_VARIABLE: INTEL_RPMS_DIR
# @DESCRIPTION:
# Sub-directory of the tarball that holds the RPMs.
: "${INTEL_RPMS_DIR:=rpm}"

# @ECLASS_VARIABLE: INTEL_X86
# @DESCRIPTION:
# 32bit arch tag as used in the RPM file names.
: "${INTEL_X86:=i486}"

# @ECLASS_VARIABLE: INTEL_BIN_RPMS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Functional names of the multilib (per-arch) RPMs to extract, without version/arch tags,
# e.g. ``compilerproc``.

# @ECLASS_VARIABLE: INTEL_AMD64_RPMS
# @DEFAULT_UNSET
# @DESCRIPTION:
# amd64-only RPMs.  Same syntax as INTEL_BIN_RPMS.

# @ECLASS_VARIABLE: INTEL_X86_RPMS
# @DEFAULT_UNSET
# @DESCRIPTION:
# x86-only RPMs.  Same syntax as INTEL_BIN_RPMS.

# @ECLASS_VARIABLE: INTEL_DAT_RPMS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Arch-independent (noarch) data RPMs.  Same syntax as INTEL_BIN_RPMS.

# @ECLASS_VARIABLE: INTEL_SDP_DB
# @DESCRIPTION:
# Full path to Intel's on-disk product registry.
INTEL_SDP_DB="${EROOT}/opt/intel/intel-sdp-products.db"

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit check-reqs multilib-build

_INTEL_PV1=$(ver_cut 1)
_INTEL_PV2=$(ver_cut 2)
_INTEL_PV3=$(ver_cut 3)
_INTEL_PV4=$(ver_cut 4)
_INTEL_PV=""
[[ -n ${_INTEL_PV4} ]] && _INTEL_PV+="${_INTEL_PV4}-"
[[ -n ${_INTEL_PV1} ]] && _INTEL_PV+="${_INTEL_PV1}"
[[ -n ${_INTEL_PV2} ]] && _INTEL_PV+=".${_INTEL_PV2}"
[[ -n ${_INTEL_PV3} ]] && _INTEL_PV+="-${_INTEL_PV3}"

_INTEL_URI="https://registrationcenter-download.intel.com/irc_nas/${INTEL_DID}/${INTEL_DPN}"

if [[ ${INTEL_SINGLE_ARCH} == true ]]; then
	SRC_URI="
		abi_x86_32? ( ${_INTEL_URI}_${INTEL_DPV}_ia32.${INTEL_TARX} )
		abi_x86_64? ( ${_INTEL_URI}_${INTEL_DPV}_intel64.${INTEL_TARX} )"
else
	SRC_URI="${_INTEL_URI}_${INTEL_DPV}.${INTEL_TARX}"
fi

LICENSE="Intel-SDP"
SLOT="0"
IUSE="examples"

RESTRICT="fetch mirror"

BDEPEND="app-arch/rpm2targz"

_INTEL_SDP_YEAR=${INTEL_DPV%_sp*}
_INTEL_SDP_YEAR=${_INTEL_SDP_YEAR%_update*}

# @ECLASS_VARIABLE: INTEL_SDP_DIR
# @DESCRIPTION:
# Rootless install path of the product under /opt/intel.
INTEL_SDP_DIR="opt/intel/${INTEL_SUBDIR}-${_INTEL_SDP_YEAR:-${_INTEL_PV1}}"
[[ -n ${_INTEL_PV3} ]] && INTEL_SDP_DIR+=".${_INTEL_PV3}"
[[ -n ${_INTEL_PV4} ]] && INTEL_SDP_DIR+=".${_INTEL_PV4}"

# @ECLASS_VARIABLE: INTEL_SDP_EDIR
# @DESCRIPTION:
# Rooted install path of the product (${EROOT}/${INTEL_SDP_DIR}).
INTEL_SDP_EDIR="${EROOT}/${INTEL_SDP_DIR}"

S="${WORKDIR}"

QA_PREBUILT="${INTEL_SDP_DIR}/*"

# @FUNCTION: _isdp_path_exists
# @USAGE: <path ...>
# @INTERNAL
# @DESCRIPTION:
# True if any of the (already glob-expanded) arguments exists.
_isdp_path_exists() {
	local p
	for p in "$@"; do
		[[ -e ${p} ]] && return 0
	done
	return 1
}

# @FUNCTION: _isdp_big-warning
# @USAGE: [pre-check | test-failed]
# @INTERNAL
# @DESCRIPTION:
# Explain the license requirement to the user.
_isdp_big-warning() {
	case ${1} in
		pre-check)
			echo ""
			ewarn "License file not found!"
			;;
		test-failed)
			echo
			ewarn "Function test failed. Most probably due to an invalid license."
			;;
	esac

	echo ""
	ewarn "Make sure you have a valid Intel license for ${PN}."
	ewarn "A node-locked or floating classic license (from before the oneAPI switch)"
	ewarn "is required.  Install the license file into one of:"
	ewarn "    ${INTEL_SDP_EDIR}/licenses/"
	ewarn "    ${EPREFIX}/opt/intel/licenses/"
	ewarn "or point INTEL_LICENSE_FILE at a file or a port@host license server."
	echo ""
}

# @FUNCTION: convert2intel_arch
# @USAGE: <arch>
# @DESCRIPTION:
# Convert a portage abi/arch keyword to Intel's naming (intel64 / ia32).
convert2intel_arch() {
	case $1 in
		amd64|abi_x86_64|*amd64*) echo "intel64" ;;
		x86|abi_x86_32|*x86*)     echo "ia32" ;;
		*) die "Abi '$1' is unsupported" ;;
	esac
}

# @FUNCTION: intel-sdp_pkg_nofetch
# @DESCRIPTION:
# Tell the user which file to place in ${DISTDIR}.
intel-sdp_pkg_nofetch() {
	local f
	einfo "Intel retired these classic products and their download center URLs; they"
	einfo "cannot be fetched automatically.  Obtain the original tarball(s) from your"
	einfo "own backup / license portal and copy into ${DISTDIR}:"
	echo
	for f in ${A}; do
		einfo "    ${f}"
	done
	echo
	einfo "The historical (dead) upstream location was:"
	einfo "    ${_INTEL_URI}_${INTEL_DPV}*.${INTEL_TARX}"
	echo
	einfo "A valid classic Intel license is also required to use the compiler; see the"
	einfo "notes printed during installation."
}

# @FUNCTION: intel-sdp_pkg_pretend
# @DESCRIPTION:
# Check for disk space and for a license before doing anything expensive.
intel-sdp_pkg_pretend() {
	local warn=1 dir dirs ret

	: "${CHECKREQS_DISK_BUILD:=256M}"
	check-reqs_pkg_pretend

	if [[ -n ${INTEL_SKIP_LICENSE} ]]; then
		eqawarn "This ebuild does not check for a valid Intel license!"
		return 0
	fi

	if [[ ${INTEL_LICENSE_FILE} == *@* ]]; then
		einfo "Using license server: ${INTEL_LICENSE_FILE}"
		return 0
	fi

	dirs=(
		"${INTEL_SDP_EDIR}/licenses"
		"${INTEL_SDP_EDIR}/Licenses"
		"${EPREFIX}/opt/intel/licenses"
	)
	for dir in "${dirs[@]}"; do
		ebegin "Checking for a license in: ${dir}"
		_isdp_path_exists "${dir}"/*lic
		ret=$?
		eend ${ret}
		if [[ ${ret} == 0 ]]; then
			warn=0
			break
		fi
	done
	if [[ ${warn} == 1 ]]; then
		_isdp_big-warning pre-check
		die "Could not find an Intel license file"
	fi
}

# @FUNCTION: intel-sdp_pkg_setup
# @DESCRIPTION:
# Compute the concrete list of RPM file names to pull out of the tarball.
intel-sdp_pkg_setup() {
	local arch="" a p

	INTEL_ARCH=""
	if use abi_x86_64; then
		arch+=" x86_64"
		INTEL_ARCH+=" intel64"
	fi
	if use abi_x86_32; then
		arch+=" ${INTEL_X86}"
		INTEL_ARCH+=" ia32"
	fi

	INTEL_RPMS=()
	for p in "${INTEL_BIN_RPMS[@]}"; do
		for a in ${arch}; do
			INTEL_RPMS+=( "intel-${p}-${_INTEL_PV}.${a}.rpm" )
		done
	done
	if use amd64; then
		for p in "${INTEL_AMD64_RPMS[@]}"; do
			INTEL_RPMS+=( "intel-${p}-${_INTEL_PV}.x86_64.rpm" )
		done
	fi
	for p in "${INTEL_X86_RPMS[@]}"; do
		INTEL_RPMS+=( "intel-${p}-${_INTEL_PV}.${INTEL_X86}.rpm" )
	done
	for p in "${INTEL_DAT_RPMS[@]}"; do
		INTEL_RPMS+=( "intel-${p}-${_INTEL_PV}.noarch.rpm" )
	done

	[[ ${#INTEL_RPMS[@]} -gt 0 ]] || die "No RPMs selected; set INTEL_*_RPMS"
}

# @FUNCTION: intel-sdp_src_unpack
# @DESCRIPTION:
# Pull the selected RPMs out of the product tarball, convert each to a tar stream and
# extract it, then relocate the resulting tree to INTEL_SDP_DIR.
intel-sdp_src_unpack() {
	local t r rb l list rpmdir log

	for t in ${A}; do
		list=()
		rpmdir="${t%%.*}/${INTEL_RPMS_DIR}"
		for r in "${INTEL_RPMS[@]}"; do
			list+=( "${rpmdir}/${r}" )
		done

		tar xf "${DISTDIR}/${t}" "${list[@]}" &> "${T}/rpm-extraction.log" \
			|| die "extracting RPMs from ${t} failed (see ${T}/rpm-extraction.log)"

		for r in "${list[@]}"; do
			rb=$(basename "${r}")
			[[ -f ${r} ]] || die "expected RPM missing from tarball: ${r}"
			log=".${rb}_$(date +'%d%m%y_%H%M%S').log"
			einfo "Unpacking ${rb}"
			rpm2tar -O "${r}" | tar xvf - > "${log}"
			assert "unpacking ${r} failed"
			mv "${log}" opt/intel/ || die "failed moving extract log file"
		done
	done

	# All components extract into a single opt/intel/<vendor-dir>; the per-RPM logs are
	# dotfiles and are skipped by the glob, so exactly the compiler tree is left to move.
	[[ -d ${INTEL_SDP_DIR} ]] || mkdir -p "$(dirname "${INTEL_SDP_DIR}")" || die
	mv opt/intel/*/ "${INTEL_SDP_DIR}" || die "relocating to INTEL_SDP_DIR failed"
	[[ -d ${INTEL_SDP_DIR} ]] || die "INTEL_SDP_DIR not created: ${INTEL_SDP_DIR}"
}

# @FUNCTION: intel-sdp_src_install
# @DESCRIPTION:
# Trim uninstall/registration cruft, handle docs/examples, retarget the vars scripts to
# the real install location and merge into the image.
intel-sdp_src_install() {
	if _isdp_path_exists "${INTEL_SDP_DIR}"/uninstall*; then
		ebegin "Cleaning out uninstall information"
		find "${INTEL_SDP_DIR}"/uninstall* -delete
		eend $? || die
	fi

	if _isdp_path_exists "${INTEL_SDP_DIR}"/Documentation; then
		dodoc -r "${INTEL_SDP_DIR}"/Documentation/*
		ebegin "Cleaning out documentation"
		find "${INTEL_SDP_DIR}"/Documentation -delete
		eend $? || die
	fi

	if _isdp_path_exists "${INTEL_SDP_DIR}"/Samples; then
		if use examples; then
			insinto /usr/share/${PF}/examples
			doins -r "${INTEL_SDP_DIR}"/Samples/*
		fi
		ebegin "Cleaning out examples"
		find "${INTEL_SDP_DIR}"/Samples -delete
		eend $? || die
	fi

	if _isdp_path_exists "${INTEL_SDP_DIR}"/man; then
		_isdp_path_exists "${INTEL_SDP_DIR}"/man/en_US/man1/* && \
			doman "${INTEL_SDP_DIR}"/man/en_US/man1/*
		_isdp_path_exists "${INTEL_SDP_DIR}"/man/man1/* && \
			doman "${INTEL_SDP_DIR}"/man/man1/*
		find "${INTEL_SDP_DIR}"/man -delete || die
	fi

	ebegin "Retargeting environment scripts to ${INTEL_SDP_EDIR}"
	find opt -name '*sh' -type f -exec sed -i \
		-e "s:<.*DIR>:${INTEL_SDP_EDIR}:g" '{}' +
	eend $? || die

	[[ -d ${ED} ]] || dodir /
	mv opt "${ED}/" || die "moving files into the image failed"

	keepdir "${INTEL_SDP_DIR}"/licenses
}

# @FUNCTION: intel-sdp_pkg_postinst
# @DESCRIPTION:
# Register the extracted RPMs in Intel's product database.
intel-sdp_pkg_postinst() {
	local l r
	for r in "${INTEL_RPMS[@]}"; do
		l=$(ls -1 "${EROOT}"/opt/intel/."${r}"_*.log 2>/dev/null | head -n 1)
		echo >> "${INTEL_SDP_DB}" \
			"<:${r%-${_INTEL_PV4}*}-${_INTEL_PV4}:${r}:${INTEL_SDP_EDIR}:${l}:>"
	done
}

# @FUNCTION: intel-sdp_pkg_postrm
# @DESCRIPTION:
# Drop this product's entries from Intel's product database.
intel-sdp_pkg_postrm() {
	[[ -e ${INTEL_SDP_DB} ]] || return 0
	local r
	for r in "${INTEL_RPMS[@]}"; do
		sed -i -e "/${r}/d" "${INTEL_SDP_DB}"
	done
}

fi

EXPORT_FUNCTIONS pkg_pretend pkg_nofetch pkg_setup src_unpack src_install pkg_postinst pkg_postrm
