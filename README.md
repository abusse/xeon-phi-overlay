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

### MPSS SDK

This overlay also includes an ebuild for the SDK supplied by Intel. It can be installed into your Gentoo environment by running:

```
emerge -av sys-devel/mpss-sdk-k1om
```

## Installing a Xeon Phi cross toolchain

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

### USE flags

No `USE=` prefix is needed. `vanilla` is default-on for `sys-libs/glibc` (these ebuilds
never apply Gentoo patchsets to Intel's sources), and `binutils`/`gcc` no longer carry
the `vanilla`, `sanitize` or `vtv` flags at all.

## Cross debugger

The debugger is built after the toolchain stages:

```
crossdev --target k1om-mpss-linux-gnu --ex-only --ex-gdb --gdb 7.6.50_p386 \
         -od /var/db/repos/xeon-phi-overlay
```

Pass `-od` explicitly. `crossdev` populates `cross-<target>/<pkg>` only once and then
leaves the existing link alone, so a link left pointing at `::gentoo`'s `dev-debug/gdb`
makes every version in this overlay appear masked. (The package lives in `dev-debug`
because that is where Gentoo moved `gdb` and where crossdev looks for it.)

The resulting `k1om-mpss-linux-gnu-gdb` disassembles the KNC vector ISA, not just
scalar x86-64. It is built without Python support: this gdb's bindings use CPython APIs
removed in 3.12/3.13, so no Python slot still in the tree can build them. Pretty-printers
are the only loss.

The card-side `gdbserver` is not built here — a k1om binary already ships in the SDK at
`/opt/mpss/3.8.6/sysroots/k1om-mpss-linux/usr/bin/gdbserver`.
