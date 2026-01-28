# 🧠 RISC-V RV32I 5-Stage Pipelined CPU  
**RTL to GDSII Implementation**

## 📌 Overview
This repository contains the complete **RTL design and verification** of a **5-stage pipelined RISC-V RV32I CPU**, developed to take the design **from RTL all the way to GDSII**.

The CPU follows the standard **IF–ID–EX–MEM–WB** pipeline architecture and includes **hazard handling**, **forwarding**, and **control logic** required for correct instruction execution.

This project is intended for:
- Learning and demonstrating **processor microarchitecture**
- Practicing **RTL design best practices**
- Preparing for **ASIC RTL-to-GDSII flow**
- FPGA prototyping and functional verification

---

## 🏗️ Architecture Overview

### 🔹 Pipeline Stages
1. **Instruction Fetch (IF)**  
   - Program Counter (PC)  
   - Instruction memory access

2. **Instruction Decode (ID)**  
   - Register file read  
   - Immediate generation  
   - Main control decoding

3. **Execute (EX)**  
   - ALU operations  
   - Branch decision logic  
   - Forwarding logic  
   - PC source resolution

4. **Memory Access (MEM)**  
   - Data memory read/write  
   - Store and load handling

5. **Write Back (WB)**  
   - Writes result back to register file

---

## ⚙️ Supported ISA
- **RISC-V RV32I Base Integer Instruction Set**

Includes:
- Arithmetic & Logical: `add`, `addi`, `sub`, `and`, `or`, etc.
- Immediate instructions
- Load/Store: `lw`, `sw`
- Control flow: `beq`, `bne`, `jal`, `jalr`
- Upper immediates: `lui`, `auipc`

---

## 🚦 Hazard Handling
The design includes a dedicated **Hazard Unit** to ensure correctness in a pipelined environment.

### ✔ Data Hazards
- **Forwarding** from:
  - EX/MEM → EX
  - MEM/WB → EX
- **Load-use stall** insertion when forwarding is insufficient

### ✔ Control Hazards
- Branch and jump resolution in Execute stage
- **Pipeline flush** on taken branches and jumps

### ✔ Structural Hazards
- Avoided by design separation of instruction and data memory

---

## 🧩 Module Description

### 🔹 Top-Level
- `t1c_riscv_cpu.v`  
  Top-level integration module connecting CPU, instruction memory, and data memory.

- `riscv_cpu.v`  
  Core pipelined CPU module integrating controller, datapath, and hazard unit.

### 🔹 Datapath & Control
- `datapath.v` – Implements the full 5-stage pipeline  
- `controller.v` – Main control logic  
- `main_decoder.v` – Opcode decoding  
- `alu_decoder.v` – ALU control decoding  
- `controller_branch_logic.v` – Branch condition evaluation

### 🔹 Hazard & Pipeline Control
- `hazard_unit.v` – Stall, flush, and forwarding logic  
- `pipeline_funct3_tracker.v` – Tracks instruction funct3 across pipeline

### 🔹 Basic Building Blocks
- `alu.v` – Arithmetic Logic Unit  
- `reg_file.v` – 32×32 register file  
- `imm_extend.v` – Immediate generation  
- `instr_mem.v` – Instruction memory  
- `data_mem.v` – Data memory  
- `adder.v`, `mux2.v`, `mux3.v`, `mux4.v`  
- `reset_ff.v` – Resettable flip-flop

---

## 🧪 Verification
- Self-written **Verilog testbenches**  
- Instruction execution verified using `.hex` programs  
- Waveform-based validation in **Vivado Simulator**

### Instruction memory test files:
Instructions/
├── rv32i_book.hex
├── rv32i_test.hex
├── rv32i_test_2.hex


---

## 🧬 RTL-to-GDSII Flow (Planned / In-Progress)

This project is structured to support a full **ASIC flow**, including:

1. RTL design & simulation ✅  
2. Linting & synthesis (Vivado / Yosys)  
3. Technology mapping  
4. Floorplanning  
5. Placement & routing  
6. DRC / LVS  
7. **Final GDSII generation**

(Target PDK: Open-source Sky130 or equivalent)

---

## 🛠️ Tools Used
- **Vivado** – RTL simulation and FPGA support  
- **Git & GitHub** – Version control  
- **Verilog HDL**  
- (Planned) **Yosys**, **OpenROAD**, **OpenLane**

---

## 📁 Repository Structure
├── rtl/ # RTL source files
├── simulation/ # Testbenches
├── Instructions/ # Instruction memory hex files
├── .gitignore
└── README.md


---

## 🎯 Future Enhancements
- Full RV32IM support  
- CSR implementation  
- Cache integration  
- Formal verification  
- FPGA deployment  
- Timing-aware synthesis reports  
- Complete ASIC sign-off

---

## 👤 Author
**Anuj Loyare**  
B.Tech ENTC | VLSI & Computer Architecture Enthusiast  
Aspiring Semiconductor & CPU Design Engineer  

🔗 GitHub: [AnujLoyare](https://github.com/AnujLoyare)

---

## ⭐ Acknowledgements
- RISC-V ISA Specification  
- Standard pipeline architecture references  
- Open-source VLSI community
