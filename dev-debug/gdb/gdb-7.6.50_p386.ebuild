# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic strip-linguas intel-mpss

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi
is_cross() { [[ ${CHOST} != ${CTARGET} ]] ; }

RPM=
MY_PV=${PV}

SRC_URI=${MPSS_SRC_SRC_URI}

DESCRIPTION="GNU debugger"
HOMEPAGE="https://sourceware.org/gdb/"

LICENSE="GPL-2 LGPL-2"
SLOT="0"
if [[ ${PV} != 9999* ]] ; then
	KEYWORDS="~amd64"
fi
IUSE="+client expat lzma multitarget nls +server test +vanilla zlib"
REQUIRED_USE="
	|| ( client server )
"

RDEPEND="server? ( !dev-util/gdbserver )
	client? (
		>=sys-libs/ncurses-5.2-r2:0=
		sys-libs/readline:0=
		expat? ( dev-libs/expat )
		lzma? ( app-arch/xz-utils )
		zlib? ( sys-libs/zlib )
	)"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	client? (
		app-alternatives/yacc
		test? ( dev-util/dejagnu )
		nls? ( sys-devel/gettext )
	)"

S=${WORKDIR}/${PN}-${MY_PV}

src_unpack() {
	use vanilla || die "Xeon Phi toolchain only supports a vanilla build!"
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/gdb-${PV%_p*}+mpss${MPSS_VER}.tar.bz2
	mv "gdb-${PV%_p*}+mpss${MPSS_VER}" "${S}"
}

src_prepare() {
	default
	strip-linguas -u bfd/po opcodes/po
}

gdb_branding() {
	printf "Gentoo ${PV} "
	if ! use vanilla && [[ -n ${PATCH_VER} ]] ; then
		printf "p${PATCH_VER}"
	else
		printf "vanilla"
	fi
}

src_configure() {
	strip-unsupported-flags

	# gdb 7.6.50 is from 2013: GCC >= 14 rejects implicit function
	# declarations and implicit int, and >= 10 defaults to -fno-common.
	append-cflags -std=gnu89 -fcommon
	append-cflags $(test-flags-CC -Wno-error=implicit-function-declaration)
	append-cflags $(test-flags-CC -Wno-error=implicit-int)

	# texinfo >= 7 rejects this vintage's markup outright; --force still
	# writes usable .info files and the wrapper keeps a non-zero exit from
	# failing the build over documentation.
	cat > "${T}"/makeinfo <<-EOF || die
		#!/bin/sh
		makeinfo --force --no-validate "\$@"
		exit 0
	EOF
	chmod +x "${T}"/makeinfo || die
	export MAKEINFO="${T}"/makeinfo

	local myconf=(
		--with-pkgversion="$(gdb_branding)"
		--with-bugurl='https://bugs.gentoo.org/'
		--disable-werror
		# Disable modules that are in a combined binutils/gdb tree. #490566
		--disable-{binutils,etc,gas,gold,gprof,ld}
	)
	# Intel ships two opcode trees under ops/: 'ia' (stock x86) and 'mic'
	# (adds the k1om MVEX/KNC-512 vector ISA).  configure defaults to 'ia'
	# and copies it over opcodes/ + include/opcode, so without this flag
	# `disassemble` renders every 0x62-prefixed KNC vector instruction as
	# "(bad)" -- the one thing a Xeon Phi debugger has to get right.
	[[ ${CTARGET} == k1om-* ]] && myconf+=( --enable-mic_opcodes=yes )

	local sysroot="${EPREFIX}/usr/${CTARGET}"
	is_cross && myconf+=(
		--with-sysroot="${sysroot}"
		--includedir="${sysroot}/usr/include"
		--with-gdb-datadir="\${datadir}/gdb/${CTARGET}"
	)

	if use server && ! use client ; then
		# just configure+build in the gdbserver subdir to speed things up
		cd gdb/gdbserver
		myconf+=( --program-transform-name='' )
	else
		# gdbserver only works for native targets (CHOST==CTARGET).
		# it also doesn't support all targets, so rather than duplicate
		# the target list (which changes between versions), use the
		# "auto" value when things are turned on.
		is_cross \
			&& myconf+=( --disable-gdbserver ) \
			|| myconf+=( $(use_enable server gdbserver auto) )
	fi

	if ! ( use server && ! use client ) ; then
		# if we are configuring in the top level, then use all
		# the additional global options
		myconf+=(
			--enable-64-bit-bfd
			--disable-install-libbfd
			--disable-install-libiberty
			# Disable guile for now as it requires guile-2.x #562902
			--without-guile
			# This only disables building in the readline subdir.
			# For gdb itself, it'll use the system version.
			--disable-readline
			--with-system-readline
			--with-separate-debug-dir="${EPREFIX}"/usr/lib/debug
			$(use_with expat)
			$(use_with lzma)
			$(use_enable nls)
			$(use multitarget && echo --enable-targets=all)
			--without-python
			$(use_with zlib)
		)
	fi

	econf "${myconf[@]}"
}

src_test() {
	nonfatal emake check || ewarn "tests failed"
}

src_install() {
	use server && ! use client && cd gdb/gdbserver
	default
	use client && find "${ED}"/usr -name libiberty.a -delete
	cd "${S}"

	# Don't install docs when building a cross-gdb
	if [[ ${CTARGET} != ${CHOST} ]] ; then
		rm -r "${ED}"/usr/share/{doc,info,locale}
		local f
		for f in "${ED}"/usr/share/man/*/* ; do
			if [[ ${f##*/} != ${CTARGET}-* ]] ; then
				mv "${f}" "${f%/*}/${CTARGET}-${f##*/}" || die
			fi
		done
		return 0
	fi
	# Install it by hand for now:
	# https://sourceware.org/ml/gdb-patches/2011-12/msg00915.html
	# Only install if it exists due to the twisted behavior (see
	# notes in src_configure above).
	[[ -e gdb/gdbserver/gdbreplay ]] && dobin gdb/gdbserver/gdbreplay

	if use client ; then
		docinto gdb
		dodoc gdb/CONTRIBUTE gdb/README gdb/MAINTAINERS \
			gdb/NEWS gdb/ChangeLog gdb/PROBLEMS
	fi
	docinto sim
	dodoc sim/{ChangeLog,MAINTAINERS,README-HACKING}
	if use server ; then
		docinto gdbserver
		dodoc gdb/gdbserver/{ChangeLog,README}
	fi

	if [[ -n ${PATCH_VER} ]] ; then
		dodoc "${WORKDIR}"/extra/gdbinit.sample
	fi

	# Remove shared info pages
	rm -f "${ED}"/usr/share/info/{annotate,bfd,configure,standards}.info*
}

pkg_postinst() {
	# portage sucks and doesnt unmerge files in /etc
	rm -vf "${EROOT}"/etc/skel/.gdbinit

}
