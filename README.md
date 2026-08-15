Gentoo Overlay for the Intel Xeon Phi (Knights Corner and Knights Landing)
================

This overlay is intended for a clean installation of the Intel Manycore Platform Software Stack (MPSS) for the Knights Corner architecture, the Intel Xeon Phi Processor Software for Linux (XPPSL) for the Knights Landing architecture, and related tools to support the Xeon Phi processing accelerators and CPUs on Gentoo.

This readme will only give a brief introduction on how to use this overlay. Prior knowledge about the Xeon Phi software stack and the Gentoo system is highly recommended. Note that all packages in this overlay are marked unstable and therefore need to be unmasked, e.g., through your keywords file.

## Installing the Overlay

In order to [manage overlays](https://wiki.gentoo.org/wiki/Overlay), the
package [**app-portage/layman**](https://wiki.gentoo.org/wiki/Layman) must be
installed into your Gentoo environment:

```
emerge -av app-portage/layman
```

If the installation of _layman_ was successfully completed, then you are ready
to sync the content of this repository:

```
layman -o https://raw.githubusercontent.com/abusse/xeon-phi-overlay/master/master/repositories.xml -f -a xeon-phi
```

If you use [eix](https://wiki.gentoo.org/wiki/Eix) you may need to execute:

```
eix-update
```

Few of the ebuilds of this overlay require the Intel C++ compiler (ICC). Even though it is part of the official Portage repository, a more recent version is available in the [Science](https://wiki.gentoo.org/wiki/Project:Science/Overlay). Installing this overlay is therefore highly recommended:

```
layman -a science
```

## Installing the Xeon Phi Processor Software for Linux (XPPSL)

The XPPSL stack currently consists of the following packages:

* xppsl-hwloc - a modified version of hwloc for the KNL architecture
* xppsl-micperf - incorporates a variety of benchmarks into a simple user experience
* xppsl-zonesort - the zonesort kernel module for the KNL
* xppsl-memkind - a user-extensible heap manager for high bandwidth memory (MCDRAM)
* xppsl-systools-sb - provides a variety of information and diagnostics for the processor

Furthermore, there is a meta package available that merges the whole software stack. So in order to install all tools of the XPPSL simply run:

```
emerge -av sys-apps/xppsl-meta
```

## Installing the Manycore Platform Software Stack (MPSS)

This readme will only give a brief overview how to install the MPSS and related tools. However, thanks to Libor Bukata, Jan Kůrka, and Přemysl Šůcha a more detailed but dated guide based on this overlay is available: [Xeon Phi Installation on Gentoo Linux](http://industrialinformatics.cz/xeon-phi-installation-gentoo-linux). It does not only describe how to install the necessary tools but also how to configure the setup.

### MPSS Daemon

In order to run the Xeon Phi card, the MPSS daemon has to be installed:

```
emerge -av sys-apps/mpss-daemon
```

This package will pull in all other packages that necessary to run the Xeon Phi. It will install an init script that allows to start the card. However, you have to remember to configure it according to the [Intel Documentation](http://registrationcenter-download.intel.com/akdlm/irc_nas/11194/mpss_users_guide.pdf) before starting it:

```
/etc/init.d/mpss start
```

The Xeon Phi can also be started during system boot:

```
rc-update add mpss default
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

