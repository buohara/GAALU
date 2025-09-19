#!/usr/bin/env python3
"""
Generate multiplication tables for even-grade CGA basis blades
and produce SystemVerilog ACCP/ACCN expressions for ga_alu_even.sv
"""

import argparse
import sys
sys.path.append('/home/ben/GAALU/scripts/pygae')
from gen_test_vecs import layout, blades, mv_from_name_canon, coeffs_canon

EVEN_LANES = [
    "scalar",  
    "e12",     
    "e13",     
    "e23",     
    "e14",     
    "e24",     
    "e34",     
    "e15",     
    "e25",     
    "e35",     
    "e45",     
    "e1234",   
    "e1235",   
    "e1245",   
    "e1345",   
    "e2345"    
]

LANE_INDEX = {blade: i for i, blade in enumerate(EVEN_LANES)}

def parse_blade(blade_str):

    if blade_str == "scalar":
        return frozenset()
    return frozenset(int(c) for c in blade_str[1:])

def blade_to_string(indices):

    if not indices:
        return "scalar"
    return "e" + "".join(str(i) for i in sorted(indices))

def clifford_operation(blade1, blade2, operation):

    if blade1 == "scalar":
        mv1 = layout.scalar
    else:
        mv1 = mv_from_name_canon(blade1)
    
    if blade2 == "scalar":
        mv2 = layout.scalar  
    else:
        mv2 = mv_from_name_canon(blade2)
    
    if operation == 'gp':
        result_mv = mv1 * mv2
    elif operation == 'wedge':
        result_mv = mv1 ^ mv2
    elif operation == 'lcont':
        result_mv = mv1 << mv2
    else:
        raise ValueError(f"Unknown operation: {operation}")
    
    coeffs = coeffs_canon(result_mv)
    
    for blade_name, coeff in coeffs.items():
        if abs(coeff) > 1e-10 and blade_name in LANE_INDEX:
            sign = 1 if coeff > 0 else -1
            return blade_name, sign
    
    return None

def generate_multiplication_table(operation):

    table = {}
    
    op_func = {
        'gp': lambda b1, b2: clifford_operation(b1, b2, 'gp'),
        'wedge': lambda b1, b2: clifford_operation(b1, b2, 'wedge'), 
        'lcont': lambda b1, b2: clifford_operation(b1, b2, 'lcont')
    }[operation]
    
    op_name = {
        'gp': 'Geometric Product',
        'wedge': 'Wedge Product', 
        'lcont': 'Left Contraction'
    }[operation]
    
    print(f"=== 16x16 {op_name} Table (4,1) Signature ===")
    print("Rows × Columns → Result")
    print()
    
    print(f"{'':12}", end="")
    for col_blade in EVEN_LANES:
        print(f"{col_blade:>12}", end="")
    print()
    print("-" * (12 + 12 * len(EVEN_LANES)))
    
    for i, row_blade in enumerate(EVEN_LANES):
        print(f"{row_blade:12}", end="")
        table[i] = {}
        
        for j, col_blade in enumerate(EVEN_LANES):
            result = op_func(row_blade, col_blade)
            
            if result is None:
                entry = "0"
                table[i][j] = None
            else:
                result_blade, sign = result
                if result_blade in LANE_INDEX:
                    result_idx = LANE_INDEX[result_blade]
                    sign_str = "+" if sign > 0 else "-"
                    entry = f"{sign_str}{result_idx}"
                    table[i][j] = (result_idx, sign)
                else:
                    entry = "0"
                    table[i][j] = None
                
            print(f"{entry:>12}", end="")
        print()
    
    return table

def generate_systemverilog_code(table, operation):

    op_name = {
        'gp': 'geometricProduct_even',
        'wedge': 'wedgeProduct_even',
        'lcont': 'dotProduct_even'
    }[operation]
    
    print("\n" + "="*80)
    print(f"SystemVerilog Code for {op_name}:")
    print("="*80)
    
    for output_idx, output_blade in enumerate(EVEN_LANES):
        contributions = []
        
        for row_idx in range(len(EVEN_LANES)):
            for col_idx in range(len(EVEN_LANES)):
                if table[row_idx][col_idx] is not None:
                    result_idx, sign = table[row_idx][col_idx]
                    if result_idx == output_idx:
                        contributions.append((row_idx, col_idx, sign))
        
        if contributions:
            print(f"\n        // {output_blade} contributions")
            for row_idx, col_idx, sign in contributions:
                row_blade = EVEN_LANES[row_idx]
                col_blade = EVEN_LANES[col_idx]
                
                macro = "ACCP" if sign > 0 else "ACCN"
                lane_name = f"L_{output_blade.upper()}"
                
                print(f"        `{macro}({lane_name}, al[L_{row_blade.upper()}], bl[L_{col_blade.upper()}]);")

def main():

    parser = argparse.ArgumentParser(description='Generate GA multiplication tables for even-grade CGA')
    parser.add_argument('-gp', '--geometric', action='store_true', help='Generate geometric product table')
    parser.add_argument('-wedge', '--wedge', action='store_true', help='Generate wedge product table')  
    parser.add_argument('-lcont', '--left-contraction', action='store_true', help='Generate left contraction table')
    parser.add_argument('--all', action='store_true', help='Generate all tables')
    
    args = parser.parse_args()
    
    if not any([args.geometric, args.wedge, args.left_contraction, args.all]):
        args.geometric = True
    
    operations = []
    if args.all:
        operations = ['gp', 'wedge', 'lcont']
    else:
        if args.geometric:
            operations.append('gp')
        if args.wedge:
            operations.append('wedge')
        if args.left_contraction:
            operations.append('lcont')
    
    print("Generating multiplication tables for even-grade CGA...")
    print(f"Signature: (4,1) - e1²=e2²=e3²=e4²=+1, e5²=-1")
    print(f"Even lanes: {len(EVEN_LANES)}")
    print()
    
    for operation in operations:

        table = generate_multiplication_table(operation)
        
        generate_systemverilog_code(table, operation)
        
        if operation != operations[-1]:
            print("\n" + "="*80)
            print()
    
    print(f"\n" + "="*80)
    print("Usage: Copy the generated ACCP/ACCN expressions into your")
    print("respective functions in ga_alu_even.sv")
    print("="*80)

if __name__ == "__main__":
    main() 