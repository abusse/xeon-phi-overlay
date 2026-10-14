#!/bin/bash
# mkinitramfs.sh ROOT MODULES OUT
#   ROOT     a k1om root file system with busybox (e.g. the card's Gentoo root)
#   MODULES  the card kernel's lib/modules/<release>, including the mic-modules
#   OUT      the initramfs to write (gzip'd newc cpio), for "Base CPIO" in micN.conf
# Run as root (device nodes).
set -e
[[ $# == 3 ]] || { echo "usage: ${0##*/} ROOT MODULES OUT" >&2; exit 2; }
R=$(readlink -f "$1") M=$(readlink -f "$2") O=$3
init=$(dirname "$(readlink -f "$0")")/init
W=$(mktemp -d)
trap 'rm -rf "${W}"' EXIT

mkdir -p "${W}"/{bin,dev,etc,lib64,new_root,proc,sys,usr/share/udhcpc,lib/modules}
install -m755 "${init}" "${W}"/init
cp "${R}"/bin/busybox "${W}"/bin/
for a in ash awk cat cpio cut echo find grep ifconfig insmod ip ls mkdir mknod modprobe \
	mount rm rmmod sed sh sleep switch_root tr udhcpc umount; do
	ln -s busybox "${W}"/bin/${a}
done
ln -s bin "${W}"/sbin
install -m755 "${R}"/usr/share/udhcpc/default.script "${W}"/usr/share/udhcpc/

# shared libraries of busybox, and the loader
need() {
	readelf -d "$1" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'
	readelf -l "$1" | sed -n 's/.*interpreter: .*\/\(.*\)\]/\1/p'
}
todo=$(need "${R}"/bin/busybox)
while [[ -n ${todo} ]]; do
	set -- ${todo}; todo=
	for l; do
		[[ -e ${W}/lib64/${l} ]] && continue
		for d in "${R}"/lib64 "${R}"/usr/lib64; do
			[[ -e ${d}/${l} ]] || continue
			cp -L "${d}/${l}" "${W}"/lib64/
			todo+=" $(need "${d}/${l}")"
			break
		done
		[[ -e ${W}/lib64/${l} ]] || { echo "${l} not found in ${R}" >&2; exit 1; }
	done
done

cp -a "${M}" "${W}"/lib/modules/
rm -f "${W}"/lib/modules/*/{build,source}
: >> "${W}"/lib/modules/"${M##*/}"/modules.order
depmod -b "${W}" "${M##*/}"

mknod -m 600 "${W}"/dev/console c 5 1
mknod -m 666 "${W}"/dev/null c 1 3

(cd "${W}" && find . | cpio -o -H newc --quiet) | gzip -9 > "${O}"
echo "${O}: $(du -h "${O}" | cut -f1), $(find "${W}" -name '*.ko' | wc -l) modules"
