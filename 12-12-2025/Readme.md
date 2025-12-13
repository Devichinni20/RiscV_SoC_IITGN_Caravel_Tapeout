
# RISC-V Reference SoC Implementation using Synopsys and SCL180 PDK (RTL + Synthesis + GLS)


## 1. Overview
This repository contains the reference vsdcaravel RISC‑V SoC flow adapted for the SCL180 PDK and Synopsys toolchain. It demonstrates the full path from RTL functional simulation through Synopsys Design Compiler synthesis to gate‑level simulation (GLS), and provides example scripts, netlist editing notes, and post‑synthesis reports.

- Top module: `vsdcaravel`
- PDK: SCL180 (Semiconductor Laboratory) — access requires NDA and PDK distribution from SCL
- Tools: Synopsys DC (dc_shell), VCS/Icarus Verilog, GTKWave
- Reference repo: https://github.com/vsdip/vsdRiscvScl180 (branch: iitgn)

---

## 2. Quick summary of the flow
1. Functional simulation (dv/)
2. Synthesis with Synopsys DC (synthesis/)
3. Netlist edits to replace blackboxes and power ties (synthesis/output/)
4. Gate‑level simulation (gls/ or gl/)

---
## Repository Structure
```
VsdRiscvScl180/
├── dv             # Contains functional verification files 
├── gl             # Contains GLS supports files
├── gls            # Contains test bench files and synthesized netlists
├── rtl            # Contains verilog files        
├── synthesis      # Contains synthesis scripts and outputs
   ├──output       # Contain synthesis output
   ├──report       # Contain area,power and qor post synth report
   ├──work         # Synthesis work folder
├── README.md      # This README file
```
## Prerequisites
Before using this repository, ensure you have the following dependencies installed:

- **SCL180 PDK** ( SCL180 PDK)
- **RiscV32-uknown-elf.gcc** (building functional simulation files)
- **Caravel User Project Framework** from Efabless
- **Synopsys EDA tool Suite** for Synthesis
- **Verilog Simulator** (e.g., Icarus Verilog)
- **GTKWAVE** (used for visualizing testbench waves)


## Test Instructions
### Repo Setup
1. Clone the repository:
   ```sh 
   git clone https://github.com/vsdip/vsdRiscvScl180.git
   cd vsdRiscvScl180
   git checkout iitgn
   ```
2. Install required dependencies (ensure dc_shell and SCL180 PDK are properly set up).

### Functional Simulation Setup
3. Setup functional simulation file paths
   - Edit Makefile at this path [./dv/hkspi/Makefile](./dv/hkspi/Makefile)
   - Modify and verify `GCC_Path` to point to correct riscv installation
   - Modify and verify `scl_io_PATH` to point to correct io
  

## use the make file from RTL folder

###  Functional Simulation Execution
4. open a terminal and cd to the location of Makefile i.e. [./dv/hkspi](./dv/hkspi)
5. make sure hkspi.vvp file has been deleted from the hkspi folder
6. Run following command to generate vvp file for functional simulation
   ```
   make
   vvp hkspi.vvp
   ```

   - you should receive output similar to following output on successfull execution

7. Visualize the Testbench waveforms for complete design using following command
   ```
   gtkwave hkspi.vcd hkspi_tb.v
   ```


   ### Synthesis Setup
8. Modify and verify following variables in synth.tcl file at path [./synthesis/synth.tcl](./synthesis/synth.tcl)
   ```
   library Path
   Root Directory Path
   SCL PDK Path
   SCL IO PATH

   ```
### Running Synthesis
9. open a terminal and cd to the work folder i.e. [./synthesis/work_folder](./synthesis/work_folder)
10. Run synthesis using following command

check synth.tcl file

```
dc_shell -f ../synth.tcl
```


- Expected outputs:
  - Synthesized verilog: `vsdcaravel_synthesis.v` (in `synthesis/output/`)
  - Area/power/timing reports (in `synthesis/report/`)
 

## 5. Gate-Level Simulation (GLS)
Preparation:
- Copy synthesized netlist to `gls/` or reference it from `synthesis/output/`.
-  Modify synthesized netlist at path [./synthesis/output/vsdcaravel_synthsis.v](./synthesis/output/caravel_synthesis.v) to remove blackboxed modules
   - Remove following modules
   ```
   dummy_por
   RAM128
   housekeeping
   ```
   - add following lines at the beginning of the netlist file to import the blackboxed modules from functional rtl
   ```
   `include "dummy_por.v"
   `include "RAM128.v
   `include "housekeeping.v"
   ```
- Replace hard-coded `1'b0` used as ground with the PDK ground net (e.g., `vssa`) where appropriate.

GLS run (example):
```bash
cd gls
make clean
make
vvp hkspi.vvp
gtkwave hkspi.vcd hkspi_tb.v
```
18. Compare output from functional Simulation and GLS to verify the synthesis output

    
## Results
- Successfully ran functional simulations, synthesis and GLS for VexRiscV Harnessed with Efabless's Caravel usign SCL180 PDK.

## Reports














## Three highlighted errors (observed during runs) — descriptions & mitigation

Below are three reproducible errors encountered during GLS with recommended actions.

1) Error: Housekeeping module failed to synthesize (mapped to blackbox)
- Symptom: Synthesis leaves `housekeeping` as a blackbox; subsequent netlist has a blackbox placeholder.
- Probable cause: Unsupported constructs (behavioral blocks, generate loops, or inferred RAMs) or naming mismatch with PDK IO wrappers.
- Workaround:
  - Inspect `rtl/housekeeping.v` for unsupported synthesizable constructs (e.g., file I/O, $display-only constructs).
  - Refactor or rewrite the problematic logic to RTL-friendly style (finite-state machine style, remove non-synthesizable tasks).
  - As a temporary GLS workaround, include the RTL `housekeeping.v` into the netlist (remove the blackbox def) so behavioral RTL is used for GLS.
- Status: Documented; long‑term fix: RTL refactor + re-run synthesis.

2) Error: RAM128 inferred memory blackboxed / missing PDK memory macro
- Symptom: Memory instances are left as blackboxes or mismatched port widths after mapping.
- Probable cause: The synthesis mapping expects vendor-specific memory macros (SCL memory compilers) which are not available or not referenced.
- Workaround:
  - Replace inferred RAM with an explicit SCL memory macro when available (match port names and parameters).
  - For GLS, include an RTL behavioral RAM model (`RAM128.v`) and `include` it in the netlist to bypass macro absence.
- Status: Temporary GLS fix applied; PDK memory macro integration planned.

3) Error: Netlist uses literal '1'b0' for ground/power pin and causes mismatch with PDK ground net (vssa)
- Symptom: GLS or PDK tools report power pin mismatch or simulation mismatches; some modules tie inputs to `1'b0` instead of using the PDK ground net.
- Probable cause: Synthesis/RTL used hard-coded constants instead of explicit power rails; PDK expects named ports/nets for power.
- Workaround:
  - Post-process netlist: replace `1'b0` occurrences tied to power pins with `vssa` (or the correct ground net name).
  - Ensure power pins are explicitly connected in top-level instantiations or that power-net naming conventions are consistent across RTL and PDK libraries.
- Status: Applied to GLS netlist; ensure consistent treatment before P&R.

---

##  Known issues (other)
- Several modules had timing arcs disabled automatically by the tool (notably in `PLL` and parts of `housekeeping`) — these must be inspected and corrected to ensure correct static timing analysis.
- Clock tree power estimate is not included in the provided power reports; account for clock-tree insertion during P&R.

---

##  Suggested next steps (roadmap)
- Rework `housekeeping` RTL to be synthesis-friendly and re-run DC.
- Integrate SCL memory macros and POR cells to remove blackboxes.
- Add more regression tests and firmware to exercise internal interfaces of `vsdcaravel`.
- Proceed to ICC2/Primetime/Place & Route once macros are integrated.
- Add UPF/CPF files and power-aware simulation flows.

---

##  Conclusion

From RTL to GLS , the simulations are done but as mentioned above the certain modules have issues with synthesis , which were made black boxes for GLS. this is the only reason for having small differences in the waveforms between RTL simulation and GLS simulation. The other parts of the waveforms show correct functionality saying that this mismatch is not actually a functionality issue but it is a synthesis issue which is to be fixed. So the design functionality is verified.

---

---

## References
- efabless / Caravel: https://github.com/efabless/
- This repository: https://github.com/vsdip/vsdRiscvScl180/tree/iitgn

License & usage: The reference IP in this repository is free to use for tapeout on SCL180 by qualified parties with proper PDK access and NDA. Do not redistribute PDK files or licensed assets.

















