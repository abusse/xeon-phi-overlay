# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic gnuconfig multilib strip-linguas toolchain-funcs intel-mpss

DESCRIPTION="GNU binutils with Intel's k1om (Xeon Phi) target support"
HOMEPAGE=${MPSS_URI}
SRC_URI=${MPSS_SRC_SRC_URI}

LICENSE="GPL-3+"
SLOT="2.22"
KEYWORDS="~amd64"
IUSE="multitarget nls static-libs"

# Intel ships plain binutils 2.22 plus the k1om target and no Gentoo patchset,
# so this ebuild is self-contained rather than eclass-driven.
#
# The triplet spells k1om in the CPU field: bfd/config.bfd sets
# targ_defvec=k1om_elf64_vec only for k1om-*-linux-*, so build it as
# k1om-mpss-linux-gnu.  A vendor-field spelling still gives an ld whose default
# emulation is elf_k1om, but an assembler that emits x86-64 objects.

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi
is_cross() { [[ ${CHOST} != ${CTARGET} ]] ; }

RDEPEND="
	>=sys-devel/binutils-config-3
	sys-libs/zlib
"
DEPEND="${RDEPEND}"
BDEPEND="
	sys-apps/texinfo
	nls? ( sys-devel/gettext )
"

MY_P="binutils-${PV%_p*}+mpss${MPSS_VER}"
S="${WORKDIR}/${MY_P}"
MY_BUILDDIR="${WORKDIR}/build"

src_unpack() {
	unpack ${A}
	unpack ./mpss-${MPSS_VER}/src/${MY_P}.tar.bz2
}

src_prepare() {
	default

	# 2011-era autotools do not know modern build triplets.
	gnuconfig_update

	mkdir -p "${MY_BUILDDIR}" || die
}

src_configure() {
	# Gentoo's binutils layout, so binutils-config can manage this target.
	LIBPATH=/usr/$(get_libdir)/binutils/${CTARGET}/${PV}
	INCPATH=${LIBPATH}/include
	DATAPATH=/usr/share/binutils-data/${CTARGET}/${PV}
	if is_cross ; then
		TOOLPATH=/usr/${CHOST}/${CTARGET}
	else
		TOOLPATH=/usr/${CTARGET}
	fi
	BINPATH=${TOOLPATH}/binutils-bin/${PV}

	strip-linguas -u */po

	# texinfo >= 7 rejects this vintage of binutils' markup outright
	# ("@itemx should not begin @table"), and the tarball ships no
	# pre-generated .info to fall back on, so MAKEINFO=true would then break
	# "make install".  --force still writes usable .info files; the wrapper
	# stops a non-zero exit from aborting the build over documentation.
	cat > "${T}"/makeinfo <<-EOF || die
		#!/bin/sh
		makeinfo --force --no-validate "\$@"
		exit 0
	EOF
	chmod +x "${T}"/makeinfo || die
	export MAKEINFO="${T}"/makeinfo

	strip-flags

	# binutils 2.22 is from 2011 and does not survive a modern compiler's
	# defaults: GCC >= 14 rejects implicit function declarations and implicit
	# int, and >= 10 defaults to -fno-common.
	append-cflags -std=gnu89 -fcommon
	append-cflags $(test-flags-CC -Wno-error=implicit-function-declaration)
	append-cflags $(test-flags-CC -Wno-error=implicit-int)

	local myconf=(
		--prefix="${EPREFIX}"/usr
		--host=${CHOST}
		--target=${CTARGET}
		--datadir="${EPREFIX}"${DATAPATH}
		--infodir="${EPREFIX}"${DATAPATH}/info
		--mandir="${EPREFIX}"${DATAPATH}/man
		--bindir="${EPREFIX}"${BINPATH}
		--libdir="${EPREFIX}"${LIBPATH}
		--libexecdir="${EPREFIX}"${LIBPATH}
		--includedir="${EPREFIX}"${INCPATH}
		--with-pkgversion="MPSS ${MPSS_VER}"
		--with-system-zlib
		--enable-64-bit-bfd
		--enable-shared
		--enable-threads
		--enable-install-libiberty
		--disable-werror
		$(use_enable static-libs static)
	)

	# bfd and opcodes still use the old gettext macros, which install their
	# .mo files under ${prefix}/share/locale regardless of --datadir -- that
	# collides with the native sys-devel/binutils.  --localedir fixes the
	# path, and for a cross toolchain the translations are noise anyway.
	myconf+=( --localedir="${EPREFIX}${DATAPATH}"/locale )
	if is_cross ; then
		myconf+=( --disable-nls )
	else
		myconf+=( $(use_enable nls) )
	fi

	use multitarget && myconf+=( --enable-targets=all )
	is_cross && myconf+=( --with-sysroot="${EPREFIX}"/usr/${CTARGET} )
	[[ -n ${CBUILD} ]] && myconf+=( --build=${CBUILD} )

	cd "${MY_BUILDDIR}" || die
	ECONF_SOURCE="${S}" econf "${myconf[@]}"
}

src_compile() {
	cd "${MY_BUILDDIR}" || die
	emake all
}

src_install() {
	local x d

	cd "${MY_BUILDDIR}" || die
	emake DESTDIR="${D}" tooldir="${EPREFIX}${LIBPATH}" install

	rm -rf "${ED}"/${LIBPATH}/bin || die
	use static-libs || find "${ED}" -name '*.la' -delete

	if [[ -d ${ED}/${LIBPATH} ]] ; then
		cd "${ED}"/${LIBPATH} || die
		for d in ../* ; do
			[[ ${d} == ../${PV} ]] && continue
			[[ -d ${d} ]] || continue
			mv ${d}/* . || die
			rmdir ${d} || die
		done
	fi

	# Cross tools install as ${CTARGET}-foo; inside BINPATH they are addressed
	# unprefixed, and binutils-config creates the prefixed symlinks.
	if is_cross ; then
		cd "${ED}"/${BINPATH} || die
		for x in * ; do
			mv ${x} ${x/${CTARGET}-} || die
		done

		if [[ -d ${ED}/usr/${CHOST}/${CTARGET} ]] ; then
			mv "${ED}"/usr/${CHOST}/${CTARGET}/include "${ED}"/${INCPATH}
			mv "${ED}"/usr/${CHOST}/${CTARGET}/lib/* "${ED}"/${LIBPATH}/
			rm -r "${ED}"/usr/${CHOST}/{include,lib}
		fi
	fi

	if [[ -d ${ED}/${LIBPATH}/lib ]] ; then
		mv "${ED}"/${LIBPATH}/lib/* "${ED}"/${LIBPATH}/ || die
		rm -r "${ED}"/${LIBPATH}/lib || die
	fi

	# env.d entry so binutils-config can select this target
	insinto /etc/env.d/binutils
	cat <<-EOF > "${T}"/env.d || die
		TARGET="${CTARGET}"
		VER="${PV}"
		LIBPATH="${EPREFIX}${LIBPATH}"
	EOF
	newins "${T}"/env.d ${CTARGET}-${PV}

	# These collide with the native binutils' info pages.
	rm -f "${ED}"/${DATAPATH}/info/{configure,dir,standards}.info
}

pkg_postinst() {
	# Make sure this CTARGET has a binutils version selected.
	[[ -e ${EROOT}/etc/env.d/binutils/config-${CTARGET} ]] && return 0
	binutils-config ${CTARGET}-${PV}
}

pkg_postrm() {
	local current_profile=$(binutils-config -c ${CTARGET} 2>/dev/null)

	if [[ ${current_profile} == ${CTARGET}-${PV} ]] ; then
		local choice=$(binutils-config -l 2>/dev/null \
			| grep " ${CTARGET}-" | awk '{print $2}' | head -n1)
		[[ -n ${choice} ]] && binutils-config "${choice}"
	fi
}
