# IBERT Projects for testing Opsero FMCs

## Description

These projects can be used to test several Opsero FMCs in loopback using IBERT.

## Requirements

This project is designed for version 2024.1 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/opsero-fmc-ibert/tags "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2024.1
* One of the target platforms listed below

## Target designs

This repo contains several designs that target various supported development boards and their
FMC connectors. The table below lists the target design name, the number of ports supported by the design and 
the FMC connector on which to connect the mezzanine card. Some of the target designs
require a license to generate a bitstream with the AMD Xilinx tools.

<!-- updater start -->
### 10G designs

| Target board          | Target design        | Link speed | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------|-------------|-------------|-------|
| [VEK280 ES Rev-B]     | `vek280_es_revb_10g` | 10G        | 8x          | FMCP        | Enterprise |

### 16G designs

| Target board          | Target design        | Link speed | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------|-------------|-------------|-------|
| [VEK280 ES Rev-B]     | `vek280_es_revb_16g` | 16G        | 8x          | FMCP        | Enterprise |

### 32G designs

| Target board          | Target design        | Link speed | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------|-------------|-------------|-------|
| [VEK280 ES Rev-B]     | `vek280_es_revb_32g` | 32G        | 8x          | FMCP        | Enterprise |

### GT Settings

The table below shows the GT selections and settings used to create these designs.
All designs use local fixed clock sources, ensuring independence from the FMC card being tested and
eliminating the need for software-based configuration.

| Target board          | Target part                       | FMC GT Lanes | GT Quad         | Ref Clk Source     | Ref Clk Freq (MHz) |
|-----------------------|-----------------------------------|--------------|-----------------|--------------------|--------------|
| [VEK280 ES Rev-B]     | `xcve2802-vsvh1760-2MP-e-S-es1`   | DP0-DP3      | `GTYP QUAD 205` | `GTYP REFCLK X1Y6` | 100        |
|                       |                                   | DP4-DP7      | `GTYP QUAD 206` | `GTYP REFCLK X1Y8` | 100        |

[VEK280 ES Rev-B]: https://www.xilinx.com/vek280
<!-- updater end -->

Notes:

1. The Vivado Edition column indicates which designs are supported by the Vivado *Standard* Edition, the
   FREE edition which can be used without a license. Vivado *Enterprise* Edition requires
   a license however a 30-day evaluation license is available from the AMD Xilinx Licensing site.

## Build instructions

Clone the repo:
```
git clone https://github.com/fpgadeveloper/opsero-fmc-ibert.git
```

Source Vivado tool:

```
source <path-to-vivado>/2024.1/settings64.sh
```

To build the IBERT project:

```
cd opsero-fmc-ibert/Vivado
make xsa TARGET=vek280_es_revb_10g
```

Replace the target label in these commands with the one corresponding to the target design of your
choice from the tables above.

## Contribute

We strongly encourage community contribution to these projects. Please make a pull request if you
would like to share your work:
* if you've spotted and fixed any issues
* if you've added designs for other target platforms

Thank you to everyone who supports us!

## About us

This project was developed by [Opsero Inc.](https://opsero.com "Opsero Inc."),
a tight-knit team of FPGA experts delivering FPGA products and design services to start-ups and tech companies. 
Follow our blog, [FPGA Developer](https://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.

