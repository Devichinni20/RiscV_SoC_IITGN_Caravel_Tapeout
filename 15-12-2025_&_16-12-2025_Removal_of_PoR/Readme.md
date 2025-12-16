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

