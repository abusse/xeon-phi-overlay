# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic toolchain-funcs rpm intel-xppsl

DESCRIPTION="Performance benchmarks for the Intel Xeon Phi X200 Processor (Knights Landing)."
HOMEPAGE="${XPPSL_HOMPAGE}"
SRC_URI="${XPPSL_SRC_URI}"

LICENSE="Intel-XPPSL"
SLOT="0"
KEYWORDS="~amd64"
# These benchmarks were written for the Intel compiler, which is what upstream
# tuned them with.  Classic icc is not in ::gentoo, but the natinst overlay
# packages the free oneAPI classic compiler (which still targets KNL via
# -xMIC-AVX512), so USE=icc pulls that.  Off by default: the GCC path needs no
# extra overlay and already produces working KNL AVX-512 code.
IUSE="icc"

# micp is a Python 2 package and was never ported upstream, so depend on the
# 2.7 slot directly -- python-single-r1 treats python2_7 as historical and
# refuses it.
RDEPEND="sys-libs/xppsl-memkind
	sys-apps/dmidecode
	sys-process/numactl
	dev-lang/python:2.7
	virtual/mpi
	icc? (
		intel-oneapi/intel_oneapi_compiler_dpcpp_cpp_and_cpp_classic_202130
		intel-oneapi/intel_oneapi_mkl_devel_202130
	)
	!icc? ( sci-libs/mkl[gnu-openmp] )"
DEPEND="${RDEPEND}"

PATCHES=( "${FILESDIR}"/${P}-build-without-icc.patch )

S="${WORKDIR}/${P}"

src_unpack() {
	unpack ${A}
	srcrpm_unpack $(find . -name ${P}-*.src.rpm)
}

src_prepare() {
	default

	# shoc_download and shoc_readback are not supported on KNL SB
	rm "${S}"/micp/micp/kernels/shoc_download.py || die
	rm "${S}"/micp/micp/kernels/shoc_readback.py || die
	rm "${S}"/ut/micp_ut/micp_kernels_shoc_test.py || die

	sed -i 's/python/python2/g' "${S}"/micp/Makefile || die
	local f
	while IFS= read -r -d '' f ; do
		sed -i -e 's:\(#!/usr/bin/env python\)$:\12:' "${f}" || die
	done < <(find "${S}" -type f -print0)
}

# @FUNCTION: micperf_knl_cc
# @DESCRIPTION:
# Echo a compiler that can still target Knights Landing.  GCC deprecated
# -march=knl in 12 and removed it in 15, so the current compiler is often not
# one; fall back through the installed slots before giving up.
micperf_knl_cc() {
	local cc
	for cc in "$(tc-getCC)" {x86_64-pc-linux-gnu-,}gcc-{14..10} ; do
		type -P "${cc}" >/dev/null || continue
		echo 'int main(void){return 0;}' \
			| ${cc} -march=knl -x c - -o /dev/null &>/dev/null || continue
		echo "${cc}"
		return 0
	done
	return 1
}

# @FUNCTION: micperf_make_args
# @DESCRIPTION:
# Fill micperf_args[] with the make variables for the selected compiler.  Both
# src_compile and src_install need them: install-knlsb lists the binaries as
# prerequisites, so with the wrong variables it would try to rebuild them.
micperf_make_args() {
	local mklroot
	if use icc ; then
		# Match the compiler era.  Only the 2021.x MKL still carries the
		# KNL-tuned GEMM kernels (libmkl_avx512_mic) and the Intel threading
		# layer (libmkl_intel_thread) that icc pairs with; the newest MKL has
		# dropped both, so a 2026 MKL here would link against gnu threading and
		# run a generic AVX-512 GEMM instead of the Knights Landing one.
		mklroot="${EPREFIX}/opt/intel/oneapi/mkl/2021.3.0"
	else
		mklroot="${EPREFIX}/opt/intel/oneapi/mkl/latest"
	fi
	[[ -f ${mklroot}/include/mkl.h ]] || die "cannot find MKL under ${mklroot}"

	micperf_args=(
		VERSION="${PV}"
		MKLROOT="${mklroot}"
		DYNAMIC=yes
		# mkl_conv wants mkl_dnn.h -- MKL-DNN, which Intel moved out of MKL into
		# oneDNN and no longer ships.  No compiler choice brings it back.
		CONV_TARGETS="libxsmm_conv"
		CONV_INSTALL_TARGETS="libxsmm_conv_install"
	)

	if use icc ; then
		# The oneAPI classic compiler (from the natinst overlay) is not on PATH;
		# it runs with just its bin dir on PATH and its runtime libs on
		# LD_LIBRARY_PATH -- no need to source the full setvars.sh.  The exports
		# persist into the emake in src_compile/src_install because this runs in
		# the same shell.
		local iccroot="${EPREFIX}/opt/intel/oneapi/compiler/latest/linux"
		[[ -x ${iccroot}/bin/intel64/icc ]] || die "oneAPI icc not found under ${iccroot}"
		export PATH="${iccroot}/bin/intel64:${PATH}"
		export LD_LIBRARY_PATH="${iccroot}/compiler/lib/intel64_lin:${iccroot}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

		# Classic icc 2021.3 advertises the installed GCC's version (GCC 15 here)
		# and then cannot parse glibc's GCC-11+ two-argument
		# __malloc__(dealloc, argno) annotations: "attribute __malloc__ does not
		# take arguments".  Point it at a GCC older than 11 so glibc omits those
		# annotations.  Done through a config file (ICCCFG/ICPCCFG) so it applies
		# to every icc invocation, including the ones mpicc makes for the SNC
		# targets.
		local basecc
		for basecc in {x86_64-pc-linux-gnu-,}gcc-1{0,} {x86_64-pc-linux-gnu-,}gcc-9 ; do
			type -P "${basecc}" >/dev/null && break || basecc=
		done
		[[ -n ${basecc} ]] || die "icc needs a GCC older than 11 as its header base (glibc compat); none found"
		printf -- '-gcc-name=%s\n' "$(type -P "${basecc}")" > "${T}"/icc.cfg || die
		export ICCCFG="${T}/icc.cfg" ICPCCFG="${T}/icc.cfg"

		micperf_cc="icc"
		# icc's own spellings.  -qopt-streaming-stores and mkl_intel_thread are
		# the icc-native tunings the benchmarks were written for; -xMIC-AVX512 is
		# the KNL arch flag (validated to emit real AVX-512 in 2021.3).  mpicc
		# still drives the SNC targets, with icc underneath via OMPI_CC.
		micperf_args+=(
			ICC="icc"
			TARGET_ICC="icc"
			ICPC="icpc"
			MPICC="mpicc"
			OPENMP_CFLAGS="-qopenmp"
			# icc defines __INTEL_OFFLOAD by default, which makes the benchmarks
			# #include <offload.h> for KNC coprocessor offload -- a header oneAPI
			# icc no longer ships.  -qno-offload undefines it.
			NO_OFFLOAD_CFLAGS="-qno-offload"
			STREAMING_STORES_CFLAGS="-qopt-streaming-stores always"
			KNL_ARCH_CFLAGS="-xMIC-AVX512"
			MKL_THREAD_LIB="mkl_intel_thread"
			WERROR=
			MATH_LIBS="-lm -ldl"
			LIBXSMM_FC=
			LIBXSMM_ECFLAGS=
		)
		einfo "Building with Intel icc $(icc --version 2>/dev/null | head -1)"
		return 0
	fi

	local mtune
	if micperf_cc=$(micperf_knl_cc) ; then
		mtune="-march=knl"
		einfo "Building for Knights Landing with ${micperf_cc}"
	else
		# AVX-512F and CD are the parts of KNL's ISA that survive; ER and PF
		# went with -march=knl.
		micperf_cc=$(tc-getCC)
		mtune="-mavx512f -mavx512cd"
		ewarn "No compiler here still supports -march=knl."
		ewarn "Falling back to ${mtune}, which is a subset of what KNL implements."
	fi

	# LIBXSMM's C++ bits should come from the same GCC as the C ones.
	local cxx=${micperf_cc/gcc/g++}
	type -P "${cxx}" >/dev/null || cxx=$(tc-getCXX)

	# Only the variables the patch introduces are set here.  Overriding
	# EXTRA_CFLAGS or CPU_CFLAGS instead would silently drop the MKL include
	# path, because gemm assigns those per target and a command-line variable
	# outranks a target-specific assignment.
	micperf_args+=(
		ICC="${micperf_cc}"
		TARGET_ICC="${micperf_cc}"
		ICPC="${cxx}"
		MPICC="mpicc"
		OPENMP_CFLAGS="-fopenmp"
		NO_OFFLOAD_CFLAGS=
		STREAMING_STORES_CFLAGS=
		KNL_ARCH_CFLAGS="${mtune}"
		MKL_THREAD_LIB="mkl_gnu_thread"
		WERROR=
		MATH_LIBS="-lm -ldl"
		LIBXSMM_FC=
		LIBXSMM_ECFLAGS="-fcommon"
	)
}

src_compile() {
	# The makefiles put their own arch flag first and the environment's CFLAGS
	# after it, so a host -march=native silently wins and the benchmarks come
	# out built for the build machine instead of the card.
	filter-flags '-march=*' '-mtune=*' '-mcpu=*'

	local micperf_cc
	local -a micperf_args
	micperf_make_args

	# mpicc drives the SNC targets and has to use the same compiler.
	OMPI_CC="${micperf_cc}" MPICH_CC="${micperf_cc}" emake "${micperf_args[@]}" knlsb
}

src_install() {
	local micperf_cc
	local -a micperf_args
	micperf_make_args

	emake DESTDIR="${D}" "${micperf_args[@]}" install-knlsb
}
