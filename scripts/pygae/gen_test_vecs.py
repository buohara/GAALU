import argparse, sys, pathlib
from typing import List, Tuple

try:
    from clifford.g3c import layout, blades
except ImportError:
    print("clifford not installed; pip install 'clifford[extras]'", file=sys.stderr)
    sys.exit(1)

OPCODES = {'add':0,'sub':1,'mul':2,'wedge':3,'dot':4}

e1 = blades['e1']; e2 = blades['e2']; e3 = blades['e3']
_e4 = blades['e4']; _e5 = blades['e5']

eo = 0.5 * (_e4 - _e5)
ei = (_e4 + _e5)

vec_map_null = {'1': e1, '2': e2, '3': e3, '4': eo, '5': ei}

def mv_from_name_null(name: str):

    if name == 'scalar':
        return layout.scalar
    mv = layout.scalar
    for ch in name[1:]:
        mv = mv * vec_map_null[ch]
    return mv

HARDCASED_PAIRS = [
    ('e1','e1'),
    ('e1','e2'),
    ('e2','e2'),
    ('e12','e12'),
    ('e12','e13'),
    ('e4','e4'),
    ('e5','e5'),
    ('e4','e5'),
    ('e14','e15'),
    ('e14','e24'),
    ('e1234','e1235'),
    ('e1245','e1245'),
]

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
    'e1','e2','e3','eo','ei',
    'e12','e13','e23',
    'e1o','e2o','e3o',
    'e1i','e2i','e3i',
    'eoi',
    'e123',
    'e12o','e13o','e23o',
    'e12i','e13i','e23i',
    'e1oi','e2oi','e3oi',
    'e123o','e123i',
    'e12oi','e13oi','e23oi',
    'e123oi',
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

vec_map_canon = {'1': e1, '2': e2, '3': e3, '4': _e4, '5': _e5}

def mv_from_name_canon(name: str):

    if name == 'scalar':
        return layout.scalar
    mv = layout.scalar
    for ch in name[1:]:
        mv = mv * vec_map_canon[ch]
    return mv

basis_mvs_canon = [mv_from_name_canon(n) for n in blade_names]
name_to_index_canon = {}

for n, mvb in zip(blade_names, basis_mvs_canon):

    arr = mvb.value
    nz = [i for i, v in enumerate(arr) if abs(v) > 1e-12]
    name_to_index_canon[n] = nz[0] if nz else 0

def coeffs_canon(mv) -> dict:

    arr = mv.value
    return {n: float(arr[name_to_index_canon[n]]) for n in blade_names}

def coeff_array_rtl(mv) -> List[int]:

    c = coeffs_canon(mv)
    g = lambda k: c.get(k, 0.0)

    lanes = {
        'scalar': g('scalar'),
        'e1': g('e1'), 'e2': g('e2'), 'e3': g('e3'),
        'eo': 0.5*(g('e4') - g('e5')),
        'ei': g('e4') + g('e5'),
        'e12': g('e12'), 'e13': g('e13'), 'e23': g('e23'),
        'e1o': 0.5*(g('e14') - g('e15')),
        'e2o': 0.5*(g('e24') - g('e25')),
        'e3o': 0.5*(g('e34') - g('e35')),
        'e1i': -(g('e14') + g('e15')),
        'e2i': -(g('e24') + g('e25')),
        'e3i': -(g('e34') + g('e35')),
        'eoi': -(g('e45')),
        'e123': g('e123'),
        'e12o': 0.5*(g('e124') - g('e125')),
        'e13o': 0.5*(g('e134') - g('e135')),
        'e23o': 0.5*(g('e234') - g('e235')),
        'e12i': -(g('e124') + g('e125')),
        'e13i': -(g('e134') + g('e135')),
        'e23i': -(g('e234') + g('e235')),
        'e1oi': -(g('e145')), 'e2oi': -(g('e245')), 'e3oi': -(g('e345')),
        'e123o': 0.5*(g('e1234') - g('e1235')),
        'e123i': -(g('e1234') + g('e1235')),
        'e12oi': -(g('e1245')), 'e13oi': -(g('e1345')), 'e23oi': -(g('e2345')),
        'e123oi': -(g('e12345')),
    }
    return [float_to_q511(lanes[name]) for name in a_lanes]

def even_part(mv):
    return mv(0) + mv(2) + mv(4)

def apply_op(opcode: int, A, B):

    if opcode == OPCODES['add']: return A + B
    if opcode == OPCODES['sub']: return A - B
    if opcode == OPCODES['mul']: return A * B
    if opcode == OPCODES['wedge']: return A ^ B
    if opcode == OPCODES['dot']: return A | B
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

    named_pairs = [(a,b,mv_from_name_null(a), mv_from_name_null(b)) for (a,b) in HARDCASED_PAIRS]
    even_line = 0

    for (A_name,B_name,A,B) in named_pairs:
        for opcode in ops:

            Bu = B
            R = apply_op(opcode, A, Bu)

            A_q = coeff_array_rtl(A)
            B_q = coeff_array_rtl(Bu)
            R_q = coeff_array_rtl(R)

            f_in.write(''.join(hex16(x) for x in A_q))
            f_in.write(''.join(hex16(x) for x in B_q))
            f_in.write('\n')
            f_out.write(''.join(hex16(x) for x in R_q))
            f_out.write('\n')
            f_ctl.write(f"{opcode}\n")

            if args.even:

                A_e = even_part(A)
                B_e = even_part(Bu)
                R_e = even_part(apply_op(opcode, A_e, B_e))
                A_eq = coeff_array_rtl(A_e)
                B_eq = coeff_array_rtl(B_e)

                if all(v == 0 for v in A_eq) and all(v == 0 for v in B_eq):
                    continue

                R_eq = coeff_array_rtl(R_e)
                f_in_e.write(''.join(hex16(x) for x in A_eq))
                f_in_e.write(''.join(hex16(x) for x in B_eq))
                f_in_e.write('\n')
                f_out_e.write(''.join(hex16(x) for x in R_eq))
                f_out_e.write('\n')
                f_ctl_e.write(f"{opcode}\n")
                # Log non-zero lane names and values for A and B
                a_nz = [f"{n}={hex16(v)}" for n,v in zip(a_lanes, A_eq) if v != 0]
                b_nz = [f"{n}={hex16(v)}" for n,v in zip(a_lanes, B_eq) if v != 0]
                f_idx_e.write(f"{even_line}: op={opcode} A={A_name} B={B_name} | A_nz: {' '.join(a_nz)} | B_nz: {' '.join(b_nz)}\n")
                even_line += 1

    f_in.close(); f_out.close(); f_ctl.close()
    if args.even:
        f_in_e.close(); f_out_e.close(); f_ctl_e.close(); f_idx_e.close()

if __name__ == '__main__':
    main()
