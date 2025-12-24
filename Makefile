# ModelSim/Questa multi-testbench Makefile

VLOG ?= vlog
VSIM ?= vsim
VLIB ?= vlib
WORK ?= work

# List of testbenches to run
TESTBENCHES = \
	tb_bits2bytes \
	tb_bytes2bits \
	tb_byte_encode \
	tb_byte_decode

# RTL sources
RTL_SRCS = \
	rtl/bits2bytes.sv \
	rtl/bytes2bits.sv \
	rtl/byte_encode.sv \
	rtl/byte_decode.sv

.PHONY: all clean run_all run_%

all: $(WORK) run_all

# Create work library
$(WORK):
	$(VLIB) $(WORK)

# Run all testbenches
run_all:
	@for tb in $(TESTBENCHES); do \
		$(MAKE) run_$$tb; \
	done

# Rule for each testbench
run_%: $(WORK)
	@echo "=== Running $* ==="
	$(VLOG) -sv -work $(WORK) $(RTL_SRCS) tb/$*.sv
	@echo 'run -all' > run_$*.do
	@echo 'quit -f' >> run_$*.do
	$(VSIM) -c -voptargs=+acc -do run_$*.do $(WORK).$*
	rm -f run_$*.do

clean:
	rm -rf $(WORK) transcript vsim.wlf modelsim.ini run_*.do
