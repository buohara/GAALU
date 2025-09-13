#!/usr/bin/env python3
import os, argparse

basis = ["e1","e2","e3","eo","ei"]
idx_of = {name:i for i,name in enumerate(basis)}

G = [[0]*5 for _ in range(5)]
for v in ["e1","e2","e3"]:
    i = idx_of[v]; G[i][i] = 1
G[idx_of["eo"]][idx_of["ei"]] = -1
G[idx_of["ei"]][idx_of["eo"]] = -1

def positions(mask:int):

    return [i for i in range(5) if (mask >> i) & 1]

def grade(mask:int) -> int:

    return bin(mask).count("1")

def popcount_less(mask:int, idx:int) -> int:

    return sum(1 for j in range(idx) if (mask >> j) & 1)

def mask_to_name(mask:int) -> str:

    if mask == 0: return "scalar"
    s = "e"
    for i in range(5):
        if (mask >> i) & 1:
            s += basis[i][1:]
    return s

def mul_vec_blade(i:int, bm:int):

    out = {}
    js = positions(bm)

    for t, j in enumerate(js):

        gij = G[i][j]
        if gij == 0: continue
        sgn = -1 if (t & 1) else 1
        rm = bm ^ (1 << j)
        out[rm] = out.get(rm, 0) + sgn * gij

    if ((bm >> i) & 1) == 0:

        m = popcount_less(bm, i)
        sgn = -1 if (m & 1) else 1
        rm = bm ^ (1 << i)
        out[rm] = out.get(rm, 0) + sgn

    return out

def build_gp_table():

    table = {rm: {} for rm in range(32)}

    for am in range(32):
        for bm in range(32):
            
            terms = mul_blade(am, bm)

            for rm, c in terms.items():

                if c == 0: continue
                key = (am, bm)
                table[rm][key] = table[rm].get(key, 0) + c

    return table

def filter_table(table, keep_fn):
    
    out = {rm: {} for rm in range(32)}
    for rm in range(32):
        for (am, bm), c in table[rm].items():
            if keep_fn(am, bm, rm):
                out[rm][(am, bm)] = out[rm].get((am, bm), 0) + c
    return out

def make_wedge_table(table):

    return filter_table(table, lambda am,bm,rm: grade(rm) == grade(am) + grade(bm))

def make_dot_table(table, kind:str):

    if kind == "hestenes":
        return filter_table(table, lambda am,bm,rm: grade(rm) == abs(grade(am) - grade(bm)))
    if kind == "lcont":
        return filter_table(table, lambda am,bm,rm: grade(am) <= grade(bm) and grade(rm) == (grade(bm) - grade(am)))
    if kind == "rcont":
        return filter_table(table, lambda am,bm,rm: grade(bm) <= grade(am) and grade(rm) == (grade(am) - grade(bm)))
    raise ValueError("unknown dot kind")

def emit_sv_mac(table):

    lines = []
    lines.append("// Auto-generated (MAC/Q5.11). Uses helpers: addQ511, subQ511, mulQ511, mac, macSub")
    lines.append("result = '0;")

    for rm in range(32):

        cname = mask_to_name(rm)
        items = sorted(table[rm].items(), key=lambda kv: (kv[0][0], kv[0][1]))
        
        for (am, bm), c in items:

            if c == 0: continue
            an = mask_to_name(am)
            bn = mask_to_name(bm)
            op = "mac" if c > 0 else "macSub"
            for _ in range(abs(c)):
                lines.append(f"result.{cname} = {op}(result.{cname}, a.{an}, b.{bn});")
        lines.append("")
    return "\n".join(lines)

def emit_sv_norm():

    lines = ["// Auto-generated norm-squared (Q5.11) into acc (signed [FP_W-1:0])", "acc = '0;"]
    for rm in range(32):
        cname = mask_to_name(rm)
        lines.append(f"acc = mac(acc, a.{cname}[FP_W-1:0], a.{cname}[FP_W-1:0]);")
    lines.append("")
    return "\n".join(lines)

def sanity_check():

    def m(am,bm): return mul_blade(am,bm)
    e1  = 1<<idx_of["e1"]
    e2  = 1<<idx_of["e2"]
    e3  = 1<<idx_of["e3"]
    eo  = 1<<idx_of["eo"]
    ei  = 1<<idx_of["ei"]
    e12 = e1|e2
    e13 = e1|e3
    e23 = e2|e3
    e123= e1|e2|e3

    assert m(e1,e1).get(0,0) == 1
    assert m(eo,ei).get(0,0) == -1
    assert m(ei,eo).get(0,0) == -1
    assert m(eo,eo).get(0,0) == 0
    assert m(ei,ei).get(0,0) == 0
    assert m(e12,e12).get(0,0) == -1
    assert m(e123,e123).get(0,0) == -1

def write_text(path, text):

    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"Wrote {path}")

EVEN_COMPONENT_ORDER = [
    0,                      # scalar
    # grade 2 (10)
    # masks (bit order e1,e2,e3,eo,ei) -> integer masks
    # We'll enumerate by mask value (already natural in earlier code 0..31)
]
# Build programmatically later so no hard-coding mistakes.

def is_even_mask(m:int) -> bool:
    return grade(m) % 2 == 0

def collect_even_masks():
    return [m for m in range(32) if is_even_mask(m)]

def even_lane_order():
    """
    Returns ordered list of masks representing the 16 even blades:
      scalar,
      e12 e13 e23 e1o e2o e3o e1i e2i e3i eoi,
      e123o e123i e12oi e13oi e23oi
    """
    names = ["scalar","e12","e13","e23","e1o","e2o","e3o",
             "e1i","e2i","e3i","eoi",
             "e123o","e123i","e12oi","e13oi","e23oi"]
    name_to_mask = {mask_to_name(m):m for m in range(32)}
    return [name_to_mask[n] for n in names]

def lane_enum_name(mask:int) -> str:
    n = mask_to_name(mask)
    return "L_" + n.upper()

def emit_sv_even_pack_unpack():
    lanes = even_lane_order()
    lines = []
    lines.append("// Even subalgebra lane mapping (16 lanes)")
    lines.append("localparam int EVEN_LANES = 16;")
    lines.append("typedef enum int unsigned {")
    lines.append(",\n".join(["  %s = %d" % (lane_enum_name(m), i) for i,m in enumerate(lanes)]))
    lines.append("} even_lane_e;")
    lines.append("")
    lines.append("function automatic void pack_even(input ga_multivector_t mv,")
    lines.append("                                  output logic signed [FP_W-1:0] lane[EVEN_LANES]);")
    for i,m in enumerate(lanes):
        lines.append(f"  lane[{lane_enum_name(m)}] = mv.{mask_to_name(m)};")
    lines.append("endfunction")
    lines.append("")
    lines.append("function automatic ga_multivector_t unpack_even(input logic signed [FP_W-1:0] lane[EVEN_LANES]);")
    lines.append("  ga_multivector_t mv = '0;")
    for i,m in enumerate(lanes):
        lines.append(f"  mv.{mask_to_name(m)} = lane[{lane_enum_name(m)}];")
    lines.append("  return mv;")
    lines.append("endfunction")
    lines.append("")
    lines.append("function automatic logic signed [FP_W-1:0] sat16_q511(longint signed acc_raw);")
    lines.append("  longint signed r = acc_raw + (1 <<< (FP_FRAC-1));")
    lines.append("  longint signed s = r >>> FP_FRAC;")
    lines.append("  longint signed maxv = (1 <<< (FP_W-1)) - 1;")
    lines.append("  longint signed minv = -(1 <<< (FP_W-1));")
    lines.append("  if (s > maxv) s = maxv;")
    lines.append("  if (s < minv) s = minv;")
    lines.append("  return logic'(s[FP_W-1:0]);")
    lines.append("endfunction")
    lines.append("")
    return "\n".join(lines)

def restrict_gp_even(table):
    """Keep only even result masks and even operand blades."""
    even = set(even_lane_order())
    out = {}
    for rm, terms in table.items():
        if rm not in even: continue
        filtered = {}
        for (am,bm), c in terms.items():
            if am in even and bm in even and c:
                filtered[(am,bm)] = c
        if filtered:
            out[rm] = filtered
    return out

def emit_sv_even_op_func(name:str, table):
    """
    Emit a lane-based deferred accumulate function for operation 'name'
    (geometricProduct_even, wedgeProduct_even, dotProduct_even).
    'table' same structure as gp/wedge/dot tables but already restricted.
    """
    lanes = even_lane_order()
    lines = []
    lines.append(f"function automatic ga_multivector_t {name}_even(")
    lines.append("  ga_multivector_t a,")
    lines.append("  ga_multivector_t b"); lines.append(");")
    lines.append("  longint signed acc[EVEN_LANES];")
    lines.append("  logic signed [FP_W-1:0] al[EVEN_LANES], bl[EVEN_LANES];")
    lines.append("  logic signed [FP_W-1:0] out_lane[EVEN_LANES];")
    lines.append("  for (int i=0;i<EVEN_LANES;i++) acc[i] = 0;")
    lines.append("  pack_even(a, al);")
    lines.append("  pack_even(b, bl);")
    lines.append("`define ACCP(idx, xa, xb) acc[idx] += longint'($signed(xa)) * longint'($signed(xb))")
    lines.append("`define ACCN(idx, xa, xb) acc[idx] -= longint'($signed(xa)) * longint'($signed(xb))")
    
    for rm in lanes:
        
        if rm not in table: continue
        ridx = lane_enum_name(rm)
        terms = sorted(table[rm].items())
        for (am,bm), c in terms:
            op = "`ACCP" if c > 0 else "`ACCN"
            for _ in range(abs(c)):
                lines.append(f"  {op}({ridx}, al[{lane_enum_name(am)}], bl[{lane_enum_name(bm)}]);")
        lines.append("")
    
    lines.append("`undef ACCP")
    lines.append("`undef ACCN")
    lines.append("  for (int i=0;i<EVEN_LANES;i++) out_lane[i] = sat16_q511(acc[i]);")
    lines.append("  return unpack_even(out_lane);")
    lines.append("endfunction\n")
    
    return "\n".join(lines)

def emit_sv_even_norm():
    """
    Norm-squared (accumulate all even lanes^2 into scalar lane only).
    Produces a ga_multivector_t with only scalar set.
    """
    lanes = even_lane_order()
    lines = []
    lines.append("function automatic ga_multivector_t norm_even(ga_multivector_t a);")
    lines.append("  longint signed acc_scalar = 0;")
    lines.append("  logic signed [FP_W-1:0] al[EVEN_LANES];")
    lines.append("  pack_even(a, al);")
    lines.append("  for (int i=0;i<EVEN_LANES;i++) begin")
    lines.append("    acc_scalar += longint'($signed(al[i])) * longint'($signed(al[i]));")
    lines.append("  end")
    lines.append("  ga_multivector_t r = '0;")
    lines.append("  r.scalar = sat16_q511(acc_scalar);")
    lines.append("  return r;")
    lines.append("endfunction\n")
    return "\n".join(lines)

def mul_vec_into_mask(vec_i:int, mask:int, b_orig_mask:int):
    """
    Multiply basis vector vec_i (geometric product) into an existing mask.
    Contractions are ONLY allowed with vector bits that were originally in B
    (b_orig_mask) so we never contract against previously inserted A vectors.
    Returns dict: new_mask -> coefficient (+/-1, or metric value).
    """
    out = {}

    tpos = positions(mask)

    for t, j in enumerate(tpos):

        if not (b_orig_mask >> j) & 1:
            continue
        gij = G[vec_i][j]
        if gij == 0:
            continue
        sgn = -1 if (t & 1) else 1
        new_mask = mask ^ (1 << j)
        out[new_mask] = out.get(new_mask, 0) + sgn * gij

    if ((mask >> vec_i) & 1) == 0:

        m = popcount_less(mask, vec_i)
        sgn = -1 if (m & 1) else 1
        new_mask = mask ^ (1 << vec_i)
        out[new_mask] = out.get(new_mask, 0) + sgn

    return out

def mul_blade(mask_a:int, mask_b:int):
    """
    Geometric product of two (pure wedge) blades A and B.
    We sequence insertion of A's vectors (right-to-left) into B's mask.
    Contractions only occur with original B bits, never between A's own bits.
    """

    if mask_a == 0:
        return {mask_b:1}
    if mask_b == 0:
        return {mask_a:1}

    b_orig_mask = mask_b
    terms = {mask_b:1}
    Avec = positions(mask_a)

    for vi in reversed(Avec):
        next_terms = {}
        for m, coef in terms.items():
            contribs = mul_vec_into_mask(vi, m, b_orig_mask)
            for nm, kc in contribs.items():
                if kc == 0:
                    continue
                next_terms[nm] = next_terms.get(nm, 0) + coef * kc
        # Prune zero coeffs
        terms = {m:c for m,c in next_terms.items() if c != 0}

    return terms

def main():

    ap = argparse.ArgumentParser(description="Generate CGA null-basis GA ops (SV MAC Q5.11).")
    ap.add_argument("-sv-mul")
    ap.add_argument("-sv-wedge")
    ap.add_argument("-sv-dot")
    ap.add_argument("-sv-norm")
    ap.add_argument("--dot-kind", choices=["hestenes","lcont","rcont"], default="hestenes")
    ap.add_argument("--no-sanity", action="store_true")
    ap.add_argument("-even", action="store_true",
                    help="Emit even subalgebra lane-based (SV only) versions for mul/wedge/dot/norm")
    args = ap.parse_args()

    if not args.no_sanity:
        sanity_check()

    gp = build_gp_table()
    wedge = make_wedge_table(gp)
    dot = make_dot_table(gp, args.dot_kind)

    if args.even:

        header = emit_sv_even_pack_unpack()

        gp_e   = restrict_gp_even(gp)
        wedge_e= restrict_gp_even(wedge)
        dot_e  = restrict_gp_even(dot)

        if args.sv_mul:
            write_text(args.sv_mul,
                header + "\n" + emit_sv_even_op_func("geometricProduct", gp_e))
        if args.sv_wedge:
            write_text(args.sv_wedge,
                header + "\n" + emit_sv_even_op_func("wedgeProduct", wedge_e))
        if args.sv_dot:
            write_text(args.sv_dot,
                header + "\n" + emit_sv_even_op_func("dotProduct", dot_e))
        if args.sv_norm:
            write_text(args.sv_norm,
                header + "\n" + emit_sv_even_norm())
        return

    if args.sv_mul:   write_text(args.sv_mul,   emit_sv_mac(gp))
    if args.sv_wedge: write_text(args.sv_wedge, emit_sv_mac(make_wedge_table(gp)))
    dot = make_dot_table(gp, args.dot_kind)
    if args.sv_dot:   write_text(args.sv_dot,   emit_sv_mac(dot))
    if args.sv_norm:  write_text(args.sv_norm,  emit_sv_norm())

if __name__ == "__main__":
    main()