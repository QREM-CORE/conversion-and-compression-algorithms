# Makefile for ModelSim/Questa: compile and run all SystemVerilog testbenches.
# Override variables on the command line if your tool names differ.

VLOG      ?= vlog
VSIM      ?= vsim
VLIB      ?= vlib
VMAP      ?= vmap
WORK      ?= work
VLOGFLAGS ?= -sv -work $(WORK)
VSIMFLAGS ?= -c -voptargs=+acc

RTL_SRCS := \
	rtl/bits2bytes.sv \
	rtl/bytes2bits.sv \
	rtl/byte_encode.sv \
	rtl/byte_decode.sv

TB_SRCS := \
	tb/tb_bits2bytes.sv \
	tb/tb_bytes2bits.sv \
	tb/tb_byte_encode.sv \
	tb/tb_byte_decode.sv

TB_TOPS := \
	tb_bits2bytes \
	tb_bytes2bits \
	tb_byte_encode \
	tb_byte_decode

.PHONY: all clean compile run $(TB_TOPS) $(addprefix run_,$(TB_TOPS))

all: run

run: $(addprefix run_,$(TB_TOPS))

# Create and map the work library if it does not exist.
$(WORK):
	@$(VLIB) $(WORK)
	@$(VMAP) $(WORK) $(WORK)

# Compile all RTL and TB sources into the work library.
compile: $(WORK)
	$(VLOG) $(VLOGFLAGS) $(RTL_SRCS) $(TB_SRCS)

# Individual run targets invoke vsim in command-line mode.
run_tb_bits2bytes: compile
	$(VSIM) $(VSIMFLAGS) tb_bits2bytes -do "run -all; quit -f"

run_tb_bytes2bits: compile
	$(VSIM) $(VSIMFLAGS) tb_bytes2bits -do "run -all; quit -f"

run_tb_byte_encode: compile
	$(VSIM) $(VSIMFLAGS) tb_byte_encode -do "run -all; quit -f"

run_tb_byte_decode: compile
	$(VSIM) $(VSIMFLAGS) tb_byte_decode -do "run -all; quit -f"

clean:
	rm -rf $(WORK) transcript vsim.wlf modelsim.ini
