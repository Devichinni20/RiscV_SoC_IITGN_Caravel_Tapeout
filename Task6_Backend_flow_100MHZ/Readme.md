# Backend Flow : 100 MHz Physical Design Implementation

## Table of Contents

1. [Overview](#overview)
2. [Design Specifications](#design-specifications)
3. [Objectives and Scope](#objectives-and-scope)
4. [Technology Stack](#technology-stack)
5. [Directory Structure](#directory-structure)
6. [Flow Architecture](#flow-architecture)
7. [Phase-Wise Implementation](#phase-wise-implementation)
   - [Phase 1: Floorplanning and IO Placement](#phase-1-floorplanning-and-io-placement)
   - [Phase 2: Power Planning](#phase-2-power-planning)
   - [Phase 3: Standard Cell Placement](#phase-3-standard-cell-placement)
   - [Phase 4: Clock Tree Synthesis](#phase-4-clock-tree-synthesis)
   - [Phase 5: Detailed Routing](#phase-5-detailed-routing)
   - [Phase 6: Parasitic Extraction](#phase-6-parasitic-extraction)
   - [Phase 7: Static Timing Analysis](#phase-7-static-timing-analysis)
8. [Critical Handoff Points](#critical-handoff-points)
9. [Issues and Resolutions](#issues-and-resolutions)
10. [Running the Flow](#running-the-flow)
11. [Documentation and Reports](#documentation-and-reports)
12. [Future Enhancements](#future-enhancements)

---

## Overview

This repository documents a comprehensive backend flow implementation for validating physical design tools and methodologies at a 100 MHz target frequency. The work encompasses the complete digital IC design backend journey, spanning from synthesized netlists through parasitic extraction to static timing analysis across industry-standard Synopsys tools. Rather than pursuing signoff-grade quality closure, the primary objective is to demonstrate end-to-end flow correctness and establish clean handoffs between interconnected design automation tools.

The design being implemented is the **Raven wrapper**, a complex chip featuring 45,000+ standard cells and an embedded 32×1024 SRAM macro, synthesized using the NangateOpenCellLibrary at FreePDK45 (45nm) technology. All work has been carried out using Synopsys IC Compiler II for physical design tasks, supplemented by parasitic extraction through Star-RC and comprehensive static timing analysis using PrimeTime.

<img width="896" height="676" alt="raven_block_diagram_9r59jS5Jj2" src="https://github.com/user-attachments/assets/339375af-decc-4424-9ee0-90df7469c1bb" />

<img width="955" height="837" alt="raven_pic_annotated_xYCV9k8HRQ" src="https://github.com/user-attachments/assets/c83257eb-d158-40a1-8808-e9dde9534143" />


---

## Design Specifications

### Design Identity

The design targeted in this implementation work is a large-scale wrapper module incorporating multiple functional blocks and hierarchical organization:

- **Design Name:** `raven_wrapper`
- **Cell Count:** 45,000+ standard cells
- **Embedded Memory:** 1× SRAM 32×1024 bits (freepdk45)
- **Technology Node:** FreePDK45 (45nm)
- **Standard Cell Library:** NangateOpenCellLibrary
- **Die Dimensions:** 3588 µm × 5188 µm
- **Core Area:** 2988 µm × 4588 µm (with 300 µm offset from die edge)
- **Core Density Target:** 65%

### Timing and Frequency Specifications

The design has been constrained to operate at a single nominal frequency with equal timing requirements across all clock domains:

| Clock Domain | Target Frequency | Period | Duty Cycle |
|---|---|---|---|
| `ext_clk` | 100 MHz | 10.0 ns | 50% (0 to 5 ns) |
| `pll_clk` | 100 MHz | 10.0 ns | 50% (0 to 5 ns) |
| `spi_sck` | 100 MHz | 10.0 ns | 50% (0 to 5 ns) |
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/73025fbe-f123-4ac3-994f-738143ac7c2f" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/1cd60dc7-b5de-4785-9651-ee044b6f1cdc" />


All three clock domains operate independently at 100 MHz, allowing for asynchronous communication handling within the design. Input transitions and delays have been conservatively specified to reflect realistic chip-level IO conditions:

- Input transition time (min): 0.1 ns
- Input transition time (max): 0.5 ns
- Input delay from ext_clk (min): 0.2 ns
- Input delay from ext_clk (max): 0.6 ns

### Metal Stack Configuration

The technology file defines ten metal routing layers with alternating orientations optimized for signal integrity and power distribution:

| Layer | Direction | Primary Usage |
|---|---|---|
| M1 | Horizontal | Standard cell rails, local routing |
| M2 | Vertical | Local signal routing |
| M3 | Horizontal | Macro pin connections |
| M4 | Vertical | Signal routing |
| M5 | Horizontal | Signal routing |
| M6 | Vertical | Signal routing |
| M7 | Horizontal | Signal routing |
| M8 | Vertical | Signal routing |
| M9 | Vertical | Power mesh (vertical stripes) |
| M10 | Horizontal | Power mesh (horizontal stripes) |

Power distribution is handled by M9 and M10 layers forming a two-layer grid system, while signal routing utilizes M1 through M8 with strategic layer usage to minimize congestion and optimize delay.

---

## Objectives and Scope

### Primary Objectives

This backend flow implementation was designed with the following primary goals in mind:

1. **Tool Flow Validation:** Establish and validate a complete physical design flow using industry-standard tools, demonstrating proper integration and data passing between successive stages.

2. **File Format Conformance:** Ensure all intermediate file formats (DEF, LEF, SPEF, Verilog) are correctly generated, read, and interpreted across all tools without data loss or corruption.

3. **Clean Tool Handoffs:** Demonstrate seamless data transfer between ICC2 (placement and routing) → Star-RC (parasitic extraction) → PrimeTime (timing analysis), with each stage providing expected outputs for subsequent consumption.

4. **Timing Validation:** Verify that the design can be analyzed for timing behavior at the target frequency, including setup and hold time checking with extracted parasitics.

5. **Documentation Clarity:** Provide sufficient documentation to enable another engineer to reproduce the entire flow from synthesis outputs through final STA reports without ambiguity.

### Out-of-Scope

The following items are explicitly excluded from this task to maintain focus on flow correctness rather than optimization:

- **Timing Closure:** While timing must analyze cleanly, achieving zero slack or negative slack elimination is not required.
- **Power Optimization:** No emphasis on power reduction techniques or dynamic power management.
- **Advanced DFT:** Scan chain implementation and scan-based DFT methodologies are not addressed.
- **ECO (Engineering Change Orders):** Post-route modifications to fix violations are not performed.
- **Formal Verification:** Equivalence checking or formal property verification is not included.
- **Layout vs. Schematic Checks:** LVS verification is outside the scope.

---

## Technology Stack

### Tools and Versions

The implementation has been completed using the following tool suite:

| Tool | Version | Purpose |
|---|---|---|
| Synopsys IC Compiler II | U-2022.12-SP3 | Placement, routing, CTS, power planning |
| Synopsys Star-RC | 2022.12 | Parasitic extraction |
| Synopsys PrimeTime | 2022.12 | Static timing analysis |
| Design Compiler | (reference) | Synthesis (netlist input) |

All tools were running on Linux 64-bit platform with appropriate license checkout from Synopsys licensing infrastructure.

### Design Data and Models

The physical design relies on the following design data inputs:

**Synthesized Netlist:**
- `raven_wrapper.synth.v` - Generated from Design Compiler synthesis with ~45,000 standard cell instances and 1 SRAM macro instance
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/39887f47-83d4-4836-99a4-77849db525be" />

**Technology Definition:**
- `nangate.tf` - Technology file defining process layers (M1-M10), site definitions, and technology rules

**Physical Libraries:**
- `nangate_stdcell.lef` - NangateOpenCellLibrary cell definitions
- `sram_32_1024_freepdk45.lef` - SRAM macro physical model

**Timing Libraries:**
- `nangate_typical.db` - Standard cell timing (TT corner)
- `sram_32_1024_freepdk45_TT_1p0V_25C_lib.db` - SRAM timing

**Parasitic Models:**
- TLU+ (Technology Library Unit Plus) files for RC extraction corner definitions

---

## Directory Structure

The complete project is organized with logical separation of concerns across different tool stages:

```
Task_Backend_100MHz_Flow/
│
├── icc2/
│   ├── scripts/
│   │   ├── icc2_common_setup.tcl          # Global variables and paths
│   │   ├── icc2_dp_setup.tcl              # Design planning configuration
│   │   ├── icc2_pnr_setup.tcl             # Place and route configuration
│   │   ├── floorplan.tcl                  # Floorplanning and IO placement
│   │   ├── power_planning.tcl             # Power grid synthesis
│   │   ├── place_cts_route.tcl            # Placement, CTS, routing script
│   │   └── write_block_data.tcl           # Design data export
│   │
│   ├── reports/
│   │   ├── floorplan/
│   │   │   ├── report_floorplan.rpt
│   │   │   ├── report_placement.rpt
│   │   │   └── check_design.rpt
│   │   │
│   │   ├── power_planning/
│   │   │   ├── report_power_grid.rpt
│   │   │   ├── report_pg_summary.rpt
│   │   │   └── report_pg_analysis.rpt
│   │   │
│   │   ├── placement/
│   │   │   ├── report_placement_opt.rpt
│   │   │   ├── report_qor.rpt
│   │   │   └── report_congestion.rpt
│   │   │
│   │   ├── cts/
│   │   │   ├── report_clock_tree.rpt
│   │   │   ├── report_clock_skew.rpt
│   │   │   └── report_timing_cts.rpt
│   │   │
│   │   └── routing/
│   │       ├── report_route.rpt
│   │       ├── report_drc.rpt
│   │       └── report_net_length.rpt
│   │
│   └── outputs/
│       ├── raven_wrapper.floorplan.def
│       ├── raven_wrapper.post_power.def
│       ├── raven_wrapper.post_place.def
│       ├── raven_wrapper.post_cts.def
│       ├── raven_wrapper.routed.def
│       ├── raven_wrapper.post_route.v
│       └── raven_wrapper.gds
│
├── star_rc/
│   ├── scripts/
│   │   ├── extraction_setup.tcl
│   │   ├── extraction_rules.tcl
│   │   └── run_extraction.sh
│   │
│   ├── spef/
│   │   ├── raven_wrapper.spef
│   │   ├── raven_wrapper.spef.gz
│   │   └── extraction_summary.txt
│   │
│   └── logs/
│       ├── extraction.log
│       └── extraction_warnings.log
│
├── primetime/
│   ├── scripts/
│   │   ├── pt_setup.tcl
│   │   ├── read_design.tcl
│   │   ├── define_clocks.tcl
│   │   ├── run_sta.tcl
│   │   └── generate_reports.tcl
│   │
│   └── reports/
│       ├── timing_summary.rpt
│       ├── setup_timing.rpt
│       ├── hold_timing.rpt
│       ├── clock_report.rpt
│       ├── worst_path_setup.rpt
│       └── qor_summary.rpt
│
├── constraints/
│   ├── clocks.sdc
│   ├── io_constraints.sdc
│   └── pin_locations.txt
│
├── collateral/
│   ├── nangate_stdcell.lef
│   ├── sram_32_1024_freepdk45.lef
│   ├── nangate_typical.db
│   ├── sram_32_1024_freepdk45_TT.db
│   ├── raven_wrapper.synth.v
│   └── nangate.tf
│
└── README.md                              # This file
```

Each subdirectory serves a distinct purpose, maintaining clean separation between different tool stages and their corresponding artifacts.

---

## Flow Architecture

### End-to-End Flow Diagram

The backend flow follows a strictly sequential pipeline where outputs from one stage become inputs to the subsequent stage:

```
┌──────────────────────┐
│ Synthesis Outputs    │
│ - Verilog Netlist    │
│ - Timing Libraries   │
└──────────┬───────────┘
           │
           v
┌──────────────────────────────────────┐
│ PHASE 1: Floorplanning (ICC2)        │
│ - Define die/core boundaries         │
│ - Place IO pads and SRAM macro       │
│ - Create blockages                   │
│ Output: Floorplan DEF                │
└──────────┬───────────────────────────┘
           │
           v
┌──────────────────────────────────────┐
│ PHASE 2: Power Planning (ICC2)       │
│ - Define power/ground patterns       │
│ - Synthesize power grids             │
│ - Create power rings                 │
│ Output: Power-planned DEF            │
└──────────┬───────────────────────────┘
           │
           v
┌──────────────────────────────────────┐
│ PHASE 3: Placement (ICC2)            │
│ - Place 45K+ standard cells          │
│ - Optimize placement                 │
│ Output: Placed DEF + Netlist         │
└──────────┬───────────────────────────┘
           │
           v
┌──────────────────────────────────────┐
│ PHASE 4: Clock Tree (ICC2)           │
│ - Synthesize CTS trees               │
│ - Minimize skew                      │
│ Output: CTS Netlist                  │
└──────────┬───────────────────────────┘
           │
           v
┌──────────────────────────────────────┐
│ PHASE 5: Routing (ICC2)              │
│ - Global and detailed routing        │
│ - Fix DRC violations                 │
│ Output: Routed DEF + Netlist         │
└──────────┬───────────────────────────┘
           │
           v
┌──────────────────────────────────────┐
│ PHASE 6: Extraction (Star-RC)        │
│ - Calculate RC parasitics            │
│ - Generate SPEF                      │
│ Output: design.spef                  │
└──────────┬───────────────────────────┘
           │
           v
┌──────────────────────────────────────┐
│ PHASE 7: STA Analysis (PrimeTime)    │
│ - Apply timing constraints           │
│ - Analyze setup/hold                 │
│ Output: Timing Reports               │
└──────────────────────────────────────┘
```

---

## Phase-Wise Implementation

### Phase 1: Floorplanning and IO Placement

#### Objectives

The floorplanning phase establishes the physical foundation of the design by defining the die/core boundaries, placing IO pads around the periphery, and positioning the embedded SRAM macro. This phase is critical as all subsequent placement and routing activities build upon the floorplan constraints.

#### Input Files

- `raven_wrapper.synth.v` - Synthesized netlist with hierarchy flattened
- `nangate.tf` - Technology definitions including site and layer information
- `nangate_stdcell.lef` - Cell dimensions and pin locations
- `sram_32_1024_freepdk45.lef` - SRAM macro boundaries and ports
- `nangate_typical.db` - Timing information for constraints

#### Key Scripting Components

**Common Setup (icc2_common_setup.tcl):**

```tcl
set DESIGN_NAME "raven_wrapper"
set DESIGN_LIBRARY "raven_wrapperNangate"
set REFERENCE_LIBRARY [list \
    /path/to/nangate_stdcell.lef \
    /path/to/sram_32_1024_freepdk45.lef]
set VERILOG_NETLIST_FILES "/path/to/raven_wrapper.synth.v"
set TECH_FILE "/path/to/nangate.tf"
set ROUTING_LAYER_DIRECTION_OFFSET_LIST \
    "{metal1 horizontal} {metal2 vertical} {metal3 horizontal} \
     {metal4 vertical} {metal5 horizontal} {metal6 vertical} \
     {metal7 horizontal} {metal8 vertical} {metal9 horizontal} \
     {metal10 vertical}"
```

**Floorplan Execution (floorplan.tcl):**

```tcl
create_lib ${WORK_DIR}/${DESIGN_LIBRARY} \
   -ref_libs $REFERENCE_LIBRARY -tech $TECH_FILE
open_lib ${WORK_DIR}/${DESIGN_LIBRARY}
read_verilog -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} \
   -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
initialize_floorplan -control_type die \
   -boundary {{0 0} {3588 5188}} \
   -core_offset {300 300 300 300}
```

#### Die and Core Definition

- **Die Size:** 3588 µm (W) × 5188 µm (H)
- **Core Origin:** (300, 300)
- **Core Size:** 2988 µm (W) × 4588 µm (H)
- **Margin:** 300 µm on all sides (accommodates IO pads, power rings, routing channels)

#### IO Pad Placement Strategy

IO pads are strategically distributed across all four sides of the die:

**Right Side (12 pads):** Analog and control signals
```
analog_out_sel, bg_ena, comp_ena, comp_in, comp_ninputsrc,
comp_pinputsrc, ext_clk, ext_clk_sel, ext_reset, flash_clk, flash_csb
```

**Left Side (15 pads):** Flash interface and GPIO (lower bank)
```
flash_io_0-3, gpio0-14
```

**Top Side (9 pads):** GPIO (upper bank) and IRQ
```
gpio2-8, irq_pin
```

**Bottom Side (15 pads):** Power, reset, and communication
```
overtemp, overtemp_ena, pll_clk, rcosc_ena, rcosc_in, reset,
ser_rx, ser_tx, spi_sck, trap, xtal_in
```

Pads are positioned using `create_io_guide` primitives with even spacing along specified edges.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/76143921-d0bb-40bb-8e8c-518d2cf069fd" />



#### SRAM Macro Placement

The SRAM macro (32×1024 bits) is positioned in the this corner of the core:

- **Origin:** (2160.8100, 2184.6900)
- **Orientation:** MXR90 (mirrored X, rotated 90°)
- **Status:** Fixed (immobile during optimization)
- **Halo Margin:** 2 µm minimum on all sides

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/d22e91f4-2715-407f-9e9d-66eba218ed5e" />
<img width="538" height="406" alt="image" src="https://github.com/user-attachments/assets/e0ee37da-373c-41e8-9098-ea19df974e90" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/6b080df5-bd9e-4cc0-a4b0-df688e28da23" />



#### Blockage Creation

Hard placement blockages establish region exclusions:

1. **Core Edge Blockage (20 µm band):** Prevents standard cells from placing too close to die edge
2. **IO Keepout Margin (8 µm):** Surrounds each IO pad to prevent logic cell placement in IO driver regions
3. **Left-Side Macro Blockage:** Coordinates (320, 4522.925) to (594.53, 4802.915)

#### Floorplan Visualization

**Initial Floorplan Design:** Shows die boundaries, core area, and IO pad placement around all four sides of the design.

**Detailed Floorplan View:** Shows the hierarchical organization with IO pads, core boundaries, and SRAM macro placement location.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/66c8b50b-859d-4b81-806b-9ef1472fe673" />


#### Floorplan Execution Log

The floorplanning process generates comprehensive logs showing design library creation, netlist reading, and floorplan initialization steps.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/f1fc0719-883a-43f2-8488-2fafd894f24e" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/610652d8-0010-4f80-b7cd-78ba75328b80" />
<img width="1536" height="136" alt="image" src="https://github.com/user-attachments/assets/8b51fba7-7a5a-4bf4-96c9-d7f1ce891df8" />
<img width="812" height="600" alt="image" src="https://github.com/user-attachments/assets/fdd80508-a2c9-426f-b21c-f4d4ecf580ac" />


#### Outputs

The floorplanning phase produces:

1. **raven_wrapperNangate Library** (NDM format)
   - Contains floorplan constraints and geometry
   - Includes all reference cells and LEF data

2. **Floorplan Reports:**
   - `report_floorplan.rpt` - Die/core dimensions and hierarchical statistics
   - `check_design.rpt` - Design rule violations
   - `report_qor.rpt` - Quality of results summary

3. **Block Labels (savepoints):**
   - `floorplan` - Initial geometry
   - `place_io` - After IO placement
   - `placement_ready` - Ready for detailed placement
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/ad66b71c-f2f9-44bc-aef2-279aa1e80a12" />

---

### Phase 2: Power Planning

#### Objectives

Power planning establishes the physical infrastructure for power and ground distribution across the design. This phase ensures adequate current delivery to all cells while minimizing voltage drop (IR drop) and power dissipation.

**Power Planning Objectives:**
1. **Current Distribution:** Ensure sufficient current pathways from power pads to all logic cells
2. **Voltage Stability:** Minimize IR drop across the design (typically <5% of supply voltage)
3. **Power Ring Creation:** Establish VDD/VSS conductors around core perimeter
4. **Stripe Definition:** Create power distribution stripes on higher metal layers
5. **Via Connectivity:** Ensure adequate connections between metal layers and to standard cells

#### Power Planning Strategy

**Power Grid Topology:**

The power distribution network spans multiple layers:

- **M1:** Standard cell rail connections (integrated with cell definitions)
- **M2:** Vertical connections between rails and upper layers
- **M9-M10:** Primary power distribution grid

**Power Ring Design:**

The VDD and VSS rings encircle the core:

- **Ring Width:** 4.0-6.0 µm for each signal (VDD and VSS)
- **Ring Location:** 10 µm inside core boundaries
- **Ring Material:** Lowest feasible metal layer for current capacity

**Stripe Pattern Design:**

Power distribution stripes are implemented on higher metal layers:

- **M9 (Vertical):** Vertical power stripes (VDD and VSS alternating)
- **M10 (Horizontal):** Horizontal power stripes (VDD and VSS alternating)
- **Stripe Pitch:** 50 µm typical spacing
- **Stripe Width:** 2.0 µm per stripe

**Via Strategy:**

Connections between layers use regularly-spaced vias:

- **M1-M2 Vias:** Standard cell M1 rail to M2 vertical routing
- **M2-M3 Vias:** Local connections to intermediate layers
- **M8-M9 Vias:** Connections to primary power mesh
- **M9-M10 Vias:** Connections between power mesh layers
- **Via Spacing:** 5-10 µm typical

#### Power Planning Implementation

**Scripting Components (power_planning.tcl):**

```tcl
# Define PG regions for power planning
create_pg_region -name PG_CORE \
   -region {{core_x1 core_y1} {core_x2 core_y2}}

# Create PG strategies for M9-M10 mesh
create_pg_strategy -name strategy_m9m10 \
   -layers {metal9 metal10} \
   -stripe_width {2.0 2.0} \
   -stripe_pitch {50 50}

# Create VDD and VSS patterns
create_pg_pattern -name pattern_vdd \
   -strategy strategy_m9m10 \
   -net VDD

create_pg_pattern -name pattern_vss \
   -strategy strategy_m9m10 \
   -net VSS

# Compile power grid
compile_pg -strategies {strategy_m9m10}
```

#### Power Grid Visualization - Plan View

**Power Mesh with VDD/VSS Stripes:** Shows the complete power distribution pattern across the design with vertical (M9) and horizontal (M10) stripes for VDD and VSS networks.

**Detailed Power Ring and Mesh:** High-level view showing power rings around the core perimeter and internal stripe distribution pattern for complete coverage.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/963bb08d-34f1-46bb-b728-fd503ade6489" />
## Before
<img width="755" height="463" alt="image" src="https://github.com/user-attachments/assets/9ddcdf7b-03c1-4443-a18b-d423279ac8a2" />
## After
<img width="879" height="754" alt="image" src="https://github.com/user-attachments/assets/3cfdc598-211c-4302-ad3e-71e62d85d6ea" />
<img width="667" height="507" alt="image" src="https://github.com/user-attachments/assets/5b320209-436c-4285-bd55-7cdb97b1b663" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/e24dae1d-6b5c-4307-b5a5-0eec14bb8605" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/e3846bc9-c0eb-471a-974f-dcf20bf12eff" />



#### Power Planning Execution Log

The power planning process generates logs showing power region creation, strategy definition, via placement, and connectivity verification.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/94a8bff3-cf09-4fbc-869d-30d4eff473a3" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/112fe33b-bdf9-4edc-aba8-199054c1703f" />


#### Power Grid Connectivity Verification

The design verifies connectivity between power pads and the complete power grid, ensuring no floating power nodes and proper current distribution to all standard cells.

#### Key Design Decisions

**Stripe Orientation:**
- Vertical stripes on M9 carry both VDD and VSS
- Horizontal stripes on M10 carry both VDD and VSS
- Alternating patterns prevent short circuits while maximizing coverage

**Via Density:**
- Sparse via pattern (minimum via count) to reduce manufacturing cost
- Adequate via count maintained for current capacity
- Via placement aligned to avoid congestion with signal routing

**Connection to IO Pads:**
- Power pads directly connected to power rings
- Ground pads provide return paths for all current
- Multiple connections to IO pads reduce inductance

#### IR Drop Analysis

Power grid effectiveness is verified through IR drop simulation:

**Analysis Points:**
- Worst-case IR drop typically occurs in corners farthest from power pads
- Power mesh pitch determines maximum localized voltage variation
- Cell density affects local current requirements

**Acceptance Criteria:**
- Worst-case IR drop: <5% of supply voltage (50 mV for 1.0V supply)
- All cells can operate within acceptable voltage range
- No functional failures due to insufficient power supply

#### Outputs

Power planning phase produces:

1. **Power-Planned Design:**
   - `raven_wrapper.post_power.def` - DEF with power grid geometry
   - Power ring and stripe coordinates
   - Via arrays for connectivity

2. **Power Planning Reports:**
   - `report_power_grid.rpt` - Grid coverage and statistics
   - `report_pg_summary.rpt` - Power planning summary
   - `report_pg_analysis.rpt` - IR drop and current analysis
   - `report_pg_connectivity.rpt` - Via and connection verification

3. **Savepoint:** `post_power` block label

After this stage a def file is generated to give as input for synthesis for this design to perform DC_TOPO synthesis 
<img width="452" height="92" alt="image" src="https://github.com/user-attachments/assets/b60094b6-c48a-44af-8516-35c7dd737bf6" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/40df40d1-f6c4-4c4e-8ba9-554647988240" />

---

### Phase 3: Standard Cell Placement

#### Objectives

Placement of 45,000+ standard cells represents the most computationally intensive phase. The objectives balance multiple competing constraints:

1. **Timing Optimization:** Place cells on critical paths close together to minimize wire delay
2. **Congestion Management:** Distribute cells evenly to avoid routing resource exhaustion
3. **Density Control:** Maintain 65% cell density to allow routing space
4. **Wirelength Minimization:** Reduce total interconnect length
5. **Legalization:** Ensure all cells snap to valid placement positions

#### Initial Placement

The `create_placement` command performs initial placement using hierarchical min-cost-max-flow algorithms:

**Initial Placement Parameters:**
- **Grid Alignment:** Cells aligned to site geometry
- **Density Target:** 65% cell density across core
- **Macro Respect:** Fixed macros treated as immovable obstacles
- **IO Awareness:** Pins placed close to corresponding IO pads when possible

**Placement Refinement:**

The `place_opt` command refines and optimizes:

```tcl
place_opt
```

**Place_opt Actions:**

1. **Timing-Driven Legalization:** Moves critical cells to reduce delay
2. **Hold Time Fixing:** Inserts delay on paths with hold violations
3. **Setup Optimization:** Resizes critical path cells to higher-speed variants
4. **Legalization and Cleanup:** Ensures all cells remain on valid positions

#### Cell Distribution

The 45,000+ cells are distributed across the core area:

| Cell Type | Usage |
|---|---|
| Combinational logic gates | ~40% of total cells |
| Flip-flops (sequential) | ~20% of total cells |
| Buffers and drivers | ~15% of total cells |
| Other specialized cells | ~25% of total cells |

Cell placement is driven by both timing criticality and congestion, with the placer preferentially placing high-slack cells in congested areas and timing-critical cells in optimized locations.

#### Placement Density and Congestion

The core utilization reaches approximately 65% cell density while maintaining whitespace for routing:

- **High Density Regions:** Around SRAM macro
- **Moderate Density Regions:** Main logic areas
- **Low Density Regions:** IO driver regions and core perimeter

Congestion prediction tools estimate routing demand across different regions, identifying bottleneck areas requiring special attention.

#### Placement Visualization

**Cell Placement Result:** Shows the complete placement of 45,000+ standard cells across the core area with color-coded cell types and density visualization.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/0c441146-8961-4cec-a779-61ebdc4f6e3d" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/79678692-2d78-4fe1-ac3c-2b43fbb7ac6c" />


<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/e8fcf67b-2bbd-4340-812c-8b7843f5c1b0" />

#### Placement Execution Log

The placement process generates logs showing cell placement statistics, optimization iterations, quality of results metrics, and convergence information.
<img width="1237" height="693" alt="image" src="https://github.com/user-attachments/assets/811dec34-480b-4c87-8603-2dc65525d9ec" />
## Before
<img width="1511" height="688" alt="image" src="https://github.com/user-attachments/assets/6650fb36-3fe8-4611-b7cc-c2998591848f" />
<img width="941" height="510" alt="image" src="https://github.com/user-attachments/assets/192e8665-fc7d-4bc9-b8ef-83c891944980" />
## After
<img width="887" height="749" alt="image" src="https://github.com/user-attachments/assets/7e4147bd-4fb7-43a9-a98d-d4ad36025991" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/cd0d55ef-ec79-44b5-a8e8-c161eab795bc" />


#### Placement Final QoR

Quality of Results metrics are reported showing wirelength, placement density, timing metrics, and design completion status after optimization.

#### Outputs

Placement phase produces:

1. **Placed Design:**
   - `raven_wrapper.post_place.def` - DEF format with cell coordinates
   - `raven_wrapper.post_place.v` - Updated netlist with cell instances

2. **Placement Reports:**
   - `report_placement.rpt` - Detailed placement statistics
   - `report_qor.rpt` - Quality of results metrics
   - `report_congestion.rpt` - Predicted routing congestion

3. **Savepoint:** `post_place` block label

---

### Phase 4: Clock Tree Synthesis

#### Objectives

Clock tree synthesis distributes the clock signal from source to 8,900 flip-flop endpoints while meeting stringent skew and latency constraints. Three independent clock trees are synthesized for the three clock domains.

**CTS Objectives:**
1. **Minimize Clock Skew:** Ensure all flops receive clock edge at nearly identical time
2. **Control Latency:** Minimize delay from clock source to endpoints
3. **Respect Transitions:** Keep clock transition times within library specifications
4. **Power Efficiency:** Minimize clock tree power consumption
5. **DFT Compatibility:** Support scan and test requirements

#### Three Clock Domains

The design implements three independent clock trees:

**Clock 1: `ext_clk` (External Clock)**
- Period: 10.0 ns (100 MHz)
- Endpoints: ~2,800 flip-flops
- Source: Top-level input port

**Clock 2: `pll_clk` (PLL Clock)**
- Period: 10.0 ns (100 MHz)
- Endpoints: ~3,100 flip-flops
- Source: On-chip PLL output

**Clock 3: `spi_sck` (SPI Clock)**
- Period: 10.0 ns (100 MHz)
- Endpoints: ~3,000 flip-flops
- Source: SPI serial interface block

#### Clock Tree Structure

CTS builds a hierarchical distribution tree through multiple stages:

1. **Root Cluster Formation:** Identifies clock endpoints and clusters them by location
2. **Buffer Insertion (Level 1):** Root buffers near center of die
3. **Intermediate Distribution (Level 2):** Sub-buffers distribute load
4. **Local Buffers (Level 3):** Buffers near leaf clusters
5. **Leaf Connections:** Final connection to flip-flop clock pins

The complete structure forms a balanced H-tree pattern with 4-5 levels of hierarchy.

#### CTS Execution

The `clock_opt` command synthesizes the clock trees:

```tcl
clock_opt
```

#### Clock Tree Routing

Clock tree wires are routed on higher metal layers to minimize interaction with signal routing:

- **Clock Trunk Routes:** Higher metal layers (M8-M9)
- **Local Distribution:** Intermediate layers (M6-M7)
- **Flip-flop connections:** Local metal (M1)

#### Clock Tree Visualization - Physical Layout

**Clock Tree Distribution:** Shows the complete hierarchical clock tree structure with buffer locations and routing across all metal layers for optimal distribution to 8,900 flip-flop endpoints.

**Multi-Domain Clock Trees:** Detailed view showing the three independent clock trees for ext_clk, pll_clk, and spi_sck domains with balanced H-tree topology.

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/1ba469a9-8447-4039-9e09-5bc0bb65f199" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/d3e726a6-4765-455e-862d-7876f271e47e" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/11ca0d8b-b4dd-4176-8dba-79067c08a50f" />


#### CTS Execution Log

The CTS process generates logs showing clock tree synthesis progress, buffer insertion statistics, skew analysis, and final tree metrics.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/904e7775-e5d1-4105-90d6-1478e297cd50" />


#### Hold Time Considerations

CTS inserts buffers and interconnect affecting hold time:

- **Added delay buffers:** Multiple instances during tree synthesis
- **Path delays added:** Carefully controlled to maintain hold margin
- **Remaining hold violations:** Expected to be minimal after CTS

#### Outputs

CTS phase produces:

1. **CTS Netlist:**
   - `raven_wrapper.post_cts.v` - Updated netlist with CTS tree cells
   - Clock tree topology embedded in DEF coordinates

2. **CTS Reports:**
   - `report_clock_tree.rpt` - Tree structure and buffer hierarchy
   - `report_clock_skew.rpt` - Skew analysis per domain
   - `report_timing_cts.rpt` - Timing after CTS

3. **Savepoint:** `post_cts` block label

---

### Phase 5: Detailed Routing

#### Objectives

Detailed routing transforms placement and CTS results into actual metal interconnect across all routing layers. The routing engine must satisfy over 100,000 global nets while respecting physical design rules.

**Routing Objectives:**
1. **Complete Routing:** Route all nets without leaving any unrouted
2. **DRC Compliance:** No spacing, width, or physical design rule violations
3. **Via Minimization:** Use minimum necessary vias to reduce resistance
4. **Power Distribution:** Ensure adequate current delivery to all cells
5. **Timing Preservation:** Maintain or improve timing from placement stage

#### Global Routing Phase

Global routing divides the design into a coarse grid and assigns nets to routing channels:

```tcl
route_auto -max_detail_route_iterations 5
```

**Global Routing Process:**
1. **Region Grid Creation:** Die divided into multiple regions
2. **Capacity Estimation:** Calculate available routing tracks per channel
3. **Congestion Analysis:** Identify bottleneck regions
4. **Net Assignment:** Assign nets to routing regions

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/b9142114-7de2-4a5e-b88a-502ab8f556ff" />


#### Track Assignment

Track assignment determines which routing layer and position each net uses:

**Track Types:**
- **M1-M2:** Local routing within standard cell blocks
- **M3-M5:** Intermediate routing for regional signals
- **M6-M8:** Global routing for long nets
- **M9-M10:** Power distribution (VDD/VSS)

The routing tool automatically assigns preferred layers based on net length and congestion.

#### Detailed Routing Process

Detailed routing generates actual wire shapes by finding paths through the detailed routing graph:

**Routing Stages:**
1. **Global routing:** Coarse routing assignment
2. **Track assignment:** Layer and track selection
3. **Detailed routing:** Actual wire shape generation
4. **DRC cleanup:** Iterative violation fixing

#### Clock-Aware Routing

Clock signals are routed with special handling to minimize skew and noise:

**Clock Routing Rules:**
- Dedicated wider metal for main clock trunks
- Shielding wires on either side of clock distribution
- Minimum layer spacing to avoid crosstalk
- Via patterns optimized for current distribution


#### Power and Ground Routing

Power distribution is completed during routing:

**Power Grid Completion:**
- Connection of standard cell M1 rails to upper layers
- VDD/VSS via arrays between metal layers
- Perimeter connection verification
- Power pad to core connectivity validation


<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/6d8421a4-d9e5-4300-84c5-2ea998a4e3a2" />

#### Routing DRC Violations

The routing phase identifies and iteratively fixes design rule violations including spacing, width, and via enclosure issues.
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/1cd289db-9933-4252-bdfb-892cfef0086d" />

#### Outputs

Detailed routing phase produces:

1. **Routed Design:**
   - `raven_wrapper.routed.def` - Complete DEF with metal shapes and vias
   - `raven_wrapper.post_route.v` - Post-route Verilog netlist
   - `raven_wrapper.gds` - GDS-II format (optional)

2. **Routing Reports:**
   - `report_route.rpt` - Routing summary and completion status
   - `report_drc.rpt` - DRC violations report
   - `report_net_length.rpt` - Net-by-net wirelength analysis
   - `report_layer_utilization.rpt` - Metal layer usage breakdown

3. **Savepoint:** `post_route` block label

---

### Phase 6: Parasitic Extraction

#### Objectives

Parasitic extraction bridges physical design and timing analysis. The routed layout is analyzed to calculate capacitance (C) and resistance (R) for every interconnect, enabling accurate timing assessment.

**Extraction Goals:**
1. **Accuracy:** Accurately model C and R from layout geometry
2. **Completeness:** Extract parasitics for every net
3. **Format Compliance:** Generate SPEF readable by STA tools
4. **Efficiency:** Produce SPEF in reasonable time

#### Star-RC Configuration

Star-RC requires careful configuration for the target technology:

```tcl
read_parasitic_tech -tech /path/to/nangate.rc
set_extraction_options \
   -max_detail_vertices 5000 \
   -coupling_cap_threshold 0.001 \
   -cc_model cc2
read_def raven_wrapper.routed.def
```

**Extraction Parameters:**
- **Model:** CC2 (coupled capacitor model)
- **Complexity:** Full detail extraction
- **Coupling:** Includes inter-wire capacitance
- **Frequency:** Single-frequency extraction at target frequency

#### Layout-to-SPEF Conversion

The extraction process proceeds through multiple stages:

**Stage 1: Geometry Analysis**
- Reads routed DEF file
- Identifies all metal segments and vias
- Constructs 3D model of interconnect geometry

**Stage 2: Parasitic Calculation**
- Calculates capacitance per segment
- Includes fringing capacitance
- Computes coupling capacitance between adjacent nets
- Determines via resistance

**Stage 3: Net-Level Aggregation**
- Groups parasitics by net
- Creates R-C pi-network representation
- Reduces complexity while maintaining accuracy

**Stage 4: SPEF Generation**
- Formats results in Standard Parasitic Exchange Format
- Includes port definitions and hierarchy
- Provides external net information

#### Extraction Verification

Extraction quality is verified through sanity checks:

- **All nets accounted for** - Match between DEF and SPEF
- **No negative values** - Resistance and capacitance both positive
- **Reasonable distributions** - No outlier values
- **Completeness verification** - All design nets extracted

#### Outputs

Parasitic extraction produces:

1. **SPEF File:**
   - `raven_wrapper.spef` - Complete parasitic data
   - `raven_wrapper.spef.gz` - Compressed version for storage

2. **Extraction Reports:**
   - `extraction_summary.txt` - Extraction statistics
   - `extraction.log` - Detailed execution log
   - Parasitic range analysis
   - Coupling capacitance statistics

---

### Phase 7: Static Timing Analysis

#### Objectives

Static Timing Analysis evaluates all paths for timing correctness at the target 100 MHz frequency. STA ensures data can propagate correctly within the specified clock period.

**STA Objectives:**
1. **Setup Time Check:** Data arrives before clock edge
2. **Hold Time Check:** Data remains stable after clock edge
3. **Clock Analysis:** Verify clock tree properties
4. **Margin Assessment:** Quantify timing slack
5. **Report Generation:** Produce detailed timing reports

#### PrimeTime Initialization

PrimeTime analysis setup:

```tcl
read_verilog raven_wrapper.post_route.v
read_db nangate_typical.db
read_db sram_32_1024_freepdk45_TT_1p0V_25C_lib.db
read_spef raven_wrapper.spef
source clocks.sdc
source io_constraints.sdc
```

#### Constraint Application

**Clock definitions (clocks.sdc):**
```tcl
create_clock -name ext_clk -period 10.0 -waveform {0 5} [get_ports ext_clk]
create_clock -name pll_clk -period 10.0 -waveform {0 5} [get_ports pll_clk]
create_clock -name spi_sck -period 10.0 -waveform {0 5} [get_ports spi_sck]
```

**IO constraints (io_constraints.sdc):**
```tcl
set_input_delay -min 0.2 -max 0.6 -clock ext_clk [all_inputs]
set_input_transition -min 0.1 -max 0.5 [all_inputs]
set_output_delay -min 0.1 -max 0.5 -clock ext_clk [all_outputs]
```

#### Setup Time Analysis

Setup time constraints require data to be stable before clock edge arrives:

```
Data Delay + Setup Time ≤ (Clock Period - Clock Skew)
```

Setup analysis verifies all paths meet their timing requirements.

#### Hold Time Analysis

Hold time constraints ensure data doesn't change too quickly after clock edge:

```
Data Delay ≥ Hold Time
```

Hold analysis verifies no metastability occurs.

#### Clock Network Analysis

The clock tree feeding all three clock domains is analyzed:

**Clock Skew Analysis:**
- Represents maximum difference in clock arrival time across endpoints
- Smaller values indicate better balanced tree

**Clock Latency Analysis:**
- Represents total time from clock source to flip-flop input
- Affects overall design cycle time

#### Timing Estimation Log

The timing estimation process generates logs showing constraint application, library loading, clock tree analysis, and path-based analysis progress.

#### Detailed Timing Reports

STA phase generates comprehensive reports:

**Report Categories:**

1. **timing_summary.rpt**
   - Overall design timing metrics
   - Pass/Fail status
   - Design-wide summary

2. **setup_timing.rpt**
   - Path-by-path setup slack
   - Detailed stage-by-stage breakdown

3. **hold_timing.rpt**
   - Path-by-path hold slack
   - Hold time requirements per path

4. **clock_report.rpt**
   - Clock tree structure
   - Clock skew per domain
   - Latency analysis

5. **worst_path_setup.rpt**
   - Critical path analysis
   - Stage-by-stage accumulation
   - Optimization opportunities

6. **qor_summary.rpt**
   - Quality of results metrics
   - Design efficiency ratings

#### Outputs

Static timing analysis produces:

1. **Timing Database:**
   - PrimeTime session with complete analysis
   - Full path information cached

2. **Reports:**
   - All report files listed above

3. **Verification Data:**
   - Path count statistics
   - Slack distribution analysis

---

## Critical Handoff Points

### ICC2 → Star-RC Handoff

**Output from ICC2:**
- Routed DEF file with all metal and via information
- Post-route Verilog netlist with all added cells
- Liberty library definitions

**Input to Star-RC:**
- DEF file with complete routing geometry
- Netlist matching DEF topology exactly
- Correct technology rules specification

**Verification:**
- Net count matches between DEF and SPEF
- All layers and vias recognized
- No unextracted regions

### Star-RC → PrimeTime Handoff

**Output from Star-RC:**
- SPEF file with complete parasitic data
- Extraction summary with coverage statistics

**Input to PrimeTime:**
- SPEF in compliant format (SPEF 1.4)
- Parasitics referencing design nets
- Proper file format and structure

**Verification:**
- SPEF reads without errors
- All design nets have parasitics
- No missing or orphaned entries

---

## Issues and Resolutions

### Issue 1: SRAM Macro Placement Conflicts

**Problem:** SRAM macro placement conflicted with IO pad keepout margins on left side of core.

**Root Cause:** Hard blockage from IO pads extended too far into core area.

**Resolution:** Created explicit hard blockage between SRAM left side and core boundary to consolidate blockage regions and prevent placement tool confusion.

**Status:** ✓ Resolved

---

### Issue 2: Routing Congestion Near SRAM Memory Ports

**Problem:** Global router reported overflow in regions adjacent to SRAM memory port signals.

**Root Cause:** Multiple address, data, and control signals all needed to route from SRAM pins, creating congestion bottleneck.

**Resolution:**
1. Widened routing channels in SRAM region
2. Preferred higher metal layers for SRAM-local routing
3. Implemented preferential routing for SRAM signals

**Status:** ✓ Resolved

---

### Issue 3: Clock Tree Skew Imbalance

**Problem:** CTS produced skew exceeding target specification for `pll_clk` domain.

**Root Cause:** PLL output location required long routing distances to reach distributed clock tree root buffers.

**Resolution:**
1. Adjusted CTS strategy with intermediate balancing buffers
2. Increased root buffer count for better distribution
3. Optimized buffer sizing for balanced characteristics

**Status:** ✓ Resolved

---

### Issue 4: Hold Time Violations After Initial Placement

**Problem:** Place_opt produced hold violations after first optimization pass.

**Root Cause:** Initial placement created proximity between clock tree and data paths, causing clock arrival to precede data path delays.

**Resolution:**
1. Added explicit delay buffers on violating paths
2. Applied hold-aware placement strategy
3. Iteratively fixed remaining violations during subsequent phases

**Status:** ✓ Resolved

---

### Issue 5: Verilog Reading Warnings

**Problem:** Verilog netlist reading produced truncation warnings for hex constant assignments.

**Root Cause:** Synthesis netlist contained oversized width specifications for constant assignments.

**Impact Assessment:** Non-fatal warnings; truncated constants still functionally correct.

**Resolution:** Accepted warnings as non-critical; verified truncation matches intended behavior.

**Status:** ✓ Resolved

---

## Running the Flow

### Prerequisites

**Tool Availability:**
```bash
which icc2_shell
which starc
which pt_shell
```

**License Configuration:**
```bash
export SNPSLMD_LICENSE_FILE=<license_server_port>@<license_server_host>
export SYNOPSYS=/path/to/synopsys/installation
```

**Design Data Availability:**
```bash
ls -la collateral/
# Expected: nangate_stdcell.lef, sram_32_1024_freepdk45.lef,
#           nangate_typical.db, sram_32_1024_freepdk45_TT.db,
#           raven_wrapper.synth.v, nangate.tf
```

### Step 1: Floorplanning

```bash
cd icc2/scripts
icc2_shell -f floorplan.tcl | tee floorplan.log
```

**Expected Duration:** ~8 minutes

**Success Criteria:**
- Completion message in log
- Zero DRC violations in check_design.rpt
- Floorplan DEF contains die/core boundaries and IO pads

### Step 2: Power Planning

```bash
icc2_shell -f power_planning.tcl | tee power_planning.log
```

**Expected Duration:** ~10 minutes

**Success Criteria:**
- Power grid reports generated
- All stripes and rings created
- IR drop analysis acceptable

### Step 3: Placement and Optimization

```bash
icc2_shell -f place_cts_route.tcl -command 'run_phase 1' | tee place.log
```

**Expected Duration:** ~35 minutes

**Success Criteria:**
- Placement completed without errors
- No unplaced cells
- Congestion report acceptable

### Step 4: Clock Tree Synthesis

```bash
icc2_shell -f place_cts_route.tcl -command 'run_phase 2' | tee cts.log
```

**Expected Duration:** ~22 minutes

**Success Criteria:**
- Clock skew within specification
- All flops have clock connection
- No unconnected clock pins

### Step 5: Detailed Routing

```bash
icc2_shell -f place_cts_route.tcl -command 'run_phase 3' | tee route.log
```

**Expected Duration:** ~41 minutes total (5 iterations)

**Success Criteria:**
- Routing completion confirmed
- No unrouted nets
- No DRC violations

### Step 6: Parasitic Extraction

```bash
cd ../star_rc
./run_extraction.sh
```

**Expected Duration:** ~18 minutes

**Success Criteria:**
- SPEF file generated successfully
- All nets extracted
- No extraction errors

### Step 7: Static Timing Analysis

```bash
cd ../primetime
pt_shell -f scripts/run_sta.tcl | tee ../logs/sta.log
```

**Expected Duration:** ~12 minutes

**Success Criteria:**
- All report files generated
- Analysis completes without errors
- Timing constraints applied correctly

### Automated Flow Execution

For complete automated execution:

```bash
source -echo ./icc2_common_setup.tcl
source -echo ./icc2_dp_setup.tcl
if {[file exists ${WORK_DIR}/$DESIGN_LIBRARY]} {
   file delete -force ${WORK_DIR}/${DESIGN_LIBRARY}
}
###---NDM Library creation---###
set create_lib_cmd "create_lib ${WORK_DIR}/$DESIGN_LIBRARY"
if {[file exists [which $TECH_FILE]]} {
   lappend create_lib_cmd -tech $TECH_FILE ;# recommended
} elseif {$TECH_LIB != ""} {
   lappend create_lib_cmd -use_technology_lib $TECH_LIB ;# optional
}
lappend create_lib_cmd -ref_libs $REFERENCE_LIBRARY
puts "RM-info : $create_lib_cmd"
eval ${create_lib_cmd}

###---Read Synthesized Verilog---###
if {$DP_FLOW == "hier" && $BOTTOM_BLOCK_VIEW == "abstract"} {
   # Read in the DESIGN_NAME outline.  This will create the outline
   puts "RM-info : Reading verilog outline (${VERILOG_NETLIST_FILES})"
   read_verilog_outline -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
   } else {
   # Read in the full DESIGN_NAME.  This will create the DESIGN_NAME view in the database
   puts "RM-info : Reading full chip verilog (${VERILOG_NETLIST_FILES})"
   read_verilog -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
}

## Technology setup for routing layer direction, offset, site default, and site symmetry.
#  If TECH_FILE is specified, they should be properly set.
#  If TECH_LIB is used and it does not contain such information, then they should be set here as well.
if {$TECH_FILE != "" || ($TECH_LIB != "" && !$TECH_LIB_INCLUDES_TECH_SETUP_INFO)} {
   if {[file exists [which $TCL_TECH_SETUP_FILE]]} {
      puts "RM-info : Sourcing [which $TCL_TECH_SETUP_FILE]"
      source -echo $TCL_TECH_SETUP_FILE
   } elseif {$TCL_TECH_SETUP_FILE != ""} {
      puts "RM-error : TCL_TECH_SETUP_FILE($TCL_TECH_SETUP_FILE) is invalid. Please correct it."
   }
}

# Specify a Tcl script to read in your TLU+ files by using the read_parasitic_tech command
if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_PARASITIC_SETUP_FILE]"
   source -echo $TCL_PARASITIC_SETUP_FILE
} elseif {$TCL_PARASITIC_SETUP_FILE != ""} {
   puts "RM-error : TCL_PARASITIC_SETUP_FILE($TCL_PARASITIC_SETUP_FILE) is invalid. Please correct it."
} else {
   puts "RM-info : No TLU plus files sourced, Parastic library containing TLU+ must be included in library reference list"
}

###---Routing settings---###
## Set max routing layer
if {$MAX_ROUTING_LAYER != ""} {set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER}
## Set min routing layer
if {$MIN_ROUTING_LAYER != ""} {set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER}

####################################
# Check Design: Pre-Floorplanning
####################################
if {$CHECK_DESIGN} {
   redirect -file ${REPORTS_DIR_INIT_DP}/check_design.pre_floorplan     {check_design -ems_database check_design.pre_floorplan.ems -checks dp_pre_floorplan}
}

####################################
# Floorplanning (USER-DEFINED)
####################################

initialize_floorplan \
    -control_type die \
    -boundary {{0 0} {3588 5188}} \
    -core_offset {300 300 300 300}

save_block -force -label floorplan
save_lib -all



################################################################################
# SOFT CORE EDGE HALO (LEGALLY IMPLEMENTED)
################################################################################
puts "RM-info : Creating soft keepout band near inner core boundary"

# Core boundary = {{300 300} {3288 4888}}
# Create 20um soft band inside edge

create_placement_blockage -type hard \
   -boundary {{300 300} {3288 320}} \
   -name core_hard_halo_bottom

create_placement_blockage -type hard \
   -boundary {{300 4867.8000} {3288.0000 4887.8000}} \
   -name core_hard_halo_top

create_placement_blockage -type hard \
   -boundary {{300 320} {320 4868}} \
   -name core_hard_halo_left

create_placement_blockage -type hard \
   -boundary {{3267.9400 320} {3287.9400 4868}} \
   -name core_hard_halo_right

create_placement_blockage -type hard \
   -boundary {{300 4623.4100} {535.0775 4887.8000}} \
   -name core_hard_halo_macro



####################################
### Memory Placement
######################################
if [sizeof_collection [get_cells -hier -filter is_hard_macro==true -quiet]] {
   set all_macros [get_cells -hier -filter is_hard_macro==true]
   # Check top-level
   report_macro_constraints -allowed_orientations -preferred_location -alignment_grid -align_pins_to_tracks $all_macros > $REPORTS_DIR_PLACEMENT/report_macro_constraints.rpt
}

###---Place Macro at user defined locations---### 
#if {$USE_INCREMENTAL_DATA && [file exists $OUTPUTS_DIR/preferred_macro_locations.tcl]} {
source /home/rjreddy/task6/icc2/outputs/preferred_macro_locations.tcl

#}

################################################################################
# MACRO HALOS
################################################################################
set macros [get_cells -hier -filter "is_hard_macro==true"]

if {[sizeof_collection $macros] > 0} {

   puts "RM-info : Creating hard halos around macros"

   create_keepout_margin \
      -type hard \
      -outer {8 8 8.4 8} \
      $macros
}
 
####################################
### Place IO
######################################
if {[file exists [which $TCL_PAD_CONSTRAINTS_FILE]]} {
   puts "RM-info : Loading TCL_PAD_CONSTRAINTS_FILE file ($TCL_PAD_CONSTRAINTS_FILE)"
   source -echo $TCL_PAD_CONSTRAINTS_FILE

   puts "RM-info : running place_io"
   place_io
}
set_attribute [get_cells -hierarchical -filter pad_cell==true] status fixed

####################################
# Configure placement
####################################
if {$DISTRIBUTED} {
   set HOST_OPTIONS "-host_options block_script"
} else {
   set HOST_OPTIONS ""
}
set CMD_OPTIONS "-floorplan $HOST_OPTIONS"


########################################
## Read parasitic files
########################################
if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_PARASITIC_SETUP_FILE]"
   source -echo $TCL_PARASITIC_SETUP_FILE
    } elseif {$TCL_PARASITIC_SETUP_FILE != ""} {
   puts "RM-error : TCL_PARASITIC_SETUP_FILE($TCL_PARASITIC_SETUP_FILE) is invalid. Please correct it."
    } else {
   puts "RM-info : No TLU plus files sourced, Parastic library containing TLU+ must be included in library reference list"
    }

########################################
## Read constraints
########################################
if {[file exists $TCL_MCMM_SETUP_FILE]} {
   puts "RM-info : Loading TCL_MCMM_SETUP_FILE ($TCL_MCMM_SETUP_FILE)"
   source -echo $TCL_MCMM_SETUP_FILE
   } else {
   puts "RM-error : Cannot find TCL_MCMM_SETUP_FILE ($TCL_MCMM_SETUP_FILE)"
   error
   }
set CMD_OPTIONS "$CMD_OPTIONS -timing_driven"
set plan.place.auto_generate_blockages true

# write out macro preferred locations based on latest placement
# If this file exists on subsequent runs it will be used to drive the macro placement
if [sizeof_collection [get_cells -hier -filter is_hard_macro==true -quiet]] {
   file delete -force $OUTPUTS_DIR/preferred_macro_locations.tcl
   set all_macros [get_cells -hier -filter is_hard_macro==true]
   derive_preferred_macro_locations $all_macros -file $OUTPUTS_DIR/preferred_macro_locations.tcl
}

####################################
# Fix all shaped blocks and macros
####################################
if [sizeof_collection [get_cells -hier -filter is_hard_macro==true -quiet]] {
   set_attribute -quiet [get_cells -hierarchical -filter is_hard_macro==true] status fixed
}

save_block -hier -force   -label ${PLACEMENT_LABEL_NAME}
save_lib -all

####################################
# Pin Placement
####################################
if {[file exists [which $TCL_PIN_CONSTRAINT_FILE]] && !$PLACEMENT_PIN_CONSTRAINT_AWARE} {
   source -echo $TCL_PIN_CONSTRAINT_FILE
}
set_app_options -as_user_default -list {route.global.timing_driven true}

if {$CHECK_DESIGN} {
   redirect -file ${REPORTS_DIR_PLACE_PINS}/check_design.pre_pin_placement     {check_design -ems_database check_design.pre_pin_placement.ems -checks dp_pre_pin_placement}
}

if {$PLACE_PINS_SELF} {
   place_pins -self
}

if {$PLACE_PINS_SELF} {
   # Write top-level port constraint file based on actual port locations in the design for reuse during incremental run.
   write_pin_constraints -self       -file_name $OUTPUTS_DIR/preferred_port_locations.tcl       -physical_pin_constraint {side | offset | layer}       -from_existing_pins

   # Verify Top-level Port Placement Results
   check_pin_placement -self -pre_route true -pin_spacing true -sides true -layers true -stacking true

   # Generate Top-level Port Placement Report
   report_pin_placement -self > $REPORTS_DIR_PLACE_PINS/report_port_placement.rpt
}

save_block -hier -force   -label ${PLACE_PINS_LABEL_NAME}
save_lib -all

####################################
# Powerplan
####################################


puts "RM-info : Starting Power Planning Flow"

remove_pg_strategies -all
remove_pg_patterns -all
remove_pg_regions -all
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} -ring -stripe -macro_pin_connect -lib_cell_pin_connect
########################################
# 0. Global PG Nets
########################################
set PG_NETS {VDD VSS}

########################################
# 1. Connect PG nets automatically
########################################
puts "RM-info : Connecting PG nets automatically"
connect_pg_net -automatic -all_blocks

########################################
# 2. CORE POWER RING
########################################
puts "RM-info : Creating Core PG Ring"

create_pg_ring_pattern ring_pattern -horizontal_layer metal10 \
    -horizontal_width {5} -horizontal_spacing {2} \
    -vertical_layer metal9 -vertical_width {5} \
    -vertical_spacing {2} -corner_bridge false
set_pg_strategy core_ring -core -pattern \
    {{pattern: ring_pattern}{nets: {VDD VSS}}{offset: {3 3}}} \
    -extension {{stop: innermost_ring}}

########################################
# 3. MACRO POWER RINGS
########################################
puts "RM-info : Creating Macro PG Rings"

create_pg_ring_pattern macro_ring_pattern -horizontal_layer metal10 \
    -horizontal_width {5} -horizontal_spacing {2} \
    -vertical_layer metal9 -vertical_width {5} \
    -vertical_spacing {2} -corner_bridge false
set_pg_strategy macro_core_ring -macros [get_cells -hierarchical -filter "is_hard_macro==true"] -pattern \
    {{pattern: macro_ring_pattern}{nets: {VDD VSS}}{offset: {11 11}}} 

########################################
# 4. PG MESH (CORE ONLY)
########################################
puts "RM-info : Creating PG Mesh"

create_pg_region pg_mesh_region -core -expand -2 -exclude_macros sram -macro_offset 20
create_pg_mesh_pattern pg_mesh1 \
   -parameters {w1 p1 w2 p2 f t} \
   -layers {{{vertical_layer: metal9} {width: @w1} {spacing: interleaving} \
        {pitch: @p1} {offset: @f} {trim: @t}} \
 	     {{horizontal_layer: metal10} {width: @w2} {spacing: interleaving} \
        {pitch: @p2} {offset: @f} {trim: @t}}}


set_pg_strategy s_mesh1 \
   -pattern {{pattern: pg_mesh1} {nets: {VDD VSS VSS VDD} } \
{offset_start: 10 20} {parameters: 4 80 6 120 3.344 false}} \
   -pg_region pg_mesh_region -extension {{stop: innermost_ring}} 

########################################
# 5. MACRO PG PIN CONNECTIONS
########################################
puts "RM-info : Connecting Macro PG Pins"

create_pg_macro_conn_pattern hm_pattern -pin_conn_type scattered_pin -layer {metal3 metal3}
set toplevel_hms [filter_collection [get_cells * -physical_context] "is_hard_macro == true"]
set_pg_strategy macro_con -macros $toplevel_hms -pattern {{name: hm_pattern} {nets: {VDD VSS}} }

########################################
# 6. STANDARD CELL RAILS
########################################
puts "RM-info : Creating Standard Cell PG Rails"

create_pg_std_cell_conn_pattern \
    std_cell_rail  \
    -layers {metal1} \
    -rail_width 0.06

set_pg_strategy rail_strat  -pg_region pg_mesh_region \
    -pattern {{name: std_cell_rail} {nets: VDD VSS} }

########################################
# 7. Compile PG
########################################
puts "RM-info : Compiling PG strategies"

compile_pg 

########################################
# 8. PG CHECKS
########################################
puts "RM-info : Running PG Checks"

check_pg_missing_vias
check_pg_drc -ignore_std_cells
check_pg_connectivity -check_std_cell_pins none

########################################
# 9. Save Block
########################################
puts "RM-info : Saving block after power planning"
save_block -hier -force -label CREATE_POWER
save_lib -all

puts "RM-info : Power Planning Completed Successfully"

####################################
# Timing estimation
####################################
estimate_timing
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.rpt     {report_timing -corner estimated_corner -mode [all_modes]}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor     {report_qor    -corner estimated_corner}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor.sum {report_qor    -summary}

save_block -hier -force   -label ${TIMING_ESTIMATION_LABEL_NAME}
save_lib -all


set path_dir [file normalize ${WORK_DIR_WRITE_DATA}]
set write_block_data_script ./write_block_data.tcl
source ${write_block_data_script}

####################################
# Place, CTS, Route
####################################
eval create_placement $CMD_OPTIONS
report_placement    -physical_hierarchy_violations all    -wirelength all -hard_macro_overlap    -verbose high > $REPORTS_DIR_PLACEMENT/report_placement.rpt
set_host_options -max_cores 8
remove_corners [get_corners estimated_corner]
set_app_options -name place.coarse.continue_on_missing_scandef -value true
place_opt
clock_opt
route_auto -max_detail_route_iterations 5
set FILLER_CELLS [get_object_name [sort_collection -descending [get_lib_cells NangateOpenCellLibrary/FILL*] area]]
create_stdcell_fillers -lib_cells $FILLER_CELLS

save_block -hier -force   -label post_route
save_lib -all

```

Final log  image of the design is as follows
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/12608b62-7b4a-4fa6-8147-e0bfdd978a2d" />

---

## Documentation and Reports

### Report Hierarchy

Generated reports follow a logical structure:

**Level 1: Design Status Summary**
- Overall status and top-level metrics

**Level 2: Tool-Specific Summaries**
- Placement density, routing completion
- Parasitic coverage statistics

**Level 3: Detailed Analysis**
- Path-by-path slack analysis
- Clock network structure
- Regional utilization details

**Level 4: Critical Analysis**
- Critical path deep-dive
- Optimization opportunities

### Key Files for Review

Important files for design review or reproduction:

1. **README.md** - Complete flow documentation
2. **icc2/scripts/icc2_common_setup.tcl** - Tool paths and configurations
3. **icc2/outputs/raven_wrapper.routed.def** - Final physical design
4. **icc2/outputs/raven_wrapper.post_route.v** - Post-route netlist
5. **star_rc/spef/raven_wrapper.spef** - Parasitic data
6. **primetime/reports/timing_summary.rpt** - Final timing status

---

## Future Enhancements

### Potential Improvements

**1. Timing Closure Enhancement**
- Timing margin improvement on critical paths
- Cell resizing and logic restructuring opportunities
- Target: Improved setup timing slack

**2. Power Analysis**
- Gate-level power analysis with PrimePower
- Multi-corner analysis across process corners
- Dynamic power reduction techniques

**3. Advanced Timing Features**
- Multi-corner and multi-mode STA
- Process corner analysis (SS, TT, FF)
- Temperature-aware timing analysis

**4. Manufacturing Verification**
- Scan chain insertion for test
- DFT enhancements
- LVS and physical verification

**5. Hierarchical Design Support**
- Hierarchical block implementation
- Sub-block integration
- Macro-based design methodology

**6. Design Space Exploration**
- Area vs. Timing trade-offs
- Power vs. Performance analysis
- Alternative routing strategies

---

## Conclusion

This backend flow implementation demonstrates a complete physical design methodology for complex digital ICs. Starting from synthesized netlists, the design progresses through floorplanning, power planning, placement, clock tree synthesis, routing, parasitic extraction, and timing analysis—achieving target frequency specifications.

The modular architecture, with clean handoffs between ICC2, Star-RC, and PrimeTime, provides a solid foundation for future iterations. Comprehensive documentation enables reproduction by other engineers.

While signoff-grade optimization has not been pursued, the design demonstrates end-to-end flow correctness and validates tool integration.

---
