

This folder contains the Verilog files for the implementation of Zynq Blade. The Zynq Blade files are only included here and the other Verilog files are the exisiting ones like the Hammerblade core, Zynq parrot shell, etc

PLEASE REFER to the HammerBlade Architectural BlockDiagram - Slide 26 -> https://drive.google.com/file/d/1CGmLDxd58JArar-dlGAAtPv25v5fbJd7/view?usp=sharing

---Hierarchical Flow

**mc_top.v - is the top module of Zynq Blade and contains the simulation instantiations

**mc_top_zynq.v - module contains the core wrapper and calls the zynq shell apart from performing the address translation and integrating the endpoint interface unit

**mc_wrapper - is the core Hammerblade module which contains the manycore array along with the V$ data interfacing

**mc_ps.cpp - This is a basic code to test the functionality of the ZynqBlade architecture ( Will be UPDATED to include all the required tests)
