# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs flag-o-matic gnuconfig multilib systemd unpacker multiprocessing prefix intel-mpss

DESCRIPTION="GNU libc6 (also called glibc2) C library"
HOMEPAGE="https://www.gnu.org/software/libc/libc.html"

LICENSE="LGPL-2.1+ BSD HPND ISC inner-net rc PCRE"
KEYWORDS="~amd64"
RESTRICT="strip" # strip ourself #46186
EMULTILIB_PKG="true"

# Configuration variables
RELEASE_VER=""

EXTRA_ECONF="--enable-add-ons"
	# see https://sourceware.org/glibc/wiki/Release/2.20 3.2.1

case ${PV} in
9999*)
	EGIT_REPO_URIS="git://sourceware.org/git/glibc.git"
	EGIT_SOURCEDIRS="${S}"
	inherit git-2
	;;
*)
	RELEASE_VER=${PV%_p*}
	;;
esac
GCC_BOOTSTRAP_VER="4.7.3-r1"
NPTL_KERN_VER=${NPTL_KERN_VER:-"2.6.16"}	   # min kernel version nptl requires

IUSE="debug gd hardened multilib nscd selinux systemtap profile suid +vanilla crosscompile_opts_headers-only"

# Here's how the cross-compile logic breaks down ...
#  CTARGET - machine that will target the binaries
#  CHOST   - machine that will host the binaries
#  CBUILD  - machine that will build the binaries
# If CTARGET != CHOST, it means you want a libc for cross-compiling.
# If CHOST != CBUILD, it means you want to cross-compile the libc.
#  CBUILD = CHOST = CTARGET	   - native build/install
#  CBUILD != (CHOST = CTARGET) - cross-compile a native build
#  (CBUILD = CHOST) != CTARGET - libc for cross-compiler
#  CBUILD != CHOST != CTARGET  - cross-compile a libc for a cross-compiler
# For install paths:
#  CHOST = CTARGET	- install into /
#  CHOST != CTARGET - install into /usr/CTARGET/

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi

[[ ${CTARGET} == hppa* ]] && NPTL_KERN_VER=${NPTL_KERN_VER/2.6.16/2.6.20}

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}

# Why SLOT 2.2 you ask yourself while sippin your tea ?
# Everyone knows 2.2 > 0, duh.
SLOT="2.2"

# General: We need a new-enough binutils/gcc to match upstream baseline.
# arch: we need to make sure our binutils/gcc supports TLS.
DEPEND=">=app-misc/pax-utils-0.1.10
	!<sys-apps/sandbox-1.6
	!<sys-apps/portage-2.1.2
	selinux? ( sys-libs/libselinux )"
RDEPEND="!sys-kernel/ps3-sources
	selinux? ( sys-libs/libselinux )
	!sys-libs/nss-db"

if [[ ${CATEGORY} == cross-* ]] ; then
	DEPEND+=" !crosscompile_opts_headers-only? (
		>=${CATEGORY}/binutils-2.20
		>=${CATEGORY}/gcc-4.3
	)"
	[[ ${CATEGORY} == *-linux* ]] && DEPEND+=" ${CATEGORY}/linux-headers"
else
	DEPEND+="
		>=sys-devel/binutils-2.20
		>=sys-devel/gcc-4.3
		virtual/os-headers
		!vanilla? ( >=sys-libs/timezone-data-2012c )"
	RDEPEND+="
		vanilla? ( !sys-libs/timezone-data )
		!vanilla? ( sys-libs/timezone-data )"
fi

upstream_uris() {
	echo mirror://gnu/glibc/$1 ftp://sourceware.org/pub/glibc/{releases,snapshots}/$1 mirror://gentoo/$1
}
gentoo_uris() {
	local devspace="HTTP~vapier/dist/URI HTTP~azarah/glibc/URI"
	devspace=${devspace//HTTP/https://dev.gentoo.org/}
	echo mirror://gentoo/$1 ${devspace//URI/$1}
}
SRC_URI=$(
	echo ${MPSS_SRC_SRC_URI}
	[[ -n ${PATCH_VER}		]] && gentoo_uris ${P%_p*}-patches-${PATCH_VER}.tar.bz2
)
SRC_URI+=" ${GCC_BOOTSTRAP_VER:+multilib? ( $(gentoo_uris gcc-${GCC_BOOTSTRAP_VER}-multilib-bootstrap.tar.bz2) )}"

# eblit-include [--skip] <function> [version]
eblit-include() {
	local skipable=false
	[[ $1 == "--skip" ]] && skipable=true && shift
	[[ $1 == pkg_* ]] && skipable=true

	local e v func=$1 ver=$2
	[[ -z ${func} ]] && die "Usage: eblit-include <function> [version]"
	for v in ${ver:+-}${ver} -${PVR} -${PV} "" ; do
		e="${FILESDIR}/eblits/${func}${v}.eblit"
		if [[ -e ${e} ]] ; then
			source "${e}"
			return 0
		fi
	done
	${skipable} && return 0
	die "Could not locate requested eblit '${func}' in ${FILESDIR}/eblits/"
}

# eblit-run-maybe <function>
# run the specified function if it is defined
eblit-run-maybe() {
	[[ $(type -t "$@") == "function" ]] && "$@"
}

# eblit-run <function> [version]
# aka: src_unpack() { eblit-run src_unpack ; }
eblit-run() {
	eblit-include --skip common "${*:2}"
	eblit-include "$@"
	eblit-run-maybe eblit-$1-pre
	eblit-${PN}-$1
	eblit-run-maybe eblit-$1-post
}

src_unpack()  { eblit-run src_unpack  ; }
# Under EAPI 0/1 the eblits folded prepare and configure into unpack/compile
# (see their "${EAPI:-0} == [01]" guards) and the ebuild declared neither phase.
# At EAPI 8 those are separate phases, so without these portage would run the
# *default* src_prepare/src_configure -- and the default econf cannot configure
# glibc. src_{prepare,configure}.eblit already provide the real implementations.
src_prepare()   { eblit-run src_prepare   ; }
src_configure() { eblit-run src_configure ; }
src_compile() { eblit-run src_compile ; }
src_test()	  { eblit-run src_test	  ; }
src_install() { eblit-run src_install ; }

# Cross-build adjustments.
#
# These cannot live in pkg_setup: FILESDIR is not populated yet when it runs, so
# the pkg_* eblits are never sourced and no pkg_setup hook of ours would fire.
# They also cannot be done once in src_configure and relied on afterwards --
# portage re-applies CFLAGS from the package config at the start of every phase,
# so a filter-flags in src_configure is gone again by src_compile (which is
# exactly how -march=native kept reaching the k1om assembler).  Apply them at
# the start of each phase that needs them instead.
mpss_cross_setup() {
	# The host's CFLAGS are not valid for the target. In particular a
	# -march=native from the build host resolves against *its* CPU, and the
	# resulting instructions are rejected outright by the k1om assembler
	# ("Error: `cmove' is not supported on `k1om'") -- KNC's in-order core has
	# no cmov. Let the k1om compiler use its own default arch.
	if [[ ${CATEGORY} == cross-* ]] ; then
		# setup_flags() in common.eblit caches the incoming CFLAGS in
		# CFLAGS_BASE on its first call and restores CFLAGS from it on every
		# later call.  That cache is populated by an earlier phase (src_prepare)
		# before any hook of ours runs, and portage carries it across phases in
		# the saved environment -- so filtering CFLAGS alone is undone again the
		# moment setup_flags runs.  Drop the caches so they are re-derived from
		# the filtered flags.
		unset CFLAGS_BASE CXXFLAGS_BASE ASFLAGS_BASE

		filter-flags '-march=*' '-mtune=*' '-mcpu=*'

		# glibc's configure probes the compiler for -fstack-protector and, on
		# success, sets have-ssp=yes in config.make and adds the flag from
		# inside its own build system -- after the ebuild has filtered CFLAGS,
		# so filtering cannot prevent it.  libresolv.so then fails to link with
		# "undefined reference to __stack_chk_guard".  Pre-seed the configure
		# cache instead; SSP is not useful for a coprocessor cross libc.
		export libc_cv_ssp=no

		# DT_RELR postdates binutils 2.22 by a decade.  Its ld does not fail
		# on "-z pack-relative-relocs" -- it prints "warning: -z
		# pack-relative-relocs ignored" and exits 0 -- so
		# strip-unsupported-flags probes it as supported and keeps it.  The
		# warning is enough to throw glibc's own link steps off: libc.so then
		# dies with __libc_freeres_fn "defined in discarded section", a BFD
		# assertion in elf64-x86-64.c, and "Nonrepresentable section on
		# output".  It only shows up when this package is emerged directly;
		# crossdev builds it with LDFLAGS emptied, which is why the toolchain
		# came up clean.
		filter-ldflags '-Wl,-z,pack-relative-relocs' '-z,pack-relative-relocs'
	fi

	# glibc 2.14 (2011) does not build under GNU Make 4.4: the elf/rtld-Rules
	# recursion wedges, with the string/csu/nptl sub-makes stuck in R state
	# burning CPU, no compiler running and nothing written.  It looks like a
	# slow build rather than a hang.  --jobserver-style=pipe does NOT help --
	# it is not the 4.4 jobserver change.  Use a pre-4.4 make instead.
	local oldmake
	for oldmake in /opt/make-4.3/bin/make /usr/bin/make-4.3 /usr/bin/make-4.2 ; do
		[[ -x ${oldmake} ]] || continue
		mkdir -p "${T}"/make-shim || die
		ln -sf "${oldmake}" "${T}"/make-shim/make || die
		export PATH="${T}/make-shim:${PATH}"
		einfo "Using $(${oldmake} --version | head -1) for glibc"
		break
	done

	if [[ $(make --version 2>/dev/null | head -1) == *" 4.4"* ]] ; then
		eerror "GNU Make 4.4 cannot build glibc ${PV%_p*}; the build wedges in"
		eerror "elf/rtld-Rules. Install a pre-4.4 make, e.g.:"
		eerror "    cd /var/tmp && wget https://ftp.gnu.org/gnu/make/make-4.3.tar.gz"
		eerror "    tar xf make-4.3.tar.gz && cd make-4.3"
		eerror "    ./configure --prefix=/opt/make-4.3 && make && make install"
		eerror "(make 4.2.1 is not an option: its bundled glob.c no longer builds.)"
		die "need a pre-4.4 GNU make"
	fi
}

eblit-src_prepare-pre()   { mpss_cross_setup ; }
eblit-src_configure-pre() { mpss_cross_setup ; }
eblit-src_compile-pre()   { mpss_cross_setup ; }
eblit-src_install-pre()   { mpss_cross_setup ; }

# These must be sourced at global scope: FILESDIR is not populated yet when
# pkg_setup runs, so a lazy eblit-include finds nothing and the phase dies with
# "eblit-glibc-pkg_setup: command not found" (upstream also noted FILESDIR may
# be missing during a binpkg install).  Doing it unconditionally, though, also
# runs them in the depend phase, where the sandbox forbids writes and portage
# aborts before the build starts -- so skip exactly that phase.  Per-package
# customisation lives in the eblit-*-pre hooks, which eblit-run calls for us.
if [[ ${EBUILD_PHASE} != depend ]] ; then
	for x in setup {pre,post}inst ; do
		e="${FILESDIR}/eblits/pkg_${x}.eblit"
		if [[ -e ${e} ]] ; then
			. "${e}"
			eval "pkg_${x}() { eblit-run pkg_${x} ; }"
		fi
	done
fi

eblit-src_unpack-pre() {
	use vanilla || die "Xeon Phi toolchain only supports a vanilla build!"
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/glibc-${PV%_p*}+mpss${MPSS_VER}.tar.bz2
	mv "glibc-${PV%_p*}+mpss${MPSS_VER}" "${S}"
}

eblit-pkg_preinst-post() {
	if [[ ${CTARGET} == arm* ]] ; then
		# Backwards compat support for renaming hardfp ldsos #417287
		local oldso='/lib/ld-linux.so.3'
		local nldso='/lib/ld-linux-armhf.so.3'
		if [[ -e ${D}${nldso} ]] ; then
			if scanelf -qRyi "${ROOT}$(alt_prefix)"/*bin/ | grep -s "^${oldso}" ; then
				ewarn "Symlinking old ldso (${oldso}) to new ldso (${nldso})."
				ewarn "Please rebuild all packages using this old ldso as compat"
				ewarn "support will be dropped in the future."
				ln -s "${nldso##*/}" "${D}$(alt_prefix)${oldso}"
			fi
		fi
	fi
}
