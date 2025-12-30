#  Raven SoC PD - RTL to GDSII flow using Synopsys Tools
Reference Scripts
Use the following ICC2 standalone flow scripts as a learning reference:
```
https://github.com/kunalg123/icc2_workshop_collaterals/blob/master/standaloneFlow/top.tcl
```
---

## Design Specifications

| Parameter | Value |
|-----------|-------|
| **Die Size** | 3.588 mm × 5.188 mm |
| **Core Offset** | 0.2 mm (all sides) |
| **Core Area** | 3.388 mm × 4.988 mm |
| **Top-level Module** | raven_wrapper |
| **Technology** | Nangate 45nm |

---
Tools: Synopsys ICC2, Star-RC, PrimeTime
Scope: Placement → Routing → Extraction → STA (Flow Validation Task)
## Performance Target
•	Target Frequency: 100 MHz
•	Clock Period: 10 ns
Timing must be checked using post-route parasitics (SPEF).
## Flow to Be Implemented
Sequence:
ICC2 (Placement + Routing)
   ↓
Star-RC (SPEF Extraction)
   ↓
PrimeTime (Post-Route STA @ 100MHz)

### 1. Floorplanning Using ICC2 

A floorplan-only implementation of the raven_wrapper Processor using Synopsys ICC2, targeting fixed die dimensions of **3.588 mm × 5.188 mm** on SCL 180 nm technology with reserved IO bands around the core.

---

## 📋 Overview

This project corresponds to **Task 5: SoC Floorplanning Using ICC2**, with a strictly limited scope that stops after floorplan creation and geometry verification. The emphasis is on accurate die/core definition, IO ring reservation using hard placement blockages, and report-driven validation, without any placement, clock tree, routing, or power planning.

**Scope & Constraints:**

- ✓ Floorplan-only, no placement, CTS, routing, or IR/EM analysis
- ✓ No macros or memory hard IPs; raven memories are synthesized logic
- ✓ Synthesized netlist is imported only to provide design context and ports
- ✓ Verification is via reports and GUI visualization, not timing closure

---

## 🚀 Getting Started

### Prerequisites

Ensure the following environment inputs are available before running the Tcl flow:

- **Synopsys ICC2 2022.12** (or compatible) installation with valid license
- **SCL 180 nm** PDK reference NDM library (standard cells + tech data)
- **Pre-synthesized raven** Verilog netlist
- Linux shell with Tcl support for batch runs and scripting

### Running the Floorplan Flow

**Method 1 – Batch Mode**

```bash
cd scripts/
icc2 -64bit -f floorplan.tcl | tee floorplan.log
```

**Method 2 – Interactive ICC2 Session**

```tcl
icc2 -64bit
source scripts/floorplan.tcl
place_ports -self      ;# Optional: auto-distribute top ports
gui_show_man_page      ;# Optional: view floorplan in GUI
```

### Generated Artifacts

| Output | Purpose |
|--------|---------|
| `raven_fp_lib/` | ICC2 design library in NDM format |
| `reports/floorplan_report.txt` | Text summary of die/core bounds and ports |
| GUI floorplan view | Visual confirmation of geometry and IO bands |

---

## 📐 Floorplan Specification

### Die and Core Geometry

The floorplan is fully defined using absolute coordinates for repeatability across runs.

```
Die Extents : [0, 0] → [3588, 5188] µm
Core Extents: [200, 200] → [3388, 4988] µm
Core Margin : 200 µm (all four sides)
Total Area  : 18.606 mm²
```

**Initialization Command:**

```tcl
initialize_floorplan \
    -control_type die \
    -boundary {{0 0} {3588 5188}} \
    -core_offset {300 300 300 300}
```

This creates a rectangular die with a core inset by 300 µm on all sides, leaving a continuous peripheral band for IO and power structures.

**Why These Dimensions?**

- The die size (3.588 mm × 5.188 mm) represents the target silicon footprint negotiated with foundry rules and packaging constraints
- Core margin of 200 µm balances standard cell placement area with IO infrastructure needs in 180 nm technology
- Aspect ratio of ~1.44:1 (height:width) optimizes routing channel distribution between horizontal and vertical tracks

### IO Region Reservation with Hard Blockages

IO bands are reserved using **hard placement blockages**, ensuring no standard cells are placed where IO pads, ESD structures, and future power rings may exist.

```
┌─────────────────────────────────────┐
│       IO_TOP: 100 µm height         │
├─┬─────────────────────────────────┬─┤
│I│                                 │I│
│O│           CORE AREA             │O│
│_│      [200,200]→[3388,4988]      │_│ 
│L│                                 │R│
│E│                                 │I│
│F│                                 │G│
│T│                                 │H│
│ │                                 │T│
├─┴─────────────────────────────────┴─┤
│     IO_BOTTOM: 100 µm height        │
└─────────────────────────────────────┘
```

**Blockage Coordinate Definitions:**

| Region | Boundary (µm) | Size | Purpose |
|--------|---|---|---|
| Bottom | [0, 0] → [3588, 100] | Full width × 100 µm | Power delivery, ground ring, bottom pad row |
| Top | [0, 5088] → [3588, 5188] | Full width × 100 µm | Power delivery, ground ring, top pad row |
| Left | [0, 100] → [100, 5088] | 100 µm × core height | ESD clamps, level shifters, left pad row |
| Right | [3488, 100] → [3588, 5088] | 100 µm × core height | ESD clamps, level shifters, right pad row |

Each blockage is declared as `-type hard`, creating permanent no-placement zones that prevent standard cell placement while allowing future insertion of pad cells, power rings, and specialty circuits.

**Example Blockage Creation:**

```tcl
create_placement_blockage \
  -name IO_BOTTOM -type hard \
  -boundary {{0 0} {3588 100}}

create_placement_blockage \
  -name IO_TOP -type hard \
  -boundary {{0 5088} {3588 5188}}

create_placement_blockage \
  -name IO_LEFT -type hard \
  -boundary {{0 100} {100 5088}}

create_placement_blockage \
  -name IO_RIGHT -type hard \
  -boundary {{3488 100} {3588 5088}}
```

---
## 📊 floorplanning Using Synonpsys ICC2 

commands to access the Synopsys tools:
```csh
csh
source ~/tooliitgn
```


Go to the directory "~/icc2Workshop/standalone" and use this commands
- make sure the tcl scripts exist in the current directory

```csh
icc2_shell -f floorplan.tcl | tee floorplan.log
```
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/695bd875-0cf6-4ed1-953d-29f1dba559cc" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/f9c9cc13-a52b-406c-9455-f8406a1dca26" />

To see the visualizations of Floorplanned design:

```csh
iic2_shell> start_gui
```
### ERRORS
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/2e25daa1-146b-4318-b9c3-889849e98254" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/8074ca54-0a39-4489-bcaa-a11336e42a9a" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/9d8dd859-c336-4935-bc88-c15105fbe287" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/b96561c3-4438-4ed9-b1fd-db31f71e811b" />

The above visuals declares that the IO blocks are not properly placed inside the IO Pads area of the design

The few coordinates changes in the file "pads_contraints.tcl" solves the above problem but the ports are not placed as per the ports order but placed perfectly in the IO Pad area
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/270bc0ad-933f-462d-b509-ed6e369d7486" />

After making the changes in the respective file the design will look like:

## 📊 Port Placement & Visualization

### Automatic Port Distribution

After script execution, ports can be auto-placed for visualization:

```tcl
place_ports -self
```
<img width="1525" height="109" alt="image" src="https://github.com/user-attachments/assets/76ecb57f-8e28-479d-a7bd-81df494f59df" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/3c4c7c7f-be7f-4c7f-893d-60b999718d71" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/6c265ab1-ef16-4612-8336-8c3b12405275" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/07f8c5b3-abbe-48f1-8eef-1d1aaeaa689c" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/8acd1083-6ba3-46c0-80c2-708965917965" />

--
## 📊 DEF Creation
Commands to create .def file in the tcl command terminal in gui/shell

```csh
write _def raven_wrapper.floorplan.def
```
<img width="452" height="92" alt="image" src="https://github.com/user-attachments/assets/094b3ec8-6613-44c0-93a9-aa77dfaa295f" />
<img width="616" height="399" alt="image" src="https://github.com/user-attachments/assets/bd49d8ef-d559-47f1-a95d-4813a6259031" />

**What This Command Does:**

- Analyzes top-level port list from imported netlist
- Calculates perimeter distribution accounting for die geometry
- Places port instances automatically along die edges
- Respects IO region blockages to avoid conflicts
- Provides preliminary pinout for early validation

**When to Use:**

- During design review to show expected IO placement
- For congestion analysis to estimate routing demand near pads
- For package feasibility checks with electrical stakeholders
- As baseline before manual port refinement in later flows

### GUI Inspection Commands

Once floorplan is loaded in ICC2, use these commands for visualization:

```tcl
# Display interactive floorplan viewer
gui_show_man_page

# Query all ports and their locations
get_ports

# List blockage definitions and verify coverage
get_placement_blockages

# Zoom to full design extent
zoom_extents

# Show layer details (metal, via definitions)
gui_show_layer_info
```

**Expected Visualization:**

- ✓ Cyan die boundary outline (rectangular, no concavities)
- ✓ Blue core region rectangle (inset 200 µm on all sides)
- ✓ Gray shaded blockage areas (four IO bands around core)
- ✓ Port markers along die edges (red or green circles)
- ✓ Clear spacing between core and IO bands

---

## ✅ Verification Workflow

### Automated Checks in ICC2

Run these commands to validate correctness of floorplan constraints:

```tcl
# Check die size and core boundaries
get_floorplan -all

# Validate core bounds match initialization
get_core_bounds

# List and count all blockages
get_placement_blockages -all

# Verify port count matches netlist
llength [get_ports]

# Check for blockage overlaps or inconsistencies
report_placement_blockage -all
```

**Verification Script Example:**

```tcl
proc verify_floorplan {} {
    set die [get_floorplan -all]
    set core [get_core_bounds]
    set blockages [get_placement_blockages -all]
    set port_count [llength [get_ports]]
    
    puts "Die bounds: $die"
    puts "Core bounds: $core"
    puts "Blockage count: [llength $blockages]"
    puts "Port count: $port_count"
    
    # Add logic to check expected values
    if {[llength $blockages] != 4} {
        puts "ERROR: Expected 4 IO blockages!"
    }
}

verify_floorplan
```

### Visual Inspection Checklist

In the GUI, systematically verify:

**Geometry Checks:**
- [ ] Die boundary is rectangular with no concavities or irregular shapes
- [ ] Core region is perfectly inset 200 µm from all die edges
- [ ] All four IO blockages form continuous bands with no gaps
- [ ] Blockage bands do not extend beyond die boundary (no overflow)
- [ ] Left and right blockages meet top and bottom blockages cleanly

**IO Band Checks:**
- [ ] Bottom IO band spans full die width [0, 100]
- [ ] Top IO band spans full die width at [5088, 5188]
- [ ] Left IO band is 100 µm wide, runs full height
- [ ] Right IO band is 100 µm wide, runs full height
- [ ] IO bands leave core access clear in the center

**Port Checks:**
- [ ] Port count matches top-level netlist declarations
- [ ] Ports align to nearest IO edge (no floating interior ports)
- [ ] Port spacing is regular and respects blockage boundaries
- [ ] No ports overlap die boundary or extend outside

**Error Checks:**
- [ ] No error or warning messages in ICC2 transcript
- [ ] Design database saved without warnings
- [ ] Report file generated with expected content

### Report File Verification

Open `reports/floorplan_report.txt` and confirm it contains:

```text
===== FLOORPLAN GEOMETRY =====
Die Area  : 0 0 3588 5188  (microns)
Core Area : 200 200 3388 4988  (microns)
Die Size  : 3.588 mm × 5.188 mm
Total Area: 18.606 mm²

===== TOP LEVEL PORTS =====
[complete port listing]

===== PLACEMENT BLOCKAGES =====
[blockage definitions]
```
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/0a6c5b4d-1bd7-467b-a991-d245f248a454" />
<img width="812" height="600" alt="image" src="https://github.com/user-attachments/assets/6e5fc6c8-6b64-4be9-beb3-de3f49b8233b" />

This report serves as the official documentation artifact for the floorplan task and provides traceability for downstream design phases.

---





## 📁 Repository Structure

```
Task_Floorplan_ICC2/
│
├── scripts/
│   └── floorplan.tcl              ← Main ICC2 automation script
│
├── reports/
│   └── floorplan_report.txt       ← Generated floorplan summary
│
├── images/
│   ├── floorplan_screenshot_1.png ← Initial die/core setup
│   ├── floorplan_screenshot_2.png ← IO blockages visualization
│   └── floorplan_screenshot_3.png ← Port distribution view
│
└── README.md                       ← Project overview
```

This structure maintains clear separation between automation (scripts), generated artifacts (reports), visual evidence (images), and configuration data.

---
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/6ab02a94-8d0a-4c3b-9f4f-5fb538e8ed49" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/2d003b96-ea03-4c13-94c8-c618159e2064" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/9e3f085d-9999-4422-9522-bf034cddff53" />

## 🔄 Modifications from Reference Flow

The ICC2 workshop reference script (raven_wrapper) required significant changes:
- Paths changes to my local directory in various .tcl files like
    - iic2_common_setup.tcl
    - iic2_dp_setup.tcl
    - *parasitic.tcl

---

## 🛠️ Troubleshooting Guide

### Error: "Reference library not found"

```
Symptom: ICC2 exits with file-not-found error on REF_LIB
Cause:   REF_LIB path is incorrect, file doesn't exist, or permissions restricted
Fix:     1. Verify absolute path: echo $REF_LIB
         2. Check file exists: file exists /path/to/lib.ndm
         3. Check permissions: ls -l /path/to/lib.ndm
         4. Update REF_LIB variable to correct location
Example: set REF_LIB "/opt/foundry/scl180nm/lib.ndm"
```

Incorrect or missing reference libraries are a common setup issue when migrating ICC2 scripts across environments.

### Error: "Unresolved cell references in netlist"

```
Symptom: Warning messages about cells not found in libraries
Cause:   Netlist instantiates cells absent from reference library
Fix:     This is expected for floorplan-only scope where placement is skipped
         Optionally add -continue_on_error flag to suppress warnings:
         read_verilog -continue_on_error -top $DESIGN_NAME raven.v
```

At the floorplan stage, only geometry and port inventory matter; full library completeness is not required.

### Error: "Blockage boundaries invalid"

```
Symptom: ICC2 reports blockage creation failure
Cause:   Blockage coordinates extend outside die extents or overlap improperly
Fix:     Verify all blockage boundaries are within die [0,3588]×[0,5188]
         Check math for left/right overlap: 100 + 3488 = 3588 ✓
         Validate top/bottom overlap: 0 + 100 = 100, 5088 + 100 = 5188 ✓
Debug:   Print coordinates: puts "Checking: 3488 + 100 = [expr {3488 + 100}]"
```

ICC2 strictly enforces that all geometric primitives lie entirely within the defined floorplan boundary.

### Ports not visible in GUI

```
Symptom: GUI shows core and blockages but no port markers
Cause:   Ports exist but have no physical coordinate assignment
Fix:     Run automatic placement: place_ports -self
         Then refresh view: gui_show_man_page
         Or manually set port location: place_port port_name -location {x y edge}
Verify:  Check port assignment: get_ports -filter "is_placed == true"
```

Port placement is a separate step from port definition and may require explicit commands or GUI interaction.

### Script execution hangs or times out

```
Symptom: ICC2 process appears stuck or does not complete
Cause:   Waiting for interactive input, library locked, or filesystem issue
Fix:     1. Kill hanging process: pkill -9 icc2
         2. Remove stale locks: rm -f raven_fp_lib/.icv_lock
         3. Verify disk space: df -h (need >1GB free)
         4. Check file permissions: ls -la raven_fp_lib/
         5. Re-run with timeout: timeout 300 icc2 -64bit -f floorplan.tcl
Prevent: Use -no_gui flag in batch: icc2 -64bit -no_gui -f floorplan.tcl
```

Lock files, interactive prompts, and insufficient disk space are typical causes of stalled batch runs in ICC2.

---

## 📝 Design Rationale

### Why Floorplan-Only Scope?

**Separation of Concerns**

Floorplan quality strongly influences timing closure, congestion behavior, and power distribution. By isolating floorplanning in a dedicated task, the design team can:
- Explore multiple floorplan variants independently
- Defer detailed placement/routing decisions
- Establish clean geometric baseline for all downstream flows

**Design Reusability**

A well-constructed floorplan serves as:
- Foundation for multiple place-and-route attempts with different strategies
- Template for ECOs and incremental improvements
- Reference for physical design documentation and sign-off

**Learning Efficiency**

Focusing exclusively on geometry, IO rings, and blockages exposes core ICC2 concepts without the distraction of:
- Complex placement algorithms and convergence
- Clock tree synthesis and skew optimization
- Full routing with congestion management
- Power delivery network analysis

This scope is ideal for design engineers new to physical design who want to master fundamentals before tackling integrated flows.

**Resource Efficiency**

A floorplan-only flow:
- Executes in seconds (vs. hours for full P&R)
- Minimizes compute resource requirements
- Enables rapid iteration on die dimensions and IO strategy
- Reduces licensing overhead for tools and PDKs

### Memory Organization in raven

raven integrates **RAM128 and RAM256** structures as **synthesized logic** rather than as hard macro blocks. This design choice:

**Advantages:**
- Simplifies floorplanning (no macro placement logic needed)
- Allows placement algorithm full freedom for distributed memory logic
- Enables optimization for congestion hotspots
- Supports better utilization of available core area

**Trade-offs:**
- Slightly increased area vs. custom memory macros
- Reduced timing predictability (standard cells have longer delays)
- Higher power consumption compared to optimized memory compilers
- Less flexibility for ECO modifications to memory interfaces

**When to Use Distributed Logic vs. Macros:**
- Use macros: Large, high-density memory requirements (>100KB)
- Use distributed logic: Small memories (<16KB), high iteration rate, or area flexibility

### IO Ring in 180 nm Technology Context

In 180 nm SoCs, the IO ring operates at a higher voltage domain (typically 3.3 V) while the core logic runs at a lower voltage (typically 1.8 V or lower).

**Key Planning Considerations:**

- **Power Supply Separation:** IO ring needs independent power delivery (VDD_IO, VSS) isolated from core supply
- **Level Shifters:** Boundary between 3.3 V and 1.8 V domains requires level conversion cells to protect core transistors
- **ESD Protection:** IO pads require ESD clamp circuits (diodes, discharge paths) that need specific placement near pads
- **Ground Return:** Continuous ground plane with strategic vias from IO ring to core ground ensures low inductance

**Reserved Band Allocation:**

The 100 µm IO bands in this design accommodate:
- 40-50 µm: Pad cell itself (typically 70 µm × 70 µm pad frame in 180 nm)
- 30-40 µm: ESD clamp circuits and small decoupling capacitors
- 20-30 µm: Power and ground redistribution, level shifters
- Remaining: Routing corridors and margin for future optimizations

**Why 200 µm Core Margin?**

The 200 µm inset from die edge to core provides:
- Sufficient clearance for pad frame and peripheral structures
- Room for power rings and ground straps
- Buffer for foundry edge exclusion and manufacturing tolerance
- Space for future addition of analog blocks or special circuits

---

## 🎯 Floorplanning Best Practices

Even though this project stops at the floorplan stage, the following industry best practices are implicitly supported by the chosen constraints and recommendations for extending the flow:

### Aspect Ratio Optimization

**Principle:** Keep aspect ratio near 1:1 when possible to balance horizontal and vertical routing resources.

**For raven:**
- Current aspect ratio: 5.188 / 3.588 ≈ 1.44:1
- This is acceptable for a rectangular die; slightly wider dies are common in standard cells
- Wider horizontal aspect favors horizontal metal layers (M1, M3, M5 in 180 nm)

**Action Items:**
- If congestion appears along vertical edges, consider widening die horizontally
- If aspect ratio exceeds 2:1, evaluate core orientation and macro placement strategy

### Whitespace and Channel Planning

**Principle:** Leave sufficient whitespace and clear routing corridors to prevent congestion near IO and power structures.

**Recommendations:**
- Maintain 150-200 µm channels between IO bands and core boundary for power ring + routing
- Avoid placing high-connectivity cells (large multiplexers, decoders) near IO regions
- Reserve horizontal and vertical routing corridors for global signals

**Implementation:**
```tcl
# Add internal routing tracks
create_routing_guide -name routing_corridor_h \
  -boundary {{200 2500} {3388 2600}} \
  -layer M3
```

### Power Domain Partitioning

**Principle:** Plan partitions and domains early so the floorplan remains scalable to full SoC flows.

**Domains in raven:**
- Core domain: 1.8 V logic
- IO domain: 3.3 V IO, pads, ESD clamps
- Analog domain: Optional PLL, voltage reference (if present)

**Floorplan Implications:**
- Reserve separate supply pins and bonding pads for each domain
- Isolate supply and ground routing to minimize cross-coupling
- Plan level shifter placement at domain boundaries

### Clock Domain Planning

**Principle:** Identify clock domains and plan clock tree distribution early.

**For raven:**
- Main system clock (likely RISC-V SoC master clock)
- Optional IO clock domain (if async interfaces present)
- Test/scan clock (if DFT implemented)

**Floorplan Actions:**
- Identify clock source location (usually central core region)
- Plan primary clock buffer placement
- Reserve metal routing for clock tree distribution
- Avoid placing IO blockages in critical clock paths

---

## 📚 References and Further Reading

### Synopsys ICC2 Documentation

- IC Compiler II Design Planning User Guide (Synopsys official)
- IC Compiler II Floorplanning Best Practices (Synopsys whitepaper)
- IC Compiler II Multi-Level Physical Hierarchy (advanced topic)

### Physical Design Fundamentals

- VLSI Design and Verification Methodology (textbook)
- Floorplanning and placement concepts in modern IC design
- Power delivery and IO ring design in nanoscale technologies

### 180 nm Technology Specifics

- SCL 180 nm PDK Design Rules and Constraints
- Standard cell library characterization and timing
- IO cell specifications and ESD requirements

---

### Placement to Routing

### Changes made 
1. top.tcl file
2. given clock freq as 10ns in raven_wrapper.sdc
3. 

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/9f324fcd-c949-43a8-886d-129ad496a297" />

### ERRORS

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/33649f12-6d63-4d62-88e9-cfe07d484598" />


### SUCCESS
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/2f8ae26c-0489-488f-a5d3-a5a2c7bfbde0" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/b21d355b-eb02-4316-ad20-f363d1051887" />


<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/11ab5174-e20f-496b-a360-7d04b0029dc9" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/76962124-d160-4be3-8400-b5f508a8d8f9" />

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/ba73ebf7-0315-4d5a-8218-463dcd002432" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/bedf26af-70c5-44c2-986e-209b2d84f02f" />

<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/ba875fa5-2264-4958-b871-06c410efeab4" />
### REPORTS
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/dfa72b35-8703-49a7-899e-790e6e2ebca7" />
<img width="1600" height="1000" alt="image" src="https://github.com/user-attachments/assets/ef01ebde-c51b-4252-a5ea-ef8ea9c00361" />












