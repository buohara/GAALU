#!/bin/bash
# filepath: /home/ben/GAALU/scripts/build_and_program.sh

set -e

export OMP_NUM_THREADS=2
export VIVADO_JOBS=2

echo "Building FPGA bitstream..."
cd scripts
vivado -mode batch -source fpga/build_fpga.tcl

echo "Programming FPGA..."
BITFILE="gaalu_proj/gaalu_proj.runs/impl_1/fpga_top.bit"

if [ ! -f "$BITFILE" ]; then
    echo "Error: Bitstream not found at $BITFILE"
    exit 1
fi

#vivado -mode batch -source program_fpga.tcl

echo "FPGA programmed successfully!"