#!/usr/bin/env python3
"""Minimal replacement for DejaGnu's run_dump_test: assemble a .s, objdump it,
and match the output against the regexes in the .d file."""
import re, subprocess, sys, os, tempfile

def run(dfile, sfile, asm, objdump):
    hdr, pats = {}, []
    for line in open(dfile, errors='replace'):
        line = line.rstrip('\n')
        m = re.match(r'#(\w+):\s*(.*)', line)
        if m:
            hdr[m.group(1)] = m.group(2); continue
        if line.startswith('#'):
            continue
        if line.strip():
            pats.append(line)

    asflags   = hdr.get('as', '').split()
    odflags   = hdr.get('objdump', '-dw').split()
    src       = hdr.get('source', sfile)
    if not os.path.isabs(src):
        src = os.path.join(os.path.dirname(dfile), src)

    with tempfile.TemporaryDirectory() as td:
        obj = os.path.join(td, 'a.o')
        p = subprocess.run([asm] + asflags + ['-o', obj, src],
                           capture_output=True, text=True)
        if p.returncode:
            return ('ASSEMBLE_FAIL', p.stderr.strip().splitlines()[:3], 0, len(pats))
        p = subprocess.run([objdump] + odflags + [obj], capture_output=True, text=True)
        out = [l for l in p.stdout.splitlines() if l.strip()]

    # match patterns in order, allowing skips (as run_dump_test does not)
    matched, oi = 0, 0
    fails = []
    for pat in pats:
        try:
            rx = re.compile(pat.strip() + r'\s*$')
        except re.error:
            rx = None
        found = False
        while oi < len(out):
            line = out[oi]; oi += 1
            if rx and rx.match(line.strip()):
                found = True; break
        if found:
            matched += 1
        else:
            if len(fails) < 3:
                fails.append(pat.strip()[:70])
            oi = 0   # restart scan for the next pattern
    return ('OK' if matched == len(pats) else 'PARTIAL', fails, matched, len(pats))

if __name__ == '__main__':
    dfile, sfile, asm, objdump = sys.argv[1:5]
    status, fails, m, t = run(dfile, sfile, asm, objdump)
    print(f'{os.path.basename(dfile):<24} {status:<14} matched {m}/{t}')
    for f in fails:
        print(f'    unmatched: {f}')
