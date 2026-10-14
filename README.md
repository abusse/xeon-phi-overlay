Gentoo Overlay for the Intel Xeon Phi (Knights Corner and Knights Landing)
================

This overlay is intended for a clean installation of the Intel Manycore Platform Software Stack (MPSS) for the Knights Corner architecture, the Intel Xeon Phi Processor Software for Linux (XPPSL) for the Knights Landing architecture, and related tools to support the Xeon Phi processing accelerators and CPUs on Gentoo.

This readme will only give a brief introduction on how to use this overlay. Prior knowledge about the Xeon Phi software stack and the Gentoo system is highly recommended. Note that all packages in this overlay are marked unstable and therefore need to be unmasked, e.g., through your keywords file.

## Installing the Overlay

Overlays are [managed with
`eselect repository`](https://wiki.gentoo.org/wiki/Eselect/Repository), which
writes to `/etc/portage/repos.conf`:

```
emerge -av app-eselect/eselect-repository
```

This overlay is not in Gentoo's repository list, so add it by URL and sync it:

```
eselect repository add xeon-phi git https://github.com/abusse/xeon-phi-overlay.git
emaint sync -r xeon-phi
```

If you use [eix](https://wiki.gentoo.org/wiki/Eix) you may need to execute:

```
eix-update
```

Few of the ebuilds of this overlay require the Intel C++ compiler (ICC). Even though it is part of the official Portage repository, a more recent version is available in the [Science](https://wiki.gentoo.org/wiki/Project:Science/Overlay). Installing this overlay is therefore highly recommended:

```
eselect repository enable science
emaint sync -r science
```

## Installing the Xeon Phi Processor Software for Linux (XPPSL)

The XPPSL stack currently consists of the following packages:

* xppsl-micperf - incorporates a variety of benchmarks into a simple user experience
* xppsl-zonesort - the zonesort kernel module for the KNL
* xppsl-memkind - a user-extensible heap manager for high bandwidth memory (MCDRAM)
* xppsl-systools-sb - provides a variety of information and diagnostics for the processor

(hwloc is no longer forked here: Intel's KNL work — MCDRAM, MemoryMode/ClusterMode
— was upstreamed, so the meta package pulls Gentoo's `sys-apps/hwloc`.)

Furthermore, there is a meta package available that merges the whole software stack. So in order to install all tools of the XPPSL simply run:

```
emerge -av sys-apps/xppsl-meta
```

### Building the benchmarks with icc (`xppsl-micperf[icc]`)

Everything above builds with GCC and needs nothing extra — KNL is standard
AVX-512, which GCC targets natively (`-march=knl`), so the default build already
produces working Knights Landing code.

For the Intel compiler the benchmarks were originally tuned with, `micperf`
carries a `USE=icc` flag. Intel's classic `icc` is no longer sold, but the free
oneAPI *classic* compiler still targets KNL (`-xMIC-AVX512`) up to release
**2021.3** — later releases removed it. It is packaged, license-free, in the
[natinst overlay](https://github.com/Nowa-Ammerlaan/natinst), which `USE=icc`
depends on (both the 2021.3 compiler and the era-matched 2021.3 MKL — only that
vintage still ships the KNL-tuned GEMM kernel `libmkl_avx512_mic` and the Intel
threading layer).

Enable the overlay and allow the packages:

```
eselect repository enable natinst
emaint sync -r natinst
echo 'intel-oneapi/* ~amd64' >> /etc/portage/package.accept_keywords/intel-oneapi
```

Two build-environment notes for the natinst packages:

* Their `rpm-extended` eclass inherits `dkms`, whose `pkg_setup` insists on a
  complete kernel source tree even for packages that ship no module. Set
  `USE=-dkms` for them, and point `KERNEL_DIR` at a *prepared* kernel source
  (one with a `Makefile`, i.e. `make modules_prepare` has been run) via
  `/etc/portage/env` — the running kernel's `/usr/src/linux` is often only
  half-configured.
* The resulting benchmarks link Intel MKL and `libiomp5` from `/opt/intel/oneapi`,
  which is not on the default library path. Source the oneAPI environment
  (`. /opt/intel/oneapi/setvars.sh`) before running them, or the GCC-built ones,
  which link the system MKL, will run without it.

icc is worth it where you want the aggressive vectorisation and KNL tunings it
was built for — on the STREAM kernel it emits noticeably more AVX-512 than GCC
and adds streaming (non-temporal) stores — but it is strictly optional; the GCC
path is the supported default.

## Installing the Manycore Platform Software Stack (MPSS)

This readme will only give a brief overview how to install the MPSS and related tools. However, thanks to Libor Bukata, Jan Kůrka, and Přemysl Šůcha a more detailed but dated guide based on this overlay is available: [Xeon Phi Installation on Gentoo Linux](http://industrialinformatics.cz/xeon-phi-installation-gentoo-linux). It does not only describe how to install the necessary tools but also how to configure the setup.

### MPSS Daemon

In order to run the Xeon Phi card, the MPSS daemon has to be installed:

```
emerge -av sys-apps/mpss-daemon
```

This package pulls in everything else needed to run a Knights Corner card — the `mic.ko` host driver (`sys-kernel/mpss-modules`), the SCIF and management libraries, the `micctrl`/`micinfo`/`micflash` tools, and the card's bootable Linux image (`sys-kernel/mic-image`). It also installs an OpenRC init script. Intel's MPSS user's guide is no longer served by Intel; it ships as `doc/mpss_users_guide.pdf` inside the [MPSS 3.8.6 release](https://archive.org/details/intel-mpss-3.8.6) this overlay builds from.

The rest of this section walks through bringing a card all the way up.

#### Host kernel requirement

The `mic.ko` driver only builds against a **host kernel of 5.4 or older**. On 5.10+ it fails to compile — the KNC driver still uses `set_fs()`, which was removed from x86 in 5.10 — and on 4.19 and earlier it fails on the `mm->pinned_vm` reference counter, which only became an `atomic64_t` in 5.1. A **5.4 longterm** kernel hits both constraints. Build the module (and later any out-of-tree pieces) with the *same* compiler that built the kernel.

#### First boot

Load the driver and let `micctrl` generate a default configuration for every card it detects:

```
modprobe mic
micctrl --initdefaults
```

`--initdefaults` writes one `/etc/mpss/micN.conf` per card, composes each card's root filesystem under `/var/mpss/`, and copies the host's root SSH public key into the card so that `ssh micN` works without a password. The card's own root account stays locked — access is key-only.

Start the stack. With the default `BootOnStart Enabled` in each card's config this also boots the cards:

```
rc-service mpss start
```

Watch them come up (`ready` → `booting` → `online`) and log in:

```
micctrl -s
ssh mic0 uname -a          # -> Linux mic0.local ... k1om GNU/Linux
```

To boot the cards automatically at system start:

```
rc-update add mpss default
```

> **Heads-up:** `rc-service mpss start` may print `failed` even though the cards boot fine. The init script's `micctrl -w` "wait for boot" helper can abort with a glibc *double free* on a modern toolchain. `mpssd` itself is unaffected — confirm with `micctrl -s`.

#### Networking

By default each card gets a private point-to-point link to the host (`StaticPair`: host `172.31.<n>.254`, card `172.31.<n>.1`), reachable only from the host. Networking is changed with `micctrl --network` while the daemon is stopped.

To put the cards on your **real LAN** through an existing host bridge — here `br0`, already carrying the physical NIC and the host's own address — register the bridge and switch the cards to DHCP over it:

```
rc-service mpss stop
micctrl --addbridge=br0 --type=external --ip=<host-ip> --netbits=<bits> --mtu=1500
micctrl --network=dhcp --bridge=br0 mic0 mic1
rc-service mpss start
```

**On Gentoo this is not enough on its own.** `micctrl` enslaves the card interfaces to the bridge by calling the RedHat/SUSE `ifup`/`ifdown` scripts, which Gentoo does not have — so `micN` never actually joins `br0`, and the card's DHCP request never leaves the host. Add the card interfaces to the bridge yourself with a udev rule that fires when the `mic` driver creates each interface:

```
# /etc/udev/rules.d/70-mic-bridge.rules
SUBSYSTEM=="net", ACTION=="add", KERNEL=="mic[0-9]*", RUN+="/bin/ip link set %k mtu 1500 master br0 up"
```

Match the MTU to the bridge (**1500** for a normal LAN) at *both* ends: the rule sets it on the host side, and `micctrl` sets the card side from the bridge's `--mtu`. A mismatch silently drops every frame on the virtual PCIe link — the symptom is a card that is `online` but whose host-side `micN` shows `RX: packets 0`. Finally make the daemon start after the bridge exists, so the rule has something to enslave to:

```
# /etc/conf.d/mpss
rc_need="net.br0"
```

Once bridged, each card requests a lease as `micN.local`; find the addresses on your DHCP server or with `ip neigh show dev br0`. Assign DHCP reservations if you want them to be stable.

#### If a card comes up wrong after a config change

The image generator runs `gzip` without `-f`, so an existing `/var/mpss/micN.image.gz` is **not** overwritten and the card can boot a stale root filesystem (old network settings, etc.). After changing a card's config, delete the composed images so they are regenerated on the next boot:

```
rc-service mpss stop
rm -f /var/mpss/mic*.image /var/mpss/mic*.image.gz
rc-service mpss start
```

A single misbehaving card can be recycled on its own without disturbing the others:

```
micctrl -r mic0                                   # reset to ready
rm -f /var/mpss/mic0.image /var/mpss/mic0.image.gz
micctrl -b mic0                                   # boot it again
```

### Booting a card from a block device (PersistentFS)

By default a card boots a RAM disk (`RootDevice Ramfs`), so any change is lost on
reboot. This overlay restores MPSS's **PersistentFS** mode, which lets a card
mount its root filesystem from a host file, an LVM volume, or a **ZFS zvol** over
virtio-blk (it appears as `/dev/vda` on the card) — persistent like a real disk.
Intel shipped this in earlier MPSS but dropped the config parser for it in 3.8.6;
the `sys-apps/mpss-daemon` ebuild here patches it back in and has `mpssd` assign
the backing store to `/sys/class/mic/micN/virtblk_file` automatically at boot.

It needs three things beyond the stock setup:

- A **card kernel** with virtio, ext4 and devtmpfs. The stock in-tree config has
  none of these; a ready-made one is at
  `sys-kernel/mic-sources/files/config-knc-persistentfs` (adds `VIRTIO`,
  `VIRTIO_RING`, `EXT4_FS`, `DEVTMPFS`, `I2C_PXA`/`I2C_CHARDEV`, drops the
  standalone `EXT2/3` drivers). Build it with the k1om cross toolchain and
  install the resulting `bzImage`/`System.map` as the card's `OSimage`.
- The **card-side modules** (`micscif`, `intel_micveth`, `michvc`, `mic_virtblk`,
  …) built from the same `sys-kernel/mpss-modules` source but for the card — run
  `make` with `MIC_CARD_ARCH` unset and `KERNEL_SRC=` pointing at that kernel —
  and placed in the initramfs so they match its vermagic.
- An **initramfs** whose `/init` loads those modules, mounts `/dev/vda` and
  `switch_root`s into it. Since the persistent rootfs has no `/lib/modules` and
  the initramfs has no udev, the init mknods `/dev/vda` from `/sys/block/vda`,
  signals the host it is online
  (`modprobe mpssboot; echo done > /sys/class/micnotify/notify/host_notified`),
  and DHCPs `mic0` before switching. A working example is in
  `contrib/persistentfs/init`.

Prepare the backing store (a zvol here) with a k1om root filesystem:

```
zfs create -V 8G tank/mic0-root
mkfs.ext4 -O ^64bit,^metadata_csum /dev/zvol/tank/mic0-root
mount /dev/zvol/tank/mic0-root /mnt/root
# unpack a k1om rootfs into /mnt/root, then:
umount /mnt/root
```

Point the card at it in `/etc/mpss/micN.conf` and (re)start `mpss`:

```
RootDevice PersistentFS /dev/zvol/tank/mic0-root
Base CPIO /usr/share/mpss/boot/<persistentfs-initramfs>.cpio.gz
OSimage   /usr/share/mpss/boot/<card-bzImage> /usr/share/mpss/boot/<System.map>
```

`mpssd` builds a `root=/dev/vda` command line, assigns the backing store, and the
card mounts its persistent root.

> The stock card userland ships OpenSSH 6.4, whose `ssh-rsa`/SHA-1 a modern
> client refuses by default. Reach the card with:
> `ssh -o PubkeyAcceptedAlgorithms=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa root@<card>`

### MPSS SDK

This overlay also includes an ebuild for the SDK supplied by Intel. It can be installed into your Gentoo environment by running:

```
emerge -av sys-devel/mpss-sdk-k1om
```

## Installing a Xeon Phi cross toolchain

This section builds Intel's MPSS 3.8.6 toolchain (gcc 5.1.1, glibc 2.21); for the current
one see "A modern Gentoo on the card" below.

If you prefer to compile your own toolchain and not relying on the binaries supplied by the Intel SDK (see above), you can do this with the ebuilds provided by this overlay.

In order to [build a cross toolchain](https://wiki.gentoo.org/wiki/Cross_build_environment), the package [**sys-devel/crossdev**](https://gitweb.gentoo.org/proj/crossdev.git/) must be installed into your Gentoo environment:

```
emerge -av sys-devel/crossdev
```

Using crossdev, it is possible to build a toolchain from the sources supplied by Intel:

```
crossdev --target k1om-mpss-linux-gnu --binutils 2.22_p386 --gcc 5.1.1_p386 --kernel 2.6.38_p386 --libc 2.14.1_p386
```

Note that the patch level of the tools indicate the MPSS version. For example MPSS version 3.8.6 results in `*_p386`.

The target triplet must spell `k1om` in the **CPU** field. `x86_64-k1om-linux-gnu`
looks plausible and even yields an `ld` whose default emulation is `elf_k1om`, but it
produces an assembler that emits x86-64 objects; only `k1om-*-linux-*` selects the
`elf64-k1om` default vector. Keep the `-gnu` suffix as well — that is what lets
crossdev infer `libc=glibc`.

`crossdev` warns `No ARCH is known for this target`. That is expected: k1om is not a
Gentoo `ARCH`.

Once built, GCC drives the assembler and linker for you. Calling `as` by hand needs
`-march=k1om`, otherwise it silently produces x86-64 objects:

```
k1om-mpss-linux-gnu-as -march=k1om -o foo.o foo.s
```

Verify a build really targeted the card with `readelf -h`, which must report
`Machine: Intel K1OM`.

### Do not substitute a newer binutils

Use the `2.22_p386` ebuild from this overlay. Upstream binutils carried k1om only from
2.22 to 2.38 and dropped it in 2.39, and even within that window upstream never shipped
a `k1om-*` target triplet or the KNC vector ISA — the assembler tables for it exist only
in Intel's tree. A modern `sys-devel/binutils` cannot build this toolchain.
(This overlay's `binutils-2.47` carries Intel's k1om support forward-ported; it belongs to
the current toolchain described below.)

### USE flags

No `USE=` prefix is needed. `vanilla` is default-on for `sys-libs/glibc` (these ebuilds
never apply Gentoo patchsets to Intel's sources), and `binutils`/`gcc` no longer carry
the `vanilla`, `sanitize` or `vtv` flags at all.

## A modern Gentoo on the card

The overlay also carries a current k1om toolchain (binutils 2.47, gcc 16.2, glibc 2.44,
kernel headers 6.18), the card kernel `sys-kernel/mic-sources-6.18` with its drivers
`sys-kernel/mic-modules`, and the profile `k1om/23.0` (amd64 23.0, merged-usr, without
MMX/SSE/AVX/CMOV/CET). With them a current Gentoo is cross-built for the card and
afterwards maintained on the card itself.

### Cross toolchain

Add `contrib/k1om-stage/crossdev.bashrc` to the build host's `/etc/portage/bashrc`
(crossdev would put the k1om libraries in `lib` instead of `lib64`), then:

```
crossdev --target k1om-mpss-linux-gnu -oS /var/db/repos/xeon-phi-overlay \
         --binutils 2.47 --gcc 16.2.0 --kernel 6.18 --libc 2.44-r1
```

`dev-util/k1om-toolchain-tests` (below) checks the result on a card.

### Card root file system

`contrib/k1om-stage/k1om-stage-setup DIR` prepares a build directory: `DIR/root` for the
card's root (with `make.profile` pointing at `k1om/23.0`), compiler wrappers that pass
`--sysroot=DIR/root`, and `DIR/bin/kemerge`, which runs the cross emerge into it. `DIR`
must be readable by the portage user, so not below `/root`. Then:

```
USE=build DIR/bin/kemerge -1 --nodeps sys-apps/baselayout
DIR/bin/kemerge -1 --nodeps sys-kernel/linux-headers sys-libs/glibc
DIR/bin/kemerge @system
DIR/bin/kemerge sys-apps/k1om-card-config net-misc/openssh net-misc/dhcpcd ...
DIR/bin/kemerge --config sys-apps/k1om-card-config
```

baselayout has to come first and with `USE=build`: only then does it create the
merged-usr symlinks, which the compiler needs to find the libraries in the new root.

Cross-building rules:

* Never set `CC` and friends in `make.conf`; perl, python and libtool record them. The
  wrappers come first in `PATH` instead.
* Perl XS modules cannot be cross-built (they use the build host's perl configuration).
  Build `dev-vcs/git` with `-perl` and the like, and rebuild them on the card.
* `profiles/package.mask` masks this overlay's copies of `app-arch/zstd`, `dev-libs/gmp`,
  `dev-libs/libffi`, `dev-libs/libgcrypt`, `net-misc/openssh`, `sys-apps/busybox`,
  `sys-apps/kexec-tools` and `sys-libs/libxcrypt` everywhere except in the k1om profile,
  which in turn masks the `::gentoo` versions. They differ from `::gentoo` only by a k1om
  patch (no SSE, no CMOV, the k1om target), so a `::gentoo` bump needs a matching copy here.

`sys-apps/k1om-card-config` adds what the card needs beyond a stock root: the `net.mic0`
interface and a sysctl default without the packet scheduler setting the card kernel lacks.
Its `--config` step replaces the virtual terminals in `inittab` by a root autologin on the
virtio console `hvc0` (the host's `/dev/ttyMICn`) and a getty on the I2C serial `ttyS0`,
and switches the runlevels to `swclock`, `net.mic0` and `sshd`. Host keys, `authorized_keys`,
the hostname and the network settings are site data and stay with you.

### Booting the card from it

Copy the root onto a block device of the host (a ZFS zvol, an LVM volume or a file), build
the card kernel from `sys-kernel/mic-sources-6.18` (`ARCH=k1om
CROSS_COMPILE=k1om-mpss-linux-gnu-`) and `sys-kernel/mic-modules` against it, and make the
initramfs from the root and the modules:

```
contrib/persistentfs/mkinitramfs.sh DIR/root /path/to/lib/modules/<release> initramfs-k1om.cpio.gz
```

Then point the card at all three (see "Booting a card from a block device" above):

```
OSimage   /usr/share/mpss/boot/bzImage-k1om /usr/share/mpss/boot/System.map-k1om
Base CPIO /usr/share/mpss/boot/initramfs-k1om.cpio.gz
RootDevice PersistentFS /dev/zvol/tank/mic1-root
```

### On the card

Once it runs, the card is a self-hosting Gentoo: remove `CBUILD` and `PKGDIR` from
`make.conf` and emerge natively. The card has 7.6 GB of RAM for over 200 hardware threads, so
start with `MAKEOPTS="-j32"` and `EMERGE_DEFAULT_OPTS="--jobs=4"` and lower `-j` for a
package only after it ran out of memory (cmake's bootstrap needs `-j16`).

## Testing the cross toolchain on a card

`dev-util/k1om-toolchain-tests` builds a set of test programs with the k1om cross
compiler (C, C++, OpenMP, Fortran, libquadmath, libitm, IMCI inline assembly, shared
libraries), runs them on a card over ssh and checks the results:

```
emerge -av dev-util/k1om-toolchain-tests
k1om-toolchain-test --card root@<card>
```

The programs run through the glibc loader of the sysroot they were linked against,
which is copied to the card together with the compiler's runtime libraries, so the
card's own C library does not matter. Nothing is installed on the card; each run uses
a temporary directory under `/tmp` and removes it afterwards. The card needs root ssh
access by key from the machine running the test, or from the host given with `--via`:

```
k1om-toolchain-test --card root@<card> --via root@<mic-host>
```

Other options:

* `--bindir DIR`, `--sysroot DIR`: test a compiler outside `PATH`, or link against
  another sysroot (the default is the compiler's own).
* `--build-only`: only build the programs and run the checks that need no card.
* `--keep`, `--workdir DIR`: keep the binaries, the card output and the compiler
  warnings.
* `--ssh-opts OPTS`: ssh options for the card. The default enables the legacy
  algorithms the card's OpenSSH 6.4 needs.

Defaults for these can be set in `/etc/k1om-toolchain-test.conf`.

The output is compared with a run built by Intel's MPSS gcc 5.1.1 and with fixed
expected results. The run fails on any difference, on a binary that is not
`Intel K1OM` (or not PIE when the compiler defaults to PIE), and if the compiler
accepts `-msse2` or `target("avx2")`. Tests for libitm, libquadmath and Fortran are
skipped when the compiler does not provide them. The exit status is 0 only if every
check passed.

## Debugger

`dev-debug/gdb-17.2` carries Intel's k1om support forward-ported from gdb 7.6.50: the
k1om architecture with the KNC registers (`zmm0-31`, `k0-7`, `vxcsr`), the KNC
disassembler, native debugging on the card and `gdbserver`. The cross gdb is built
after the toolchain stages:

```
crossdev --target k1om-mpss-linux-gnu --ex-only --ex-gdb --gdb 17.2 \
         -od /var/db/repos/xeon-phi-overlay
```

Pass `-od` explicitly. `crossdev` populates `cross-<target>/<pkg>` only once and then
leaves the existing link alone, so a link left pointing at `::gentoo`'s `dev-debug/gdb`
makes every version in this overlay appear masked. (The package lives in `dev-debug`
because that is where Gentoo moved `gdb` and where crossdev looks for it.)

On a card root with the k1om profile, `emerge dev-debug/gdb` gives the native gdb and
`gdbserver`. With the cross gdb and `gdbserver` on the card, use `set sysroot target:`.

The vector registers need a card kernel from `mic-sources-6.18` (its series exports the
KNC vector state through `NT_X86_XSTATE`). On an older card kernel gdb shows `zmm`/`k`/`vxcsr`
as unavailable and never writes them, since writing them there oopses the card.

`gdb-7.6.50_p386` (Intel's) remains for the MPSS 3.8.6 toolchain; it is built without
Python, whose bindings in that version use CPython APIs removed in 3.12/3.13.
