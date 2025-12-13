# 🚀 RISC-V SoC Tapeout CARAVEL SCL180 

<div align="center">

[![RISC-V](https://img.shields.io/badge/RISC--V-SoC%20Implementation-2E86AB?style=for-the-badge&logo=riscv&logoColor=white)](https://riscv.org/)  
[![Caravel](https://img.shields.io/badge/Caravel-SoC%20Design-FF6B35?style=for-the-badge)](https://caravel-harness.readthedocs.io/)  
[![SCL180](https://img.shields.io/badge/SCL180-PDK-28A745?style=for-the-badge)]()  
[![Phase](https://img.shields.io/badge/Phase-2-9B59B6?style=for-the-badge)]()



**Exploring open-source silicon, one RTL module at a time.**


<img width="1280" height="720" alt="main" src="https://github.com/user-attachments/assets/d4c8dff6-cfe9-4524-be8e-63fd8507e726" />


**Designs of Caravel.**

<img width="383" height="630" alt="image" src="https://github.com/user-attachments/assets/f5113cf8-97e7-4690-9f81-652a516fb9b4" />

<img width="323" height="615" alt="image" src="https://github.com/user-attachments/assets/1ecb73e1-9fd0-4f9b-8c5b-9f304d967256" />



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
