# GAALU: Conformal Geometric Algebra Arithmetic Unit

GAALU is a hardware arithmetic unit for Conformal Geometric Algebra (CGA), implemented in SystemVerilog. It supports the following opcodes:

- ADD: Addition
- SUB: Subtraction
- MUL: Geometric Product
- WEDGE: Outer Product
- DOT: Inner Product
- DUAL: Dual
- REV: Reverse
- NORM: Norm

## Build and Run

1. **Build the Docker image:**
	```bash
	docker build -t gaalu .
	```

2. **Run the Docker container (with your project mounted):**
	```bash
	docker run --rm -it -v $(pwd):/workspace gaalu
	```

3. **Inside the container, run the simulation:**
	```bash
	make simulate
	```

This will generate test vectors, build the SystemVerilog design with Verilator, and run the testbench.

