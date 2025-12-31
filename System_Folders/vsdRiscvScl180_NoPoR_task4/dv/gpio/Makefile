# SPDX-License-Identifier: Apache-2.0

# ------------------ PDK / IO ------------------
scl_io_PATH = "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/verilog/tsl18cio250/zero"

VERILOG_PATH = ../../
RTL_PATH = $(VERILOG_PATH)/rtl
BEHAVIOURAL_MODELS = ../

# ------------------ Management SoC ------------------
#MGMT_CORE_PATH ?= ~/gits/caravel_pico                  # <<< ADD
#CARAVEL_RTL = /home/cdmanasa/vsdRiscvScl180_NoPoR           # <<< ADD

MGMT_CORE_PATH ?= ~/gits/caravel_pico
CARAVEL_RTL    = /home/cdmanasa/vsdRiscvScl180_NoPoR/rtl
CARAVEL_DEFS   = $(CARAVEL_RTL)/defines.v

scl_io_wrapper_PATH ?= $(RTL_PATH)/scl180_wrapper   # <<< FIX PATH

# ------------------ Firmware ------------------
RISCV_TYPE ?= rv32imc
FIRMWARE_PATH = ../
GCC_PATH ?= /usr/bin/gcc
GCC_PREFIX ?= riscv32-unknown-elf

# ------------------ Simulation ------------------
SIM_DEFINES = +define+FUNCTIONAL +define+SIM
SIM ?= RTL

PATTERN = gpio

# ------------------ VCS ------------------
VCS_FLAGS = -sverilog +v2k -full64 -debug_all -lca -timescale=1ns/1ps
VCS_INCDIR = \
	+incdir+$(BEHAVIOURAL_MODELS) \
	+incdir+$(RTL_PATH) \
	+incdir+$(MGMT_CORE_PATH)\
	+incdir+$(scl_io_wrapper_PATH) \
	+incdir+$(scl_io_PATH)

SIMV = simv
COMPILE_LOG = compile.log
SIM_LOG = simulation.log

# ------------------ Targets ------------------
all: compile

hex: $(PATTERN).hex

# ---------- Compile ----------

compile: $(PATTERN)_tb.v $(PATTERN).hex
	vcs $(VCS_FLAGS) $(SIM_DEFINES) $(VCS_INCDIR) \
	    $(CARAVEL_DEFS) \
	    $(CARAVEL_RTL)/user_defines.v \
	    $(CARAVEL_RTL)/caravel_clocking.v \
	    $(CARAVEL_RTL)/caravel_core.v \
	    $(CARAVEL_RTL)/mprj_io_buffer.v \
	    $(PATTERN)_tb.v \
	    -l $(COMPILE_LOG) \
	    -o $(SIMV)

# ---------- Run ----------
sim: compile
	./$(SIMV) -l $(SIM_LOG)

gui: compile
	./$(SIMV) -gui -l $(SIM_LOG) &

vpd: compile
	./$(SIMV) -l $(SIM_LOG)
	@echo "View waveform: dve -vpd vcdplus.vpd &"

# ---------- Clean ----------
clean:
	rm -f $(SIMV) *.log *.vpd *.fsdb *.key
	rm -rf simv.daidir csrc DVEfiles verdiLog novas.* *.fsdb+ AN.DB

.PHONY: clean compile sim gui vpd all

