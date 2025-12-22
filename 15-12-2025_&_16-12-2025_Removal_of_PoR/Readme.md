###  Removal of On-Chip POR and Final GLS Validation (SCL-180)

## Overview

This task focuses on the **formal removal of the on-chip Power-On Reset (POR)**
from a VSD Caravel-based RISC-V SoC and the validation of an
**external reset-only architecture** when targeting the **SCL-180 PDK**.

The work is intentionally research-driven and documentation-heavy, mirroring
real industry tape-out decision processes rather than simple RTL modification.

---

## Task Details


**Tools Used:**
- Synopsys DC_TOPO (Synthesis)
- Synopsys VCS (Simulation & GLS)
- SCL-180 PDK  



---

## Objective

The objective of this task is to **formally remove the on-chip Power-On Reset (POR)** from the VSD Caravel SoC and prove—using design reasoning, pad analysis,
synthesis, and gate-level simulation—that relying on a **single external reset pin**
is **safe, correct, and architecturally sound** for SCL-180.

By the end of this task, the following are demonstrated:

1. A **POR-free SoC RTL** relying only on an external reset pin  
2. A **clear technical justification** for POR removal based on pad behavior and power assumptions  
3. A **clean DC_TOPO synthesis** without behavioral artifacts  
4. A **final VCS-based GLS** using SCL-180 standard cells  
5. **Industry-quality documentation** explaining *why* POR was removed—not just *how*

---

## Context: Why This Task Exists

In earlier Caravel-based flows, a module named `dummy_por` was used to model
power-on reset behavior.

However, deeper analysis reveals:

- Behavioral PORs are **not synthesizable**
- True PORs are **analog macros**, not digital RTL
- Simulation-only constructs (e.g., time delays) do **not map to silicon**
- In modern pad libraries such as **SCL-180**, input pads and reset pins are
  **usable immediately after power-up**

As a result, the behavioral POR created a mismatch between **simulation behavior**
and **real silicon behavior**.

This task rigorously validates the decision to remove POR and align RTL with
physical reality.

---

## Key Technical Clarifications

### Behavioral vs Synthesizable RTL

Not all behavioral RTL is non-synthesizable.

- **Synthesizable behavioral RTL**:
  - Clocked `always @(posedge clk)` logic
  - Combinational `always @(*)` logic
- **Non-synthesizable RTL**:
  - Time delays (`#`)
  - Power-up assumptions
  - Behavioral POR models

The issue with `dummy_por` is not that it is behavioral, but that it
describes **time-based behavior without real hardware**.

---

### Why Behavioral POR Is Unsafe

Simulation can model delays such as:
```verilog
#100 porb_h = 1;
```
## Key Technical Reasoning and Design Decisions

### Why Behavioral POR Is Unsafe in Real Silicon

Real silicon has **no concept of “waiting for time”** unless explicit hardware
(e.g., counters, analog POR macros) is physically built.

Behavioral constructs such as `#100` delays exist **only in simulation**.

During synthesis:
- The `dummy_por` module is removed or ignored
- No actual POR hardware is generated
- No power-aware reset circuitry exists on silicon

This creates a **dangerous mismatch**:
- Simulation assumes reset sequencing exists
- Silicon contains no such reset mechanism

Removing behavioral POR ensures simulation behavior matches physical reality.

---

## Understanding POR Signals in the Caravel RTL

The following POR-related signals are present in the original design:

### `porb_h`
- Active-low reset signal
- Used by the main SoC logic (CPU, peripherals, memory interfaces)
- Distributed through reset trees to flip-flop reset pins

### `porb_l`
- Intended for housekeeping logic
- Functionally derived from `porb_h`
- Does not introduce independent reset behavior
- Redundant in SCL-180 when a single external reset is used

### `por_l`
- Auxiliary reset control signal
- Used only for POR-style sequencing
- Does not directly reset digital logic

**Important Observation:**  
All POR signals ultimately **fan into reset trees** (networks distributing reset
to flip-flops).  
They do **not perform analog power detection** and therefore do not constitute
a real POR in silicon.

---

## Clean Reset Edge vs Power-Derived Reset

Digital flip-flops only require:
- Clean reset assertion
- Clean reset deassertion

They do **not** require reset to be derived from power.

As long as reset timing requirements are met:
- External reset pin
- Internal POR signal

Both are **functionally equivalent** from a digital logic perspective.

---

## Why SCL-180 Does Not Require an On-Chip POR

### Pad Behavior in SCL-180

In the SCL-180 PDK:
- Input pads are powered directly by VDD
- No internal enable signal is required
- No POR-gated input path exists
- Reset pin is available immediately after power-up
- Reset is asynchronous and clock-independent

This guarantees that reset can be asserted safely during power ramp,
making an **external reset pin sufficient**.

---

## Why SKY130 Required POR

In the SKY130 PDK:
- Pad behavior during power-up was not guaranteed
- Internal enables and pull devices could be undefined
- Reset pins were unreliable during early power ramp

On-chip POR was required to:
- Mask pad uncertainty
- Delay reset deassertion until power stabilized

---

## Technology Comparison Summary

| Feature | SKY130 | SCL-180 |
|------|--------|---------|
| Pad readiness after VDD | Delayed | Immediate |
| Reset reliability | POR-dependent | Pad-driven |
| Need for internal POR | Mandatory | Not required |

---

## Documentation Structure

The following documents provide detailed justification and analysis:

### `docs/POR_Usage_Analysis.md`
- Detailed study of where and how `dummy_por` is used in the RTL
- Identification of which blocks truly depend on POR versus generic reset

### `docs/PAD_Reset_Analysis.md`
- Analysis of SCL-180 reset pad behavior
- Explicit comparison with SKY130 and justification for POR removal

### `docs/POR_Concepts_and_Rationale.md`
- Concept-level explanations addressing:
  - Synthesizability
  - Behavioral vs real hardware
  - Reset architecture decisions

---

## Final Conclusion

Removing the on-chip POR in SCL-180 is **not an optimization** —
it is a **correctness fix**.

An external reset-only strategy:
- Matches real silicon behavior
- Eliminates simulation-only assumptions
- Simplifies reset architecture
- Aligns with industry-standard SoC design practices

This task formally proves that decision through:
- Design reasoning
- Synthesis
- Gate-level simulation



------



## Overview

This documentation describes the complete RTL-to-GLS flow for the Caravel SoC implementation using SCL-180nm technology. The primary modification involves removing the internal Power-On-Reset (POR) module and replacing it with an external reset mechanism controlled from the testbench.

## Architecture

### Original POR Signal Flow

The original design utilized a `dummy_por` module that generated three critical reset signals through the following chain:

```
Power Supply Ramp (vdd3v3)
    ↓
[dummy_por module]
    ↓ (internal, 500ns delay)
inode (reg)
    ↓
hystbuf1 → FIRST dummy__schmittbuf_1
    ↓
mid (wire)
    ↓
hystbuf2 → SECOND dummy__schmittbuf_1
    ↓
porb_h (output) → 3.3V domain reset (active-low)
    ↓
porb_l = porb_h → 1.8V domain reset (direct copy)
    ↓
por_l = ~porb_l → 1.8V domain reset (inverted)
    ↓
[Used by CPU, peripherals, user project]
```

### Signal Propagation Hierarchy

**dummy_por Module Output:**
```
vdd3v3
  ↓
dummy_por (porb_h, porb_l, por_l)
  ↓
caravel_core.v
  ↓
├── caravel (porb_l → porb)
├── caravel_clocking (porb_l → porb)
├── vsdcaravel.v → iopads → mprj_io(not used there)
├── housekeeping (porb_l → porb)
    ↓
    housekeeping_spi (porb + Internal Logic)

vsdcaravel.v
```

**External Reset Path (Testbench):**
```
Testbench (resetb)
  ↓
vsdcaravel.v (resetb)
  ↓
chip_io (resetb)
  ↓
pc3de PAD (resetb)
  ↓ (PAD delay)
chip_io (resetb_core_h)
  ↓
caravel.v (rstb_h)
  ↓
caravel_core.v (rstb_h)
  ↓
xres_buf (rstb_l)

```

## POR Removal Implementation

### Step 1: Delete dummy_por Module

The `dummy_por` module was removed from the design hierarchy. This module previously generated three reset signals: `porb_h`, `porb_l`, and `por_l`.

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/934ecc0e-65c9-4ce7-8e15-e910a16c317c" />


### Step 2: Modify caravel_core.v

After removing the `dummy_por` module, the three signals in `caravel_core.v` became undriven outputs requiring an external source. Analysis revealed that only `porb_l` propagates to downstream modules, making the other two signals redundant.

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/abeac2b5-da4a-41ec-9bcf-f6d78e5b46c4" />


<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/1413dcd8-d298-4dc4-a3fb-6bda051d01fc" />


### Step 3: Signal Consolidation

Modified `caravel_core.v` to:
- Equalised the  unused signals `porb_h` and `por_l` with ext signal `resetn`
- Reconfigure `porb_l` as an inout port
- Rename to `resetn` for clarity
  <img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/3dfa2f24-49fd-402b-9cb8-7c50612cc307" />

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/3a626df7-08ed-46c8-a507-ec2d521a5689" />

### Step 4: Update Module Instantiations

Updated all module instantiations that reference `caravel_core` to reflect the reduced signal count:



The primary modifications were required in:
- `caravel.v`
- `vsdcaravel.v`
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/f4b7f58a-8d9e-4cc5-b3ff-f38e78738a60" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/da7a6a65-81d3-4427-a329-495de04fee81" />



### Step 5: Connect External Reset

Connected the testbench `resetb` signal to `vsdcaravel.v`:



Established the connection between testbench and `caravel_core` through vsdcaravel

vsdcaravel as the three signals porh_b,por_l,porh_l which is assigned to the resetb from testbench and resetb is passes to the carave_core as resetn.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/e3610387-a3a8-47ea-b9db-2e76d79731c0" />

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/b414efd5-be4d-4203-a943-987a9625f8fb" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/4870cf14-8052-46bb-8f5b-4754fcb4c0f5" />


This creates the complete reset path from testbench to all internal modules, effectively replacing the `dummy_por` functionality.

## RTL Simulation

### Simulation Setup

```bash
csh
source tool_directory

# VCS command for RTL simulation
vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all \
+incdir+../ +incdir+../../rtl +incdir+../../rtl/scl180_wrapper \
+incdir+/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/6M1L/verilog/tsl18cio250/zero \
+define+FUNCTIONAL +define+SIM \
hkspi_tb.v -o simv

or

make compile
```

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/4c5425a7-1f5c-40a7-a312-4401230f9e02" />

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/a07d0483-7997-404a-b5c0-b91f31b4e03a" />


### Execute Simulation

```bash
./simv
```
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/4218c863-bc0c-44f3-a10d-e1238b8adbde" />

### Waveform Analysis

View the simulation waveforms using GTKWave:

```bash
gtkwave hkspi.vcd hkspi_tb.v
```

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/b271d30b-1e27-43d4-9bc1-748ad55e90dd" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/9a838e95-5c01-45b2-b1e2-78735cad4c13" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/d0cde42c-1154-4a5f-8e4d-c73326f99a37" />

## Synthesis

### Synthesis Script Execution

```bash
csh
source /home/cdmanasa/toolRC_iitgntapeout
dc_shell -f ../synth.tcl | tee synth.log
```
<img width="573" height="128" alt="image" src="https://github.com/user-attachments/assets/01701ff6-7496-415e-aca0-968084439e70" />
### ERRORS
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/4d1ab652-70b2-4c28-9cf3-2fa7e7957ebd" />

### Synthesized Netlist

The synthesized netlist(vsdcaravel_synthesis.v) confirms successful removal of the `dummy_por` module:



**Note:** The absence of `dummy_por` in the netlist validates the architectural modification.
### RPTS

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/21cc92a4-8438-468d-a220-89ce8c43abfd" />

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/db725eaa-223b-4b3a-bf90-51e4ff01c9cf" />

## Gate Level Simulation

### Preparation

For functional verification at the gate level, the blackbox modules `RAM128` and `RAM256` were replaced with their Verilog behavioral models:

### Execute GLS
Execute 
```
vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all +define+FUNCTIONAL+SIM+GL +notimingchecks hkspi_tb.v +incdir+../synthesis/output +incdir+/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/verilog/tsl18cio250/zero +incdir+/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/verilog/vcs_sim_model -o simv
```
```bash
./simv
```

### Simulation Results

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/fabcd621-4baf-40d5-843b-21c53384e94d" />

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/39d587b4-5720-4336-b2fa-52355e0d2af3" />

### Waveform Verification

The waveforms demonstrate proper reset behavior and functional correctness:

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/c9e30125-f821-4021-9271-d2ff433f7d3e" />


<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/77b007a1-7982-4211-83dd-3b5dd8cb33ff" />

The highlighted region shows the point where reset is re-triggered to verify reset functionality.

## Reset Functionality Verification

### Test Methodology

To validate the external reset mechanism, the following test sequence was implemented in the testbench:

```verilog
// Write 0x00 to registers 0x08 and 0x09 (override default values)
$display("Writing the value 0x00 to register 0x08 and 0x09");

start_csb();
write_byte(8'h80);  // Write stream command
write_byte(8'h08);  // Address (register 8 default value = 0x02)
write_byte(8'h00);  // Data = 0x00 giving external value
end_csb();

start_csb();
write_byte(8'h40);  // Read stream command
write_byte(8'h08);  
read_byte(tbdata);
end_csb();
#10;
$display("Read data = 0x%08x (should be 0x00)", tbdata);

start_csb();
write_byte(8'h80);  // Write stream command
write_byte(8'h09);  // Address (register 9 default value = 0x01)
write_byte(8'h00);  // Data = 0x00 giving external value
end_csb();

start_csb();
write_byte(8'h40);  // Read stream command
write_byte(8'h09);  
read_byte(tbdata);
end_csb();
#10;
$display("Read data = 0x%09x (should be 0x00)", tbdata);

// Apply reset
RSTB <= 1'b0;
#500;
RSTB <= 1'b1;
#500;

$display("Reset is applied now the values of 0x08 and 0x09 should return to default values");
$display("Register 8 default value = 0x02, Register 9 default value = 0x01");
```

### Test Sequence

1. Write `0x00` to registers `0x08` and `0x09` (modifying from default values `0x02` and `0x01`)
2. Read back to confirm values are `0x00`
3. Assert reset (`RSTB = 0`)
4. Deassert reset after 500ns
5. Verify registers return to default values (`0x02` and `0x01`)

### Results



The simulation output confirms successful reset operation with registers returning to their default values.

The waveforms demonstrate proper reset assertion and restoration of default register values.
### GUI

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/3bad68d4-a5bd-4ad8-b512-3ca3208c6fcf" />


<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/c994ba3d-a034-44f3-9070-237fb0e8f572" />

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/386a8a08-bc2f-473c-8295-afee2fd39ae4" />


<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/61479e1c-3317-4c7c-9186-04517e73cf16" />



<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/ba63325f-b438-485e-a658-7c0f957a2715" />






## Conclusion

This implementation successfully demonstrates:
- Removal of internal POR circuitry
- Integration of external reset control
- Complete RTL-to-GLS verification flow
- Functional correctness of the reset mechanism

The modified Caravel SoC design maintains full functionality while providing direct reset control from the testbench environment.



