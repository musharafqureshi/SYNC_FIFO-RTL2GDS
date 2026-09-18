Synchronous FIFO – RTL to GDSII Flow (Cadence, DFT & EDT)
Description

This repository implements a parameterizable Synchronous FIFO (First-In-First-Out) design, taken through a complete RTL-to-GDSII ASIC flow using Cadence tools for synthesis, place & route, and timing signoff, along with Siemens Tessent for DFT scan insertion, EDT (Embedded Deterministic Test) compression, and ATPG. The project covers RTL design and verification, DFT/EDT insertion, logic synthesis, and physical implementation (floorplanning, placement, CTS, routing), producing a final tapeout-ready GDSII.

The goal of this repo is to demonstrate an end-to-end, industry-style digital design flow on a small, well-understood block — a synchronous FIFO — making it a useful reference/learning project for RTL2GDS methodology, scan insertion, and ATPG-based test compression.

Key stages covered:

RTL design (Verilog/SystemVerilog) of a synchronous FIFO
Functional verification / testbench simulation
Logic synthesis (Cadence Genus)
DFT: scan chain insertion + EDT compression (Siemens Tessent)
ATPG pattern generation and fault coverage analysis (Siemens Tessent)
Physical design: floorplan, power planning, placement, CTS, routing (Cadence Innovus)
Static timing analysis (STA) and signoff checks (Cadence Tempus)
Final GDSII generation
Tools Used
Stage	Tool
RTL Simulation	Cadence Xcelium
Logic Synthesis	Cadence Genus
DFT / Scan / EDT	Siemens Tessent Shell
ATPG	Siemens Tessent Shell
Place & Route	Cadence Innovus
Static Timing Analysis	Cadence Tempus


The synchronous FIFO is parameterized for:

Data width (DATA_WIDTH)
FIFO depth (FIFO_DEPTH, power-of-2)
Full/Empty flag generation using Gray-code or binary pointer comparison
Single clock domain (synchronous read/write)
Ports
Signal	Direction	Description
clk	Input	System clock
rst_n	Input	Active-low reset
wr_en	Input	Write enable
rd_en	Input	Read enable
data_in	Input	Write data
data_out	Output	Read data
full	Output	FIFO full flag
empty	Output	FIFO empty flag
DFT & EDT Methodology (Siemens Tessent)
Scan Insertion: All flip-flops in the design are converted to scan flip-flops and stitched into scan chains using Tessent Shell, generating a DFT-ready gate-level netlist.
EDT (Embedded Deterministic Test): An EDT controller (decompressor/compactor) is inserted between the scan chains and the tester channels via Tessent to reduce test data volume and test time while maintaining high fault coverage.
ATPG: Test patterns are generated in Tessent Shell targeting stuck-at (and optionally transition) fault models, with fault coverage reports generated per pattern set.
Scan chain reordering and DFT rule checks (DRC) are run in Tessent prior to pattern generation to ensure a clean, testable netlist.
Flow Execution Order
rtl/ — Write and simulate RTL (tb/)
synthesis/ — Synthesize RTL to gate-level netlist (Genus)
dft/ — Insert scan chains + EDT logic, run ATPG (Tessent Shell)
pnr/ — Floorplan → Power Plan → Place → CTS → Route (Innovus)
sta/ — Timing signoff (Tempus)
gds/ — Final GDSII streamout
