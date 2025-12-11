# 🚀 RISC-V SoC Tapeout CARAVEL SCL180 

<div align="center">

[![RISC-V](https://img.shields.io/badge/RISC--V-SoC%20Implementation-2E86AB?style=for-the-badge&logo=riscv&logoColor=white)](https://riscv.org/)  
[![Caravel](https://img.shields.io/badge/Caravel-SoC%20Design-FF6B35?style=for-the-badge)](https://caravel-harness.readthedocs.io/)  
[![SCL180](https://img.shields.io/badge/SCL180-PDK-28A745?style=for-the-badge)]()  
[![Phase](https://img.shields.io/badge/Phase-2-9B59B6?style=for-the-badge)]()



**Exploring open-source silicon, one RTL module at a time.**


<img width="1280" height="720" alt="main" src="https://github.com/user-attachments/assets/d4c8dff6-cfe9-4524-be8e-63fd8507e726" />

</div>

---

## 📘 Overview

This repository documents my work in **Phase 2 of the RISC-V SoC Tapeout Program**.  
The focus is on:

- Integrating custom RTL into the **Caravel SoC user project**
- Running **simulation**, **synthesis**, and **GLS flows**
- Understanding the **Caravel harness** and **VexRiscv core**
- Preparing designs for **SCL180nm tapeout**

---

## 🏗️ Project Focus Areas

- 🧩 Integration of custom logic into the Caravel user area  
- 🛠️ RTL → Gate-Level Simulation (GLS) workflow  
- 🧠 Understanding Caravel architecture + VexRiscv pipeline  
- ⚙️ Using both open-source & industry-standard synthesis tools  
- 🧪 Complete verification:  
  - RTL Simulation  
  - Gate-Level Simulation  
  - Functional Equivalence Checking  

---

## 🧰 Technology & Tools

### 🔹 SoC Platform
- **Caravel harness** with integrated **VexRiscv processor**

### 🔹 Process Technology
- **SCL 180nm PDK (Semiconductor Laboratory – India)**

### 🔹 Synthesis Tools
- **Yosys** — Open-source synthesis  
- **Synopsys Design Compiler (DC)** — Industry-grade synthesis  

### 🔹 Simulation Tools
- **Icarus Verilog (iverilog)** — Quick RTL simulation  
- **ModelSim** — Waveform debug & deep testbench analysis  

### 🔹 Verification
- ✔️ RTL Simulation  
- ✔️ Gate-Level Simulation (GLS)  
- ✔️ Functional Equivalence Checking  

---

## 📂 Repository Structure

```bash
📁 src/                 → RTL design files  
📁 sim/                 → Testbenches & simulation scripts  
📁 synthesis/           → Yosys / DC synthesis outputs  
📁 caravel_user/        → Caravel integration (user project)  
📁 docs/                → Notes, logs, screenshots, reports  

```


## 🌟 Key Objectives

- 🚀 **Explore** Caravel SoC architecture and complete design flow  
- 🛠️ **Develop mastery** in RTL synthesis and gate-level simulation  
- 🔎 **Ensure reliability** through rigorous functional verification  
- 📝 **Document** a complete, tapeout-ready methodology for reproducible SoC design  

---

## 📚 Learning Journey Documentation  
> *“A step-by-step transformation from RTL concepts to silicon-ready implementation.”*

This repository captures my hands-on journey through advanced SoC design workflows.  
Each milestone includes detailed explanations, experiments, results, and verification procedures.

---

## 📅 Part 1 — HKSPI Interface • RTL Simulation • GLS Verification

### 🔧 Part1 Summary  
Understanding the Caravel housekeeping SPI, running end-to-end RTL simulations, and validating behavior at the gate-level.

---

<details>
  <summary>
    THEORY OF CARAVEL
  </summary>

## 🏛️ Caravel SoC — Overview

Caravel is a **template SoC platform** designed for the Efabless **Open MPW** and **chipIgnite** shuttle programs, built on the **SkyWater Sky130** open-source PDK.  
It provides a complete SoC harness that allows users to integrate their own custom designs into silicon.

A high-level block diagram of the architecture is shown below:

<img width="3300" height="2550" alt="caravel_block_diagram" src="https://github.com/user-attachments/assets/427ad9e8-fccf-496b-a98a-18e77da5a091" />

For full specifications and documentation, refer to the official Caravel datasheet and reference manuals.

---

## 🧩 Caravel Architecture

Caravel consists of:

- 🟦 A **harness frame**
- 🟧 A **management area wrapper**
- 🟩 A **user project area wrapper**

Each part plays a specific role in enabling user-defined hardware to coexist with a management SoC, GPIO control, and SPI configuration logic.

---

## 🔧 Harness Definition

The **harness** provides essential system infrastructure:

- Clocking module  
- DLL  
- User ID block  
- Housekeeping SPI  
- Power-on reset (POR)  
- GPIO control logic  

### 🌀 Key Behavior Changes (Compared to Earlier Revisions)

- GPIO configuration is now handled by the **housekeeping SPI**, not the management SoC.
- The SPI has a **Wishbone interface**, allowing the management core to control GPIO via Wishbone rather than the raw SPI pins.
- A new configuration block assigns **default GPIO modes at power-up**, programmable via a text configuration file.

### ⚙️ SPI-Based GPIO Initialization

- On startup, the SPI logic **automatically configures GPIO modes**.
- Manual overrides are possible through:
  - SPI front-door access (via GPIO pins 1–4)  
  - Wishbone backdoor access from the management SoC  

### 🏠 Housekeeping Module

All harness-level functions outside the management SoC are grouped into the **housekeeping module**, which contains:

- Registers for configuration and status  
- SPI front-door interface (via pads GPIO 1–4)  
- Wishbone back-door interface (mapped at **0x26000000**)  

A small internal state machine:

- Reads **four contiguous Wishbone addresses**  
- Maps them to SPI registers  
- Stalls the SoC during transfers to ensure correct byte-by-byte handling  

---

## 🖥️ Management Area

The **management area** is a drop-in RISC-V based SoC implemented as a separate repository.  
It includes peripherals such as:

- Timers  
- UART  
- GPIO  
- On-chip SRAM  

### 🎯 Responsibilities of the Management SoC

The management firmware can:

- Configure I/O pads for the User Project  
- Monitor and control User Project signals via **logic analyzer probes**  
- Manage User Project **power domains**  

Documentation for the default management core implementation is available in its dedicated repository.

---

## 🧱 User Project Area

The **user area** is where your custom RTL design lives.

### 📐 Physical Constraints

- Silicon area: **2.92 mm × 3.52 mm**  
- I/O pads: **38 GPIO**  
- Power pads: **4 dedicated pads**

### 🛠️ Resources Available to User Projects

Your design can access:

- **38 user IO ports**  
- **128 logic analyzer probes**  
- **Wishbone interface** to communicate with the management SoC  

This area is fully customizable and forms the heart of the user-defined silicon.

---
## 📁 Required Directory Structure

This project follows the standard directory structure used in Caravel/OpenLane-based ASIC design flows.  
Each directory contains specific file types used across RTL development, synthesis, layout, and verification.

---

### 🗂️ Layout & Physical Design Files

- **gds/**  
  Contains all **GDSII layout files** generated or used in the project.

- **def/**  
  Stores **DEF (Design Exchange Format)** files representing floorplan, placement, or routing stages.

- **lef/**  
  Includes **LEF (Library Exchange Format)** files for macros and technology abstractions.

- **mag/**  
  Contains **Magic layout (.mag)** files used for layout editing and verification.

- **maglef/**  
  Contains **MAGLEF** abstracted layout files typically used for macro integration.

- **spi/lvs/**  
  Stores **SPICE netlists** used for LVS (Layout vs Schematic) verification.

---

### 🧪 Simulation & Verification Directories

- **verilog/dv/**  
  Includes all testbenches, simulation environments, and instructions for running simulations.

- **verilog/gl/**  
  Contains synthesized or elaborated **gate-level netlists**.

- **verilog/rtl/**  
  Contains all **RTL Verilog source files**.

---

### 🛠️ OpenLane Flow Support

- **openlane/<macro>/**  
  Includes all configuration files required to run OpenLane for hardening a macro.

---

### 📄 Project Metadata

- **info.yaml**  
  Includes all required metadata for Caravel integration.  
  Must point to:
  - The **elaborated Caravel netlist**
  - The **synthesized gate-level netlist** for `user_project_wrapper`

---

## 📝 Note

If you are hardening your design using **OpenLane**, the following directories will be auto-populated:

```bash
gds/
def/
lef/
mag/
maglef/
verilog/gl/
```

These outputs are generated automatically during the OpenLane flow.

---


# ⭐ Summary 

| Block                         | Purpose |
|------------------------------|---------|
| **Padframe**                 | Connects chip pins to internal SoC |
| **Clocking + POR**           | Provides stable clock and reset |
| **Housekeeping**             | Loads firmware and manages basic chip functions |
| **Management SoC (CPU)**     | Controls, debugs, and communicates with user design |
| **Wishbone Bus**             | On-chip communication backbone |
| **User Project Wrapper**     | Area for your custom RTL |
| **GPIO Routing**             | Controls how I/O pins behave |

---

## 🎯 Why Caravel Exists

Caravel is designed to make silicon development accessible by providing:

- A working RISC-V CPU  
- On-chip debug (logic analyzer)  
- Pre-designed padframe and power grid  
- Easy communication paths  
- A safe, isolated slot for custom logic


Your only responsibility is implementing logic inside the **User Project Wrapper**.  
Everything else — I/O, clocking, memory, CPU, debug — is already done.

---


</details>






































### 📂 Completed Tasks

| Task | Description | Status |
|------|------------|--------|
| [**Task 1**]) | 🧩 **HKSPI Architecture Exploration** — Studied Caravel’s housekeeping SPI, internal registers, communication pathways, and management core interactions. | ✅ Completed |
| [**Task 2**] | ⚡ **RTL Simulation** — Compiled and executed HKSPI testbench using Icarus Verilog; confirmed *“Test HK SPI (RTL) Passed”*. | ✅ Completed |
| [**Task 3**] | 🏗️ **GLS Validation** — Performed Yosys synthesis, executed gate-level simulation, and verified 100% matching with RTL behavior. | ✅ Completed |

---

### 🌟 Key Learnings — Part 1

- 🔍 **Detailed understanding of HKSPI**: Register mapping, SPI protocol flow, and Caravel management interactions.  
- 🧪 **RTL Simulation confidence**: Successfully validated HKSPI functionality using Icarus Verilog.  
- 🧠 **GLS Insight**: Learned how synthesis transforms RTL and how to ensure cycle-accurate equivalence.  
- 📦 **Tapeout readiness foundation**: Established a repeatable and reliable verification methodology.

---






















