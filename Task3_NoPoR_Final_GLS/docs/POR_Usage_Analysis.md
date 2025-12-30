# POR Usage Analysis – VSD Caravel SoC (SCL-180)

## Purpose of This Document

This document analyzes how the on-chip Power-On Reset (POR) is used in the
existing VSD Caravel RTL and determines whether the design truly depends on it.

The goal is to identify:
- Where `dummy_por` is instantiated
- What POR-related signals drive
- Which blocks actually depend on POR
- Whether POR timing assumptions exist in the RTL

---

## Where `dummy_por` Is Used

The `dummy_por` module is instantiated at the top level (`vsdcaravel.v`) and
generates the following signals:
- `porb_h`
- `porb_l`
- `por_l`

These signals are distributed to:
- Main SoC reset paths
- Housekeeping logic
- Reset distribution networks

---

## Understanding POR Signals

### `porb_h`
- Active-low reset signal
- Drives reset trees for:
  - CPU
  - Peripherals
  - SRAM and interconnect logic
- Functionally equivalent to a normal active-low reset

### `porb_l`
- Intended for housekeeping logic
- Directly derived from `porb_h`
- Does not introduce separate reset sequencing
- Redundant in SCL-180 when using a single external reset

### `por_l`
- Auxiliary reset control signal
- Used only for POR-style sequencing
- Does not directly reset flip-flops

---

## What Does “Fan Into Reset Trees” Mean?

Reset signals are distributed to **many flip-flops** across the SoC.
This distribution network is known as a **reset tree**.

Key observations:
- `porb_h` and `porb_l` are simply sources for reset trees
- They do not perform any special logic
- They do not detect power stability
- They do not implement analog POR behavior

This means POR signals are **functionally interchangeable**
with a normal external reset pin.

---

## Housekeeping Logic Dependency

The housekeeping logic:
- Uses reset as a normal digital signal
- Does not wait for POR completion
- Does not check power stability
- Does not assume delayed reset release

Any dependency on `porb_l` is purely naming-based, not architectural.

---

## RTL Audit: No Logic Assumes Internal POR Timing

After reviewing the RTL:
- No logic waits for POR to complete
- No counters delay reset release
- No logic checks power-good signals
- No logic assumes reset deassertion after a fixed delay

Reset is treated everywhere as a **generic digital reset signal**.

This proves the design does **not architecturally depend on POR**.

---

## Conclusion

- `dummy_por` provides no real hardware functionality
- POR signals only drive reset trees
- No block requires POR-specific timing
- Removing POR does not alter SoC behavior

The design is safe to operate with a **single external reset pin**.
