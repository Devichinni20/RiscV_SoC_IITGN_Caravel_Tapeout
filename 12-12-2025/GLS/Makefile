# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

scl_io_PATH = "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/verilog/tsl18cio250/zero"
scl_io_wrapper_PATH = ../rtl/scl180_wrapper
VERILOG_PATH = ../
RTL_PATH = $(VERILOG_PATH)/rtl
GL_PATH = $(VERILOG_PATH)/gl
BEHAVIOURAL_MODELS = ../gls
RISCV_TYPE ?= rv32imc
PDK_PATH = /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/verilog/vcs_sim_model 
FIRMWARE_PATH = ../gls
GCC_PATH?=/usr/bin/gcc
GCC_PREFIX?=riscv32-unknown-elf

SIM_DEFINES = -DFUNCTIONAL -DSIM
SIM?=gl

.SUFFIXES:

PATTERN = hkspi

vvp:  ${PATTERN:=.vvp}
hex:  ${PATTERN:=.hex}
vcd:  ${PATTERN:=.vcd}

%.vvp: %_tb.v %.hex
	iverilog -Ttyp $(SIM_DEFINES) -DGL \
	-I $(VERILOG_PATH) \
	-I $(VERILOG_PATH)/synthesis/output \
	-I $(BEHAVIOURAL_MODELS) \
	-I $(RTL_PATH) \
	-I $(GL_PATH) \
	-I $(scl_io_wrapper_PATH) \
	-I $(scl_io_PATH) \
	-I $(PDK_PATH) \
	-y $(scl_io_wrapper_PATH) \
	-y $(RTL_PATH) \
	-y $(GL_PATH) \
	-y $(scl_io_PATH) \
	-y $(PDK_PATH) \
	$(GL_PATH)/defines.v $< -o $@

%.vcd: %.vvp
	vvp $<

%.elf: %.c $(FIRMWARE_PATH)/sections.lds $(FIRMWARE_PATH)/start.s
	${GCC_PATH}/${GCC_PREFIX}-gcc -march=$(RISCV_TYPE) -mabi=ilp32 -Wl,-Bstatic,-T,$(FIRMWARE_PATH)/sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $(FIRMWARE_PATH)/start.s $<

%.hex: %.elf
	${GCC_PATH}/${GCC_PREFIX}-objcopy -O verilog $< $@ 
	# to fix flash base address
	sed -i 's/@10000000/@00000000/g' $@

%.bin: %.elf
	${GCC_PATH}/${GCC_PREFIX}-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@

check-env:
ifeq (,$(wildcard $(GCC_PATH)/$(GCC_PREFIX)-gcc ))
	$(error $(GCC_PATH)/$(GCC_PREFIX)-gcc is not found, please export GCC_PATH and GCC_PREFIX before running make)
endif

clean:
	rm -f *.elf *.hex *.bin *.vcd *.vvp *.log

.PHONY: clean hex vvp vcd
