# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic gnuconfig multilib toolchain-funcs intel-mpss

DESCRIPTION="The GNU Compiler Collection with Intel's k1om (Xeon Phi) support"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"
SLOT="5.1.1"
KEYWORDS="~amd64"
IUSE="+cxx fortran openmp"

# ::gentoo's toolchain.eclass refuses anything older than GCC 8
# ("tc_version_is_at_least 8 || die"), so this ebuild drives the build itself.
# It only aims at the cross case, which is all k1om can be.
#
# crossdev sequences the bootstrap purely through USE flags (see
# GUSE_DISABLE_STAGE_1 in /usr/bin/crossdev): the stage1 compiler is emerged
# with -cxx -openmp -fortran and no target libc present.  We detect that the
# same way ::gentoo's eclass does -- by whether the target glibc is installed.

GCC_PV=${PV%_p*}
GCC_CONFIG_VER=${GCC_PV}
GCCMAJOR=$(ver_cut 1 ${GCC_PV})

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi
is_cross() { [[ ${CHOST} != ${CTARGET} ]] ; }

# True while the target C library has not been merged yet: that is crossdev's
# stage1, where GCC must be built without headers and without a shared libgcc.
is_stage1() { is_cross && ! has_version "${CATEGORY}/glibc" ; }

RDEPEND="
	>=sys-devel/gcc-config-2
	dev-libs/gmp:=
	dev-libs/mpc:=
	dev-libs/mpfr:=
	sys-libs/zlib
"
DEPEND="${RDEPEND}
	${CATEGORY}/binutils
"
BDEPEND="
	sys-apps/texinfo
	sys-devel/bison
	sys-devel/flex
"

PATCHES=(
	# KNC has no CMOV; keep "#pragma GCC target" (e.g. <immintrin.h>) from
	# switching it on.
	"${FILESDIR}/${P}-knc-no-cmov.patch"

	# GCC 5's wide-int.h puts a stray "template <>" in front of partial
	# specialisations of binary_traits/int_traits.  That is ill-formed, and
	# every compiler since GCC 6 rejects it outright with "too many
	# template-parameter-lists" -- so no host compiler still in ::gentoo can
	# build this without the fix.  Upstream removed the same lines in GCC 6.
	"${FILESDIR}/${P}-wide-int-cxx11.patch"

	# The C++ front end declares libc_name_p() as plain __inline but defines it
	# with __attribute__((__gnu_inline__)), which a modern g++ rejects outright:
	# "redeclared inline with 'gnu_inline' attribute".  Make the declaration
	# match the definition, as upstream did.  Only bites at stage2, when the
	# C++ front end is actually built.
	"${FILESDIR}/${P}-cfns-gnu-inline.patch"
)

MY_P="gcc-${GCC_PV}+mpss${MPSS_VER}"
S="${WORKDIR}/${MY_P}"
MY_BUILDDIR="${WORKDIR}/build"

# The Gentoo toolchain layout.  Note LIBPATH is /usr/lib (not $(get_libdir)),
# matching ::gentoo's toolchain.eclass and the other crossdev targets.
tc_setup_paths() {
	LIBPATH=/usr/lib/gcc/${CTARGET}/${GCC_CONFIG_VER}
	BINPATH=/usr/${CHOST}/${CTARGET}/gcc-bin/${GCC_CONFIG_VER}
	DATAPATH=/usr/share/gcc-data/${CTARGET}/${GCC_CONFIG_VER}
	STDCXX_INCDIR=${LIBPATH}/include/g++-v${GCCMAJOR}
}

src_unpack() {
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/${MY_P}.tar.bz2
}

src_prepare() {
	default

	gnuconfig_update

	mkdir -p "${MY_BUILDDIR}" || die
}

src_configure() {
	tc_setup_paths

	local confgcc=()

	# GCC 5's gcc/wide-int.h is rejected outright by GCC >= 11 with "too many
	# template-parameter-lists", and a cross build does not bootstrap, so the
	# host compiler compiles these sources directly.  Building GCC 5 with
	# GCC <= 10 is the well-trodden combination, so pick the newest installed
	# slot that still accepts it.  This only affects the compiler that builds
	# GCC; the resulting k1om cross compiler is unaffected.
	if [[ $(gcc-major-version) -ge 11 ]] ; then
		local d v best= best_v=0
		for d in "${EPREFIX}"/usr/${CHOST}/gcc-bin/* ; do
			[[ -x ${d}/g++ && -x ${d}/gcc ]] || continue
			v=$("${d}"/g++ -dumpversion 2>/dev/null)
			v=${v%%.*}
			[[ -n ${v} ]] || continue
			(( v >= 11 )) && continue
			if (( v > best_v )) ; then
				best=${d}
				best_v=${v}
			fi
		done

		if [[ -z ${best} ]] ; then
			eerror "GCC ${GCC_PV} cannot be built by GCC $(gcc-major-version)."
			eerror "Install a slot <= 10, e.g.:"
			eerror "    emerge -1 '=sys-devel/gcc-10*'"
			die "no host compiler old enough to build GCC ${GCC_PV}"
		fi

		einfo "Building GCC ${GCC_PV} with the GCC ${best_v} slot in ${best}"
		export CC="${best}"/gcc
		export CXX="${best}"/g++
		export CPP="${best}"/cpp
	fi

	append-cflags -fcommon
	append-cflags $(test-flags-CC -Wno-error=implicit-function-declaration)
	append-cflags $(test-flags-CC -Wno-error=implicit-int)

	local langs="c"

	if is_stage1 ; then
		# No target headers or libc yet: build just enough C compiler to
		# compile glibc with.
		confgcc+=(
			--without-headers
			--disable-shared
			--disable-threads
			--disable-libgomp
			--disable-libssp
			--disable-libquadmath
			--disable-libatomic
			--disable-libsanitizer
			--disable-libitm
			--disable-libvtv
			--disable-libcilkrts
			--disable-libmpx
			--disable-decimal-float
			--disable-libstdcxx
		)
		ewarn "No ${CATEGORY}/glibc yet -- building the stage1 C compiler."
	else
		use cxx && langs+=",c++"
		use fortran && langs+=",fortran"

		is_cross && confgcc+=( --with-sysroot="${EPREFIX}"/usr/${CTARGET} )
		confgcc+=(
			--enable-shared
			--enable-threads=posix
			--enable-__cxa_atexit
			$(use_enable openmp libgomp)
			--disable-libsanitizer
			--disable-libcilkrts
			--disable-libmpx
			--disable-libitm
			--disable-libvtv
		)
	fi

	# The card is a single ABI; there is no 32-bit k1om multilib.
	confgcc+=( --disable-multilib )

	# Translations would land in the native /usr/share/locale and collide
	# with sys-devel/gcc, exactly as they did for binutils.
	confgcc+=( --disable-nls )

	# texinfo >= 7 rejects this vintage's markup; --force still writes usable
	# output, and the wrapper keeps a non-zero exit from failing the build.
	cat > "${T}"/makeinfo <<-EOF || die
		#!/bin/sh
		makeinfo --force --no-validate "\$@"
		exit 0
	EOF
	chmod +x "${T}"/makeinfo || die
	export MAKEINFO="${T}"/makeinfo

	confgcc+=(
		--prefix="${EPREFIX}"/usr
		--bindir="${EPREFIX}"${BINPATH}
		--includedir="${EPREFIX}"${LIBPATH}/include
		--libdir="${EPREFIX}"${LIBPATH}
		# NOT ${LIBPATH}: GCC derives its tool search path from libexecdir as
		# ${libexecdir}/gcc/${target}/[${version}/], and that is exactly where
		# binutils-config publishes as and ld.  Pointing libexecdir at LIBPATH
		# makes GCC search a doubled path, miss them, and fall back to the
		# bare "as" on PATH -- i.e. the *native* binutils, which has long since
		# dropped k1om, so every compile dies with "invalid -march= option".
		--libexecdir="${EPREFIX}"/usr/libexec
		--datadir="${EPREFIX}"${DATAPATH}
		--mandir="${EPREFIX}"${DATAPATH}/man
		--infodir="${EPREFIX}"${DATAPATH}/info
		--with-gxx-include-dir="${EPREFIX}"${STDCXX_INCDIR}
		--build=${CBUILD:-${CHOST}}
		--host=${CHOST}
		--target=${CTARGET}
		--enable-languages=${langs}
		--enable-obsolete
		--enable-secureplt
		--with-system-zlib
		--with-pkgversion="MPSS ${MPSS_VER}"
		--disable-werror
		--disable-bootstrap
		--disable-libunwind-exceptions
	)

	cd "${MY_BUILDDIR}" || die
	ECONF_SOURCE="${S}" econf "${confgcc[@]}"
}

src_compile() {
	cd "${MY_BUILDDIR}" || die
	if is_stage1 ; then
		emake all-gcc all-target-libgcc
	else
		emake
	fi
}

src_install() {
	tc_setup_paths

	cd "${MY_BUILDDIR}" || die

	if is_stage1 ; then
		emake DESTDIR="${D}" install-gcc install-target-libgcc
	else
		emake DESTDIR="${D}" install
	fi

	# A native compiler built on another machine ran fixincludes over the
	# build machine's /usr/include; keep only GCC's own limits headers.
	if ! is_cross && tc-is-cross-compiler ; then
		local fixed
		while IFS= read -r -d '' fixed ; do
			find "${fixed}" -mindepth 1 ! -name limits.h ! -name syslimits.h ! -name README -delete || die
		done < <(find "${ED}" -type d -name include-fixed -print0)
	fi

	# gcc-config expects the driver under BINPATH without the target prefix
	# too, so both ${CTARGET}-gcc and gcc resolve.
	if [[ -d ${ED}${BINPATH} ]] ; then
		local x
		cd "${ED}${BINPATH}" || die
		for x in ${CTARGET}-* ; do
			[[ -f ${x} ]] || continue
			[[ -e ${x#${CTARGET}-} ]] || ln -s "${x}" "${x#${CTARGET}-}" || die
		done
	fi

	# env.d entry so gcc-config can select this compiler
	insinto /etc/env.d/gcc
	cat <<-EOF > "${T}"/env.d || die
		GCC_PATH="${EPREFIX}${BINPATH}"
		LDPATH="${EPREFIX}${LIBPATH}"
		MANPATH="${EPREFIX}${DATAPATH}/man"
		INFOPATH="${EPREFIX}${DATAPATH}/info"
		STDCXX_INCDIR="g++-v${GCCMAJOR}"
		CTARGET="${CTARGET}"
		GCC_SPECS=""
		MULTIOSDIRS="."
	EOF
	newins "${T}"/env.d ${CTARGET}-${GCC_CONFIG_VER}

	# Would collide with the native compiler's docs.
	rm -f "${ED}"/usr/share/info/dir 2>/dev/null
	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	gcc-config ${CTARGET}-${GCC_CONFIG_VER}
}
