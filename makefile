CXX 		= g++
VECTORS_DIR = tests/vectors
CXXFLAGS 	= -std=c++17 -O0 -g3 -Wall -Wextra -DDEBUG

GA_EVEN 	?= 1
NUM_TESTS 	?= 1000

ifeq ($(GA_EVEN),1)
VERILATOR_FLAGS += -DGA_EVEN
GEN_EVEN_FLAG   = -even
SIM_ARGS        = +GA_EVEN
else
GEN_EVEN_FLAG   =
SIM_ARGS        =
endif

RTL_DIR = rtl
TB_DIR = tests/rtl
WAVES ?= 0

VERILATOR_FLAGS += --cc --binary --build -Wall --top-module tb_ga_coprocessor
VERILATOR_FLAGS += +incdir+$(RTL_DIR) +incdir+$(TB_DIR)
VERILATOR_FLAGS += -CFLAGS "-std=c++14" -Wno-UNUSED -Wno-UNDRIVEN
VERILATOR_FLAGS += --timing
VERILATOR_FLAGS += -Wno-DECLFILENAME -Wno-TIMESCALEMOD

ifeq ($(WAVES),1)
    VERILATOR_FLAGS += --trace
endif

simulate: $(RTL_DIR)/*.sv $(TB_DIR)/tb_ga_coprocessor.sv
	bash scripts/pygae/gentestvecs.sh -n $(NUM_TESTS) $(GEN_EVEN_FLAG)
	verilator $(VERILATOR_FLAGS) \
		$(RTL_DIR)/ga_pkg.sv \
		$(RTL_DIR)/ga_alu_even.sv \
		$(RTL_DIR)/ga_alu.sv \
		$(RTL_DIR)/ga_coprocessor.sv \
		$(RTL_DIR)/ga_register_file.sv \
		$(TB_DIR)/tb_ga_coprocessor.sv
#	./obj_dir/Vtb_ga_coprocessor $(SIM_ARGS) $(if $(filter 1,$(WAVES)),+WAVES)

clean:
	rm -rf tests/obj_dir/
	rm -f tests/*.log tests/*.vcd
	rm -f scripts/vivado*
	rm -rf scripts/gaalu_proj/
	rm -rf $(VECTORS_DIR)
	rm -f scripts/*.dcp scripts/*.bit scripts/*.txt

help:
	@echo "Verilator Simulation:"
	@echo "  make simulate          - Run simulation"
	@echo "  make simulate WAVES=1  - Run with waveforms"
	@echo "  make clean             - Clean artifacts"
	@echo ""
	@echo "View waveforms: gtkwave ga_coprocessor_test.vcd"

.PHONY: all clean clean_vectors clean_all help simulate
