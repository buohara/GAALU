#!/usr/bin/env python3
"""
Parse failures.txt lines and decode ga_multivector_t 512-bit hex words into 32
signed Q5.11 lanes, print floats and per-component deltas between Act and Exp.

Usage:
  python3 scripts/decode_failures.py [failures.txt] [threshold_raw]
"""

import sys
import re
from pathlib import Path

FIELD_NAMES = [
    "scalar","e1","e2","e3","e4","e5",
    "e12","e13","e23","e14","e24","e34",
    "e15","e25","e35","e45","e123","e124",
    "e134","e234","e125","e135","e235","e145",
    "e245","e345","e1234","e1235","e1245","e1345",
    "e2345","e12345"
]

FP_FRAC = 11
LSB     = 1.0 / (1 << FP_FRAC)

DEFAULT_THRESH = 100

def signed16(v):

    v &= 0xffff
    return v - 0x10000 if (v & 0x8000) else v

def decode_mv(hex128):

    if len(hex128) != 128:
        raise ValueError(f"expected 128-hex chars, got {len(hex128)}")
    
    words   = [hex128[i:i+4] for i in range(0, 128, 4)]
    vals    = [int(w, 16) for w in words]
    signed  = [signed16(v) for v in vals]
    floats  = [s * LSB for s in signed]
    
    return list(zip(words, signed, floats))

def decode_mv_to_floats(hex128):

    """Decode multivector to list of float values only"""
    decoded = decode_mv(hex128)
    return [f for _, _, f in decoded]

def parse_failures(path):

    txt = Path(path).read_text()
    pat = re.compile(
        r"Test\s+(\d+):\s+Op\s*-\s*(\d+)\s+A\s*-\s*([0-9a-fA-F]{128})\s+B\s*-\s*([0-9a-fA-F]{128})\s+Act\s*-\s*([0-9a-fA-F]{128})\s+Exp\s*-\s*([0-9a-fA-F]{128})",
        re.MULTILINE,
    )
    return list(pat.finditer(txt))

def print_test(m, thresh=DEFAULT_THRESH):

    testno = m.group(1)
    op = m.group(2)
    a_h = m.group(3)
    b_h = m.group(4)
    act_h = m.group(5)
    exp_h = m.group(6)

    try:

        A_floats = decode_mv_to_floats(a_h)
        B_floats = decode_mv_to_floats(b_h)
        ACT_floats = decode_mv_to_floats(act_h)
        EXP_floats = decode_mv_to_floats(exp_h)
        
        A = decode_mv(a_h)
        B = decode_mv(b_h)
        ACT = decode_mv(act_h)
        EXP = decode_mv(exp_h)

    except ValueError as e:

        print(f"Test {testno}: parse error: {e}")
        return

    print(f"\n=== Test {testno}  Op={op} ===")
    
    print("\nOperand A:")
    for idx, (name, val) in enumerate(zip(FIELD_NAMES, A_floats)):
        if abs(val) > 1e-6:
            print(f"  {name:8}: {val:12.6f}")
    
    print("\nOperand B:")
    for idx, (name, val) in enumerate(zip(FIELD_NAMES, B_floats)):
        if abs(val) > 1e-6:
            print(f"  {name:8}: {val:12.6f}")
    
    print("\nExpected Result:")
    for idx, (name, val) in enumerate(zip(FIELD_NAMES, EXP_floats)):
        if abs(val) > 1e-6:
            print(f"  {name:8}: {val:12.6f}")
    
    print("\nActual Result:")
    for idx, (name, val) in enumerate(zip(FIELD_NAMES, ACT_floats)):
        if abs(val) > 1e-6:
            print(f"  {name:8}: {val:12.6f}")

    diffs = []
    
    for idx, name in enumerate(FIELD_NAMES):

        exp_w, exp_s, exp_f = EXP[idx]
        act_w, act_s, act_f = ACT[idx]
        d_raw = act_s - exp_s
        if abs(d_raw) > thresh:
            d_f = act_f - exp_f
            diffs.append((idx, name, exp_s, act_s, d_raw, exp_f, act_f, d_f))

    print(f"\nLanes with |delta_raw| > {thresh}:")
    if not diffs:
        print("  None")
        return

    print("-" * 85)
    header = f"{'lane':8} {'exp_raw':>8} {'act_raw':>8} {'d_raw':>8} {'exp_f':>12} {'act_f':>12} {'d_f':>12}"
    print(header)
    print("-" * 85)

    for (idx, name, exp_s, act_s, d_raw, exp_f, act_f, d_f) in diffs:
        print(f"{name:8} {exp_s:8d} {act_s:8d} {d_raw:8d} {exp_f:12.6f} {act_f:12.6f} {d_f:12.6f}")
    print("-" * 85)
    print()


def main():
    
    path = sys.argv[1] if len(sys.argv) > 1 else "failures.txt"
    thresh = DEFAULT_THRESH
    if len(sys.argv) > 2:
        try:
            thresh = int(sys.argv[2])
        except ValueError:
            print("Invalid threshold argument, using default", DEFAULT_THRESH)
            thresh = DEFAULT_THRESH

    iters = parse_failures(path)
    if not iters:
        print("No test entries found in", path)
        return
    for m in iters:
        print_test(m, thresh)


if __name__ == "__main__":
    main()