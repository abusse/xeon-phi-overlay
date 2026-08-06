# Forward-porting k1om to binutils 2.38 — result and measurements

`binutils-2.38-k1om-target.patch` is a **working** 15-line patch that makes upstream
binutils **2.38** (the last release before k1om was removed in 2.39) build as a
`k1om-mpss-linux-gnu` cross toolchain. It is **not** wired into any ebuild; it is kept
here as the measured result of asking "can we move off Intel's 2.22?".

## What the patch does

Upstream 2.38 still had all the k1om *plumbing* (BFD vector, `elf_k1om` emulation,
`bfd_arch_k1om`, `-march=k1om`) but no way to select k1om as a **target**. Three files
gate that, not one:

| file | change |
|---|---|
| `bfd/config.bfd` | `k1om-*-linux-*` target case → `targ_defvec=k1om_elf64_vec` (note 2.38 renamed the vectors: `bfd_elf64_k1om_vec` → `k1om_elf64_vec`) |
| `bfd/config.bfd` | `k1om)`/`l1om)` → `targ_archs=bfd_i386_arch`, else `cpu-k1om.o` fails to link with undefined `bfd_arch_i386_short_nop_fill` |
| `ld/configure.tgt` | `k1om-*-linux-*` and `x86_64-k1om-linux-*` → `targ_emul=elf_k1om` |
| `gas/configure.tgt` | `x86_64*)` → `x86_64*\|[lk]1om*)`, else gas rejects the target with *"This target is no longer supported in gas"* |

## What works

Built and verified (`--target=k1om-mpss-linux-gnu`):

* default BFD target `elf64-k1om`
* `ld` default emulation `elf_k1om`
* `as` emits `Machine: Intel K1OM`
* `ld` links to a K1OM `EXEC`

So **scalar** k1om code assembles and links correctly with a 2022-era binutils.

## What does not work — the KNC vector ISA

Measured with Intel's own gas testsuite (`gas/testsuite/gas/i386/k1omni.s`, 6,980 lines,
211 distinct mnemonics). Intel's `as` assembles it clean: 7,200 instructions, 44,664 bytes.

The ported 2.38 assembler, same input:

| metric | value |
|---|---|
| instruction lines in source | 6,708 |
| **lines that failed** | **5,737 (85.5%)** |
| lines that assembled | 971 (14.5%, the AVX-512-overlapping ones) |
| "no such instruction" | 1,995 |
| `unknown vector operation` (MVEX swizzles `{dcba}` `{cdab}` `{badc}`) | 3,319 |
| `unsupported broadcast` | 93 |
| `invalid VSIB address` | 9 |

The dominant failure is *not* missing mnemonics — it is KNC's **MVEX operand syntax**.
Completing the port therefore means more than translating 314 table rows:

* reintroduce 15 opcode-modifier flags removed since 2.22 (`VecType`, `VecOp`, `VecESize`,
  `VecMem`, `VecMemShift`, `VecDisp8`, `NoSwizzle`, `NoEH`, `SAEOnly`, `NoRounding`,
  `NoBroadcast`, `BroadcastOnly`, `VecSIB`, `VexOpcode`, `IgnoreSize`) plus their
  `i386-opc.h` / `i386-gen.c` plumbing
* convert 314 `i386-opc.tbl` entries to the new field layout (the operand-count and
  opcode-length columns are gone; `VexOpcode=` became `Space0F38`-style)
* port ~193 lines of MVEX encoding logic into a `tc-i386.c` that upstream restructured
  around AVX-512 — KNC's MVEX and AVX-512's EVEX share the `0x62` prefix with different
  payload semantics, so `build_evex_prefix` cannot simply absorb it
* teach the parser KNC's swizzle/conversion syntax

That is an upstream-scale project, and the payoff is only a newer `ld`.

**Conclusion: keep using Intel's binutils 2.22.** This patch is useful only if someone
wants a modern binutils for scalar k1om work, or as the starting point for the full ISA
port. The `i386-dis.c` disassembler needs no changes at all — KNC decoding rides on the
generic VEX/EVEX tables, and 2.38 already has all 32 `zmm` and 8 mask registers.


---

# Phase 2 result: the 32 KNC mask instructions now assemble on binutils 2.38

`binutils-2.38-k1om-mask-insns.patch` applies on top of the target patch and makes
upstream 2.38 assemble Knights Corner's mask-register instruction set **byte-identically
to Intel's assembler**:

```
ported : c5f841d1 c5f842d1 c5f843d1 c5f844d1 c5f845d1 c5f847d1 c5f898d1 c5f890d1
intel  : c5f841d1 c5f842d1 c5f843d1 c5f844d1 c5f845d1 c5f847d1 c5f898d1 c5f890d1
```

It is 42 added lines in three files:

* `opcodes/i386-gen.c` — `CPU_K1OM_FLAGS` changes from the `"unknown"` sentinel to a
  real flag set. **Reuse the existing `CpuK1OM`; do not add a new Cpu flag** — adding one
  pushes `CpuMax` past a 32-bit boundary and resizes the `i386_cpu_flags` union's
  `array[CpuNumOfUints]` from 4 to 5 words.
* `opcodes/i386-opc.tbl` — 32 instruction entries converted from Intel's 2.22 layout.
* `gas/config/tc-i386.c` — the register gates that only allowed `zmm`/`RegMask` under
  `cpuavx512f` now also accept `cpuk1om`. KNC predates AVX-512 but has its own mask and
  vector registers.

## Converting Intel's table entries to the 2.38 layout

Old: `name, operands, base_opcode, ext_opcode, opcode_length, cpu_flags, modifiers, { ops }`
New: `name, base_opcode, ext_opcode, cpu_flags, modifiers, { ops }`

so drop fields 2 and 5, then translate the modifiers:

| Intel 2.22 | binutils 2.38 | note |
|---|---|---|
| `VexOpcode=0/1/2` | `Space0F` / `Space0F38` / `Space0F3A` | |
| `VexOpcode=6` | *(none)* | Intel's no-escape map; `jknzd`/`jkzd` are unportable |
| `Vex` (bare) | `Vex=1` | == VEX128 == L0 |
| `Vex=3` | `Vex=3` | VEXScalar, unchanged |
| `VexW=1` | `VexW=1` | Intel's enum is W0=1, W1=2 — so this means **W0** |
| `IgnoreSize`, `VecDisp8` | *(drop)* | removed upstream |

2.38's own AVX-512 mask entries are near-identical templates. Note KNC's `kand` is the
**2-operand L0** form while AVX-512's `kandw` is **3-operand L1** — same opcode byte,
different encoding, so they coexist under different Cpu flags.

## ⚠️ How to regenerate the opcode tables (this cost hours)

`i386-gen` reads the opcode table **from stdin, preprocessed by cpp**. It does *not* read
`i386-opc.tbl` from `--srcdir`:

```sh
cpp -P -I <srcdir>/opcodes -I <srcdir>/include < <srcdir>/opcodes/i386-opc.tbl \
  | ./i386-gen --srcdir <srcdir>/opcodes
```

Run without stdin it silently emits a **1,198-line** `i386-tbl.h` instead of ~73,000 and
**exits 0**. gas then segfaults in `md_begin()` on *any* input, including an empty file,
which looks like a bug in whatever you changed last. Always check:

```sh
wc -l i386-tbl.h    # must be ~73k, not ~1.2k
```

## Status against Intel's testsuite

`k1omni.s` (6,980 lines, 211 mnemonics). All 32 ported mnemonics assemble with **zero
errors**. What remains is the MVEX vector ISA: 1,879 unknown mnemonics and 4,688
swizzle-syntax errors (`{cdab}`, `{float16}`, ...).

Note the earlier "14.5% of lines already assemble" figure was misleading: with
`CPU_K1OM_FLAGS` set to `"unknown"` (≈ every CPU feature, including AVX-512), KNC vector
instructions accidentally matched AVX-512 templates and would have emitted **wrong
encodings**. Making the flag set correct removes those false passes.

## Disassembly — done

`i386-dis.c` now decodes the KNC mask ops. AVX-512's 3-operand forms sit at VEX.L1, so
the L0 slots were free:

* `VEX_LEN_0F41/42/45/46/47` — filled the `Bad_Opcode` L=0 slot (`kand`, `kandn`, `kor`,
  `kxnor`, `kxor`)
* `0F43`, `0F48`, `0F49`, `0F95`, `0F97` had no table at all — added direct entries
  (`kandnr`, `kmerge2l1h/l`, `kconcath/l`)
* `0F44`, `0F90`, `0F92`, `0F93`, `0F98` needed **nothing**: AVX-512's `knotw`, `kmovw`,
  `kortestw` are already the L0 forms, i.e. the *same encoding*, so KNC's `knot`/`kmov`/
  `kortest` already decoded under the AVX-512 spelling.

Caveat: these entries decode on every x86-64 target, not just k1om. The bytes are
otherwise invalid there, so this is benign, but it is not gated.

## Final scorecard for the VEX subset

30 mnemonics ported. Verified against Intel's assembler on its own testsuite operands:

| | |
|---|---|
| **byte-identical to Intel** | **20** (all the register-only k-ops) |
| differ | 10 — `clevict0/1`, `vprefetch{0,1,2}`, `vprefetche{0,1,2}`, `vprefetchenta`, `vprefetchnta` |

The 10 that differ are the memory-operand forms. Intel's table carries **both** a VEX and
an MVEX encoding for these and its assembler picks MVEX; the port only has the VEX one:

```
clevict0 0x80(%rcx)      intel=62f17b08ae7902     ported=c5fbaeb980000000
vprefetch0 0x80(%rcx)    intel=62f17808184902     ported=c5f8188980000000
```

Intel's is the 4-byte `0x62` MVEX prefix with a **compressed disp8** (0x80/64 = 2); the
port emits 2-byte VEX with a full disp32. Decoding Intel's `62 f1 7b 08`: P1 = `0x7b` has
bit 2 clear, which is exactly what distinguishes **MVEX from EVEX** — AVX-512 sets that
bit. That single bit is the crux of why 2.38's `build_evex_prefix()` cannot be reused
as-is.

## What remains: MVEX

* **10** memory-operand instructions above — need MVEX prefix emission plus disp8
  compression, but *no* swizzle machinery. The tractable next step.
* **270** vector instructions — need the full apparatus: Intel's **684-line** swizzle /
  conversion table (36 entries), ~300 lines of `i.vec`/swizzle logic, 15 reintroduced
  opcode-modifier flags (`VecType`, `VecOp`, `VecESize`, `VecMem`, `VecMemShift`,
  `VecDisp8`, `NoSwizzle`, `NoEH`, `SAEOnly`, `NoRounding`, `NoBroadcast`,
  `BroadcastOnly`, `VecSIB`, `VexOpcode`, `IgnoreSize`), and a parser for `{cdab}`,
  `{float16}`, `{uint8}` and friends — against a `tc-i386.c` that upstream restructured
  around EVEX.
* **2** instructions (`jknzd`, `jkzd`) are unportable without adding Intel's no-escape
  opcode map.



---

# Validation against Intel's own gas testsuite

Intel's MPSS binutils ships a DejaGnu testsuite for k1om, and the `.d` files carry the
**expected disassembly**, which is a far better oracle than diffing against Intel's
assembler by hand. DejaGnu is not installed on the build box, so
`run-k1om-dump-tests.py` here is a minimal stand-in for `run_dump_test`: it reads the
`#as:` / `#objdump:` / `#source:` headers and matches the remaining lines as regexes.

```sh
python3 run-k1om-dump-tests.py k1om.d k1om.s <target>-as <target>-objdump
```

Results for the ported binutils 2.38:

| test | result | note |
|---|---|---|
| `k1om` | **OK 237/237** | identical to Intel's own assembler as control |
| `nops-1-k1om` | PARTIAL 129/135 | nop-padding tuning, see below |
| `nops-4-k1om` | PARTIAL 160/187 | same |
| `k1omni` | fails | the MVEX vector ISA, not ported |
| `k1omni-branch` | fails | `jknzd`/`jkzd`, unportable opcode map |

**`k1om` passing 237/237 is the meaningful result**: the scalar k1om target validates
against Intel's own expected output, byte for byte.

## The nops tests are a tuning divergence, not a defect

Intel's 2.22 emits one 15-byte nop built from six `0x66` prefixes; 2.38 splits the same
padding into an 11-byte plus a 4-byte nop, because upstream deliberately limits long
prefix chains. 2.38 still carries `case PROCESSOR_K1OM:` in its nop-pattern selection
(`alt_patt`), so k1om tuning is maintained upstream -- only the patterns changed. Both
paddings are valid.

## Upstream's own k1om test is misleading

`i386.exp` in 2.38 runs `run_dump_test "k1om"`, but upstream's `k1om.d` overrides the
source with `#source: x86_64.s` -- a generic x86-64 file. That only assembles under
`-march=k1om` because upstream had neutered `CPU_K1OM_FLAGS` to the `"unknown"` sentinel,
enabling every feature. With a correct flag set it fails, and **so does Intel's own
assembler** on the same input (14 errors).

Checked line by line, the port and Intel's assembler reject **the same 14 lines** of
`x86_64.s`, differing only in message wording and in two Intel-syntax test-register moves
(`mov eax, tr1`) that Intel rejects and the port accepts. KNC genuinely lacks SSE2 and
`cmpxchg16b`, so rejecting them is correct -- upstream's passing test was the anomaly.
