import argparse, random, sys, pathlib
from typing import List

try:

    from clifford.g3c import layout, blades

except ImportError:
    print("clifford not installed; pip install 'clifford[extras]'", file=sys.stderr)
    sys.exit(1)

OPCODES = {'add':0,'sub':1,'mul':2,'wedge':3,'dot':4,'dual':5,'rev':6,'norm':7}

blade_names = [
    'scalar',
    'e1','e2','e12','e3','e13','e23','e123',
    'e4','e14','e24','e124','e34','e134','e234','e1234',
    'e5','e15','e25','e125','e35','e135','e235','e1235',
    'e45','e145','e245','e1245','e345','e1345','e2345','e12345'
]

e1 = blades['e1']
e2 = blades['e2']
e3 = blades['e3']
eo = blades['e4']
ei = blades['e5']
vec_map = {'1':e1,'2':e2,'3':e3,'4':eo,'5':ei}

def blade_mv(name):

    if name == 'scalar':
        return layout.scalar
    
    mv = layout.scalar

    for ch in name[1:]:
        mv = mv * vec_map[ch]

    return mv

basis_mvs = [blade_mv(n) for n in blade_names]

def dual(mv):
    return mv.dual()

def reverse(mv):
    return ~mv

def even_part(mv):
    return mv(0) + mv(2) + mv(4)

name_to_index = {}

for n,mv in zip(blade_names, basis_mvs):

    arr = mv.value
    nz = [i for i,v in enumerate(arr) if abs(v)>1e-12]
    name_to_index[n] = nz[0] if nz else 0

def coeff_array(mv) -> List[float]:

    arr = mv.value
    return [float(arr[name_to_index[n]]) for n in blade_names]

FRAC = 11
MIN_I = - (1 << 15)
MAX_I =   (1 << 15) - 1

def float_to_q511(x: float) -> int:
    
    s = int(round(x * (1<<FRAC)))
    if s > MAX_I: s = MAX_I
    if s < MIN_I: s = MIN_I
    return s & 0xFFFF

def q511_array(vals: List[float]) -> List[int]:
    return [float_to_q511(v) for v in vals]

def hex16(i): return f"{i & 0xFFFF:04x}"

def corner_multivectors():
    
    mvs = []
    zero = layout.scalar * 0
    mvs.append(zero)
    one = layout.scalar * 1.0
    mvs.append(one)
    for mv in basis_mvs[1:]:
        mvs.append(mv)
        mvs.append(-mv)
    big = 15.5
    for mv in basis_mvs[1:6]:
        mvs.append(big*mv)
        mvs.append(-big*mv)
    return mvs

def random_mv():
    
    coeffs = []
    for _ in blade_names:
        if random.random() < 0.30:
            coeffs.append(random.uniform(-4.0,4.0))
        else:
            coeffs.append(0.0)
    mv = layout.scalar * 0
    for c, base in zip(coeffs, basis_mvs):
        if c != 0:
            mv += c * base
    return mv

def apply_op(opcode, A, B):
    
    if opcode == OPCODES['add']:
        return A + B
    if opcode == OPCODES['sub']:
        return A - B
    if opcode == OPCODES['mul']:
        return A * B
    if opcode == OPCODES['wedge']:
        return A ^ B
    if opcode == OPCODES['dot']:
        return A | B
    if opcode == OPCODES['dual']:
        return dual(A)
    if opcode == OPCODES['rev']:
        return reverse(A)
    if opcode == OPCODES['norm']:
        s = float((A * reverse(A))[()])
        return s + layout.scalar*0
    
    raise ValueError

def mask_even_mv(mv):
    return even_part(mv)

def main():
    
    ap = argparse.ArgumentParser()
    ap.add_argument("-n","--num-random", type=int, default=1000)
    ap.add_argument("-o","--out-dir", default=".")
    ap.add_argument("-even", action="store_true")
    ap.add_argument("--seed", type=int, default=1)
    args = ap.parse_args()
    random.seed(args.seed)
    outdir = pathlib.Path(args.out_dir)
    outdir.mkdir(parents=True, exist_ok=True)
    f_in   = open(outdir/"cga_test_inputs.mem","w")
    f_out  = open(outdir/"cga_test_outputs.mem","w")
    f_ctl  = open(outdir/"cga_test_control.mem","w")
    
    if args.even:
        f_in_e  = open(outdir/"cga_test_inputs_even.mem","w")
        f_out_e = open(outdir/"cga_test_outputs_even.mem","w")
        f_ctl_e = open(outdir/"cga_test_control_even.mem","w")
    
    else:
        f_in_e=f_out_e=f_ctl_e=None
    
    corners = corner_multivectors()
    tests = []
    one = layout.scalar * 1
    
    for mv in corners:
        
        tests.append((mv, one))
        tests.append((mv, mv))
    
    for _ in range(args.num_random):
        tests.append((random_mv(), random_mv()))
    
    total = 0
    ops = list(OPCODES.values())
    
    for A,B in tests:
        for opcode in ops:
            
            Bu = B if opcode in (OPCODES['add'],OPCODES['sub'],OPCODES['mul'],OPCODES['wedge'],OPCODES['dot']) else layout.scalar*0
            R  = apply_op(opcode, A, Bu)
            A_q = q511_array(coeff_array(A))
            B_q = q511_array(coeff_array(Bu))
            R_q = q511_array(coeff_array(R))
            for x in A_q: f_in.write(hex16(x))
            for x in B_q: f_in.write(hex16(x))
            f_in.write("\n")
            for x in R_q: f_out.write(hex16(x))
            f_out.write("\n")
            f_ctl.write(f"{opcode}\n")
            
            if args.even:
                A_e = mask_even_mv(A)
                B_e = mask_even_mv(Bu)
                R_e = apply_op(opcode, A_e, B_e if opcode in (OPCODES['add'],OPCODES['sub'],OPCODES['mul'],OPCODES['wedge'],OPCODES['dot']) else layout.scalar*0)
                R_e = mask_even_mv(R_e)
                A_eq = q511_array(coeff_array(A_e))
                B_eq = q511_array(coeff_array(B_e))
                R_eq = q511_array(coeff_array(R_e))
                for x in A_eq: f_in_e.write(hex16(x))
                for x in B_eq: f_in_e.write(hex16(x))
                f_in_e.write("\n")
                for x in R_eq: f_out_e.write(hex16(x))
                f_out_e.write("\n")
                f_ctl_e.write(f"{opcode}\n")
            total += 1
    
    f_in.close(); f_out.close(); f_ctl.close()
    
    if args.even:
        f_in_e.close(); f_out_e.close(); f_ctl_e.close()
    
    print(f"Generated {total} test instances ({len(tests)} operand pairs × {len(ops)} ops).")



if __name__ == "__main__":
    main()