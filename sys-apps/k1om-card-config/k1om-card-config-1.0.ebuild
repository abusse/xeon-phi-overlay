# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="System configuration for a Gentoo root on a Xeon Phi (KNC) card"
HOMEPAGE="https://github.com/abusse/xeon-phi-overlay"
S=${WORKDIR}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	net-misc/netifrc
	sys-apps/openrc
	sys-apps/sysvinit
"
DEPEND="sys-apps/systemd-utils"

src_install() {
	dosym net.lo /etc/init.d/net.mic0

	# the card kernel has no packet scheduler
	local f=${ESYSROOT}/usr/lib/sysctl.d/50-default.conf
	if [[ -f ${f} ]]; then
		insinto /etc/sysctl.d
		grep -v default_qdisc "${f}" > "${T}"/50-default.conf || die
		doins "${T}"/50-default.conf
	fi
}

pkg_postinst() {
	elog "Run 'emerge --config ${CATEGORY}/${PN}' once to set up the consoles"
	elog "and runlevels of the card."
}

pkg_config() {
	local inittab=${EROOT}/etc/inittab

	einfo "inittab: no virtual terminals, root autologin on hvc0, getty on ttyS0"
	sed -i '/^c[1-6]:/d' "${inittab}" || die
	if ! grep -q '^s0:' "${inittab}"; then
		cat >> "${inittab}" <<-EOT || die

		# KNC consoles: virtio console (host /dev/ttyMICn) and the I2C serial
		s0:12345:respawn:/sbin/agetty -a root hvc0
		s1:12345:respawn:/sbin/agetty -L 115200 ttyS0 vt100
		EOT
	fi

	einfo "runlevels: swclock instead of hwclock, no keymaps, net.mic0 and sshd"
	local s
	for s in hwclock keymaps save-keymaps termencoding save-termencoding; do
		rm -f "${EROOT}"/etc/runlevels/boot/${s}
	done
	ln -sfn /etc/init.d/swclock "${EROOT}"/etc/runlevels/boot/swclock || die
	for s in net.mic0 sshd; do
		[[ -e ${EROOT}/etc/init.d/${s} ]] &&
			{ ln -sfn /etc/init.d/${s} "${EROOT}"/etc/runlevels/default/${s} || die; }
	done
}
