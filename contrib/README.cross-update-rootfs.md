# Cross-updating a Xeon Phi (k1om) card root filesystem

Runbook for updating the Gentoo **root filesystem** a Knights Corner card boots
(see the PersistentFS section in the top-level README for how it boots from a
ZFS zvol / block device). This is a plan captured for later; it has **not** been
executed yet. Read the "Hard parts" section before starting — the safe/mount
steps are easy, the cross-emerge is where the real work is.

## Why cross-compilation is the only option

The card cannot build its own updates in any practical way, and the host cannot
run the card's binaries:

- **On the card:** native `gcc` is 4.7 and the cores are slow — a world rebuild
  would take forever.
- **On the host, natively:** k1om is not x86-64. It uses the IMCI 512-bit vector
  ISA (a KNC-only AVX-512 precursor) and drops SSE/AVX; a Sandy/Ivy-Bridge host
  faults on k1om code. You cannot `chroot` into the card rootfs and run its
  `emerge`/`gcc`.
- **qemu:** there is no k1om target in qemu-user, so binfmt/qemu chroot is out.

So everything is built on the host with a **k1om cross toolchain** and installed
into the card's (mounted) rootfs.

## The card's frozen ABI (do not try to move these)

Discovered from the running card (`/etc/portage/make.conf`, `emerge --info`):

| | value |
|---|---|
| CHOST | `x86_64-k1om-linux-gnu` |
| native gcc | 4.7.0 |
| glibc | 2.14.90 |
| kernel-headers | ~3.9 (`LINUX_VERSION_CODE 198912`) |
| running kernel | 2.6.38.8+mpss3.8.6 |
| Portage | 2.2.7 |
| profile | `default/linux/amd64/13.0/no-multilib` |
| tree | `/usr/portage`, **synced 2014-02-02**, + `layman/xeon-phi` overlay |
| CFLAGS | `-O2 -pipe -march=k1om` |

k1om was dropped from gcc, binutils and Gentoo years ago, and the card's
kernel/glibc are fixed. **There is no path to a modern @world.** Any update stays
inside this 2014-era toolchain/tree envelope.

## The cross toolchain (built on the host from this overlay)

`crossdev` is not installed on knc-host yet; all component ebuilds are in this
overlay. Build the toolchain with (from the top-level README):

```
emerge -av sys-devel/crossdev
crossdev --target k1om-mpss-linux-gnu \
         --binutils 2.22_p386 --gcc 5.1.1_p386 \
         --kernel 2.6.38_p386 --libc 2.14.1_p386
```

- Target tuple must be `k1om-mpss-linux-gnu` (CPU field spells `k1om` → `elf64-k1om`
  default vector; `x86_64-k1om-...` silently emits x86-64 objects). `-gnu` makes
  crossdev pick `libc=glibc`.
- `--libc 2.14.1_p386` gives **glibc-2.14.1**, matching the card's 2.14.90 — this
  is what makes the built binaries loadable on the card.
- Do **not** substitute a newer binutils (only 2.22–2.38 ever knew k1om, and only
  Intel's `2.22_p386` ships the `k1om-*` triplet + KNC vector tables).
- crossdev prints `No ARCH is known for this target` — expected, k1om is no Gentoo ARCH.

Result: `k1om-mpss-linux-gnu-{gcc,ld,as,...}` and a sysroot at
`/usr/k1om-mpss-linux-gnu/` (glibc-2.14.1 + 2.6.38 headers).

## Safety: snapshot & rollback (do this first, every time)

The rootfs lives on the zvol `tank/mic-gentoo` (ext4). Snapshot it **with the card
off** so the filesystem is clean:

```
micctrl -r mic0                                   # shut the card down (unmounts vda)
zfs snapshot tank/mic-gentoo@pre-update-$(date +%F)
# ... work ...
# roll back if needed:
zfs rollback tank/mic-gentoo@pre-update-YYYY-MM-DD
```

Mount it on the host to work on it:

```
mount /dev/zvol/tank/mic-gentoo /mnt/card
```

## Plan: cross-emerge a (staged) system update

The goal is a system update via `emerge`, driven from the host into `ROOT=/mnt/card`.

1. Snapshot + mount (above).
2. Build the cross toolchain (above).
3. Point Portage at a **period-correct tree**: the card's own `/usr/portage`
   (2014-02-02) + the `xeon-phi` layman overlay. The modern host tree will not
   work — its ebuilds need gcc-8+/glibc-2.30+/newer kernels. Use the tree from the
   mounted rootfs (`/mnt/card/usr/portage`) or a saved 2014 snapshot, plus the
   `xeon-phi` overlay the card references (`/var/lib/layman/xeon-phi`).
4. Cross-emerge into the card root, e.g.:
   ```
   PORTDIR=/mnt/card/usr/portage \
   PORTAGE_CONFIGROOT=/mnt/card ROOT=/mnt/card \
   k1om-mpss-linux-gnu-emerge -uDN --keep-going @world      # staged; see below
   ```
5. Unmount, boot the card, verify it boots + logs in; roll back on any failure.

## Hard parts to solve when picking this up

These are the reasons this is parked, not the mount/snapshot mechanics:

- **CHOST tuple mismatch.** The rootfs `make.conf` says `x86_64-k1om-linux-gnu`;
  the crossdev toolchain is `k1om-mpss-linux-gnu`. `emerge` keys off CHOST. Either
  (a) build a crossdev target literally named `x86_64-k1om-linux-gnu` (the README
  warns modern binutils then emit x86-64 objects — needs Intel's patched binutils
  to still produce k1om under that tuple, verify with `readelf -h` → `Intel K1OM`),
  or (b) keep `k1om-mpss-linux-gnu` and reconcile CHOST in the ROOT (rewrite
  `make.conf` CHOST + rebuild the affected metadata) — riskier.
- **Toolchain vs tree era.** The 2014 tree's ebuilds were written for gcc-4.7;
  building them with gcc-5.1.1 will trip `-fpermissive`/stricter-C++ failures in
  some packages. Expect per-package patching or version pins.
- **Portage 2.2.7 in the ROOT.** Old EAPI/behaviour; the host's newer Portage
  driving an old ROOT can disagree. May need to run a Portage matching the ROOT.
- **Do NOT `@world` in one shot.** Start with `emerge --pretend`, then stage:
  toolchain-adjacent libs first, then leaf packages. `--keep-going`, review each
  batch, re-snapshot between stages.
- **glibc/headers are the ceiling.** Anything needing glibc > 2.14 or kernel
  features > 2.6.38 simply won't work on the card — pin or skip those.

## Fallback: manual per-package (for a few tools)

If the goal is just adding/updating a handful of tools rather than a world update,
skip Portage entirely:

```
./configure --host=x86_64-k1om-linux-gnu \
    CC='k1om-mpss-linux-gnu-gcc --sysroot=/mnt/card' \
    --prefix=/usr
make && make install DESTDIR=/mnt/card
```

Verify each binary with `readelf -h <file>` → `Machine: Intel K1OM`.

## Status

Parked at "plan documented". Nothing built or changed on the card. The card boots
Gentoo 2.2 from `tank/mic-gentoo` (PersistentFS); snapshot/rollback is the safety
net for whenever we resume.
