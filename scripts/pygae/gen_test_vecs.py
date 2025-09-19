import argparse, sys, pathlib
import random
from typing import List, Tuple

try:
    from clifford.g3c import layout, blades
except ImportError:
    print("clifford not installed; pip install 'clifford[extras]'", file=sys.stderr)
    sys.exit(1)

OPCODES = {'add':0,'sub':1,'mul':2,'wedge':3,'dot':4}

e1 = blades['e1']; e2 = blades['e2']; e3 = blades['e3']
e4 = blades['e4']; e5 = blades['e5']

# Use e4 and e5 directly instead of null basis
vec_map_canon = {'1': e1, '2': e2, '3': e3, '4': e4, '5': e5}

def mv_from_name_canon(name: str):
    if name == 'scalar':
        return layout.scalar
    mv = layout.scalar
    for ch in name[1:]:
        mv = mv ^ vec_map_canon[ch]
    return mv

# HARDCASED_PAIRS kept for reference (now superseded by full blade-pair expansion):
# HARDCASED_PAIRS = [
#     ('e1','e1'),
#     ('e1','e2'),
#     ('e2','e2'),
#     ('e12','e12'),
#     ('e12','e13'),
#     ('e4','e4'),
#     ('e5','e5'),
#     ('e4','e5'),
#     ('e14','e15'),
#     ('e14','e24'),
#     ('e1234','e1235'),
#     ('e1245','e1245'),
# ]

FRAC = 11
MIN_I = - (1 << 15)
MAX_I =   (1 << 15) - 1

def float_to_q511(x: float) -> int:
    s = int(round(x * (1<<FRAC)))
    if s > MAX_I: s = MAX_I
    if s < MIN_I: s = MIN_I
    return s & 0xFFFF

def hex16(i: int) -> str:
    return f"{i & 0xFFFF:04x}"

a_lanes = [
    'scalar',
    'e1','e2','e3','e4','e5', 
    'e12','e13','e23',
    'e14','e24','e34',
    'e15','e25','e35',
    'e45',
    'e123',
    'e124','e134','e234',
    'e125','e135','e235',
    'e145','e245','e345',
    'e1234','e1235',
    'e1245','e1345','e2345',
    'e12345',
]

blade_names = [
    'scalar',
    'e1','e2','e3','e4','e5',
    'e12','e13','e23',
    'e14','e24','e34',
    'e15','e25','e35',
    'e45',
    'e123',
    'e124','e134','e234',
    'e125','e135','e235',
    'e145','e245','e345',
    'e1234','e1235',
    'e1245','e1345','e2345','e12345'
]

even_blade_names = [
    'scalar',
    'e12','e13','e23',
    'e14','e24','e34',
    'e15','e25','e35',
    'e45',
    'e1234','e1235','e1245','e1345','e2345',
]

basis_mvs_canon = [mv_from_name_canon(n) for n in blade_names]
name_to_index_canon = {}

for n, mvb in zip(blade_names, basis_mvs_canon):
    arr = mvb.value
    nz = [i for i, v in enumerate(arr) if abs(v) > 1e-12]
    name_to_index_canon[n] = nz[0] if nz else 0

canon_basis_map = {n: mvb for n, mvb in zip(blade_names, basis_mvs_canon)}

def coeffs_canon(mv) -> dict:

    arr = mv.value
    return {n: float(arr[name_to_index_canon[n]]) for n in blade_names}

def coeff_array_rtl(mv) -> List[int]:

    c = coeffs_canon(mv)
    g = lambda k: c.get(k, 0.0)

    lanes = {name: g(name) for name in a_lanes}
    
    return [float_to_q511(lanes[name]) for name in a_lanes]

def even_part(mv):

    return mv(0) + mv(2) + mv(4)

def apply_op(opcode: int, A, B):

    if opcode == OPCODES['add']: return A + B
    if opcode == OPCODES['sub']: return A - B
    if opcode == OPCODES['mul']: return A * B
    if opcode == OPCODES['wedge']: return A ^ B
    if opcode == OPCODES['dot']: return A << B
    raise ValueError('Unsupported opcode')

def main():

    ap = argparse.ArgumentParser()
    ap.add_argument('-n','--num-random', type=int, default=0)
    ap.add_argument('-o','--out-dir', default='.')
    ap.add_argument('-even', action='store_true')
    ap.add_argument('--seed', type=int, default=1)
    args = ap.parse_args()

    outdir = pathlib.Path(args.out_dir)
    outdir.mkdir(parents=True, exist_ok=True)

    f_in = open(outdir/'cga_test_inputs.mem','w')
    f_out = open(outdir/'cga_test_outputs.mem','w')
    f_ctl = open(outdir/'cga_test_control.mem','w')

    f_in_e = f_out_e = f_ctl_e = f_idx_e = None

    if args.even:

        f_in_e = open(outdir/'cga_test_inputs_even.mem','w')
        f_out_e = open(outdir/'cga_test_outputs_even.mem','w')
        f_ctl_e = open(outdir/'cga_test_control_even.mem','w')
        f_idx_e = open(outdir/'cga_test_index_even.txt','w')

    ops = [OPCODES[k] for k in ('add','sub','mul','wedge','dot')]

    basis_for_pairs = even_blade_names if args.even else blade_names

    named_pairs = [
        (a, b, mv_from_name_canon(a), mv_from_name_canon(b))
        for a in basis_for_pairs for b in basis_for_pairs
    ]

    even_line = 0

    if args.num_random and args.num_random > 0:

        random.seed(args.seed)
        scale = 2.0

        for ri in range(args.num_random):

            A_rand = layout.scalar * 0.0
            B_rand = layout.scalar * 0.0

            for nm in even_blade_names:

                coef_a = random.uniform(-scale, scale)
                coef_b = random.uniform(-scale, scale)
                basis_mv = canon_basis_map[nm]
                A_rand = A_rand + coef_a * basis_mv
                B_rand = B_rand + coef_b * basis_mv

            for opcode in ops:

                R = apply_op(opcode, A_rand, B_rand)

                A_q = coeff_array_rtl(A_rand)
                B_q = coeff_array_rtl(B_rand)
                R_q = coeff_array_rtl(R)

                f_in.write(''.join(hex16(x) for x in A_q))
                f_in.write(''.join(hex16(x) for x in B_q))
                f_in.write('\n')
                f_out.write(''.join(hex16(x) for x in R_q))
                f_out.write('\n')
                f_ctl.write(f"{opcode}\n")

                if args.even:

                    A_e = even_part(A_rand)
                    B_e = even_part(B_rand)
                    R_e = even_part(apply_op(opcode, A_e, B_e))
                    A_eq = coeff_array_rtl(A_e)
                    B_eq = coeff_array_rtl(B_e)

                    if not (all(v == 0 for v in A_eq) and all(v == 0 for v in B_eq)):
                        
                        R_eq = coeff_array_rtl(R_e)
                        f_in_e.write(''.join(hex16(x) for x in A_eq))
                        f_in_e.write(''.join(hex16(x) for x in B_eq))
                        f_in_e.write('\n')
                        f_out_e.write(''.join(hex16(x) for x in R_eq))
                        f_out_e.write('\n')
                        f_ctl_e.write(f"{opcode}\n")
                        f_idx_e.write(f"{even_line}: RND op={opcode} idx={ri}\n")
                        even_line += 1

    f_in.close(); f_out.close(); f_ctl.close()

    if args.even:

        f_in_e.close(); f_out_e.close(); f_ctl_e.close(); f_idx_e.close()

if __name__ == '__main__':
    main()
