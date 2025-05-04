TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/../src/*.sv
VERILOG_SOURCES += $(shell pwd)/../src/*.svh
VERILOG_SOURCES += $(shell pwd)/../src/SIE/downstream/*.sv
TOPLEVEL = SIE_down
MODULE = SIE_down_test
SIM = verilator
EXTRA_ARGS += --trace --trace-fst --trace-structs -Wno-fatal
include $(shell cocotb-config --makefiles)/Makefile.sim
