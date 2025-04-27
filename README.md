# IBERT Projects for testing Opsero FMCs

## Description

These projects can be used to test several Opsero FMCs in loopback using IBERT. We use these
projects internally for development and test purposes, but feel free to use them to build your
own similar test setups.

## Requirements

This project is designed for version 2024.1 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/opsero-fmc-ibert/tags "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2024.1
* One of the target platforms listed below

## FMC Cards

Currently this project supports the following Opsero products:

* [FPGA Drive FMC Gen4] (PN: OP063) with 2x [M.2 loopback] (PN: OP157)
* [M.2 M-key Stack FMC] (PN: OP073) with 2x [M.2 loopback] (PN: OP157)
* [Quad SFP28 FMC] (PN: OP081) with either active or passive loopbacks
* [MCIO PCIe Host FMC] (PN: OP100) with passive loopbacks
* [2x QSFP28 FMC] (PN: OP120) with either active or passive loopbacks

They can also be used with the following FMC products from other vendors:

* [FMC XM107 Loopback card]

## Target designs

This repo contains several designs that target various supported development boards and their
FMC connectors. The table below lists the target design name, the number of ports supported by the design and 
the FMC connector on which to connect the mezzanine card. Some of the target designs
require a license to generate a bitstream with the AMD Xilinx tools.

<!-- updater start -->
### 10G designs

| Target board          | Target FMCs          | Target design                | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------------------------|-------------|-------------|-------|
| [VEK280 ES Rev-B]     | OP063<br>OP073<br>XM107 | `vek280_es_revb_op063_10g`   | 8x          | FMCP        | Enterprise |
| [VEK280 ES Rev-B]     | OP081                | `vek280_es_revb_op081_10g`   | 8x          | FMCP        | Enterprise |
| [VEK280 ES Rev-B]     | OP120                | `vek280_es_revb_op120_10g`   | 8x          | FMCP        | Enterprise |

### 16G designs

| Target board          | Target FMCs          | Target design                | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------------------------|-------------|-------------|-------|
| [VEK280 ES Rev-B]     | OP063<br>OP073<br>XM107 | `vek280_es_revb_op063_16g`   | 8x          | FMCP        | Enterprise |
| [VEK280 ES Rev-B]     | OP100                | `vek280_es_revb_op100_16g`   | 8x          | FMCP        | Enterprise |

### 28G designs

| Target board          | Target FMCs          | Target design                | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------------------------|-------------|-------------|-------|
| [VEK280 ES Rev-B]     | OP063<br>OP073<br>XM107 | `vek280_es_revb_op063_28g`   | 8x          | FMCP        | Enterprise |
| [VEK280 ES Rev-B]     | OP081                | `vek280_es_revb_op081_28g`   | 8x          | FMCP        | Enterprise |
| [VEK280 ES Rev-B]     | OP120                | `vek280_es_revb_op120_28g`   | 8x          | FMCP        | Enterprise |

### 32G designs

| Target board          | Target FMCs          | Target design                | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------------------------|-------------|-------------|-------|
| [VEK280 ES Rev-B]     | OP063<br>OP073<br>XM107 | `vek280_es_revb_op063_32g`   | 8x          | FMCP        | Enterprise |
| [VEK280 ES Rev-B]     | OP100                | `vek280_es_revb_op100_32g`   | 8x          | FMCP        | Enterprise |

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

To build the 10G IBERT project for [VEK280 ES Rev-B] and OP081:

```
cd opsero-fmc-ibert/Vivado
make xsa TARGET=vek280_es_revb_op081_10g
```

Replace the target label in these commands with the one corresponding to the target design of your
choice from the tables above.

## MCIO PCIe Host FMC

The project for the [MCIO PCIe Host FMC] contains a bare-metal application that can be used to dynamically
adjust the equalizer settings of the transmit and receive redrivers ([TI DS320PR810]). To use the application,
you need to open up a UART terminal and follow the menu options.

There are two ways to launch the application:

1. Boot from SD card with a UART terminal open. Use Vivado Hardware Manager to interact with the IBERT core.
2. Boot from JTAG using Vitis with a UART terminal open. Then close Vitis and open Vivado Hardware Manager to 
   interact with the IBERT core. Note that if you leave Vitis open, it will not release the JTAG and you may 
   have issues in Vivado Hardware Manager.

The CTLE index is the main equalizer setting, providing high-frequency boost and low-frequency attenuation to 
equalize the frequency-dependent insertion loss of the PCB traces and cables being used. It's value can be set
from 0 to 19.

The flat gain is the overall data-path DC and AC gain. This can be set to -6dB, -4dB, -2dB, 0dB or 2dB. The 
default is 0dB and this is the recommended flat gain for most systems.

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

[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[M.2 M-key Stack FMC]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/
[M.2 loopback]: https://opsero.com/product/m-2-loopback-2230-mkey/
[FMC XM107 Loopback card]: https://docs.amd.com/v/u/en-US/ug539
[Quad SFP28 FMC]: https://ethernetfmc.com/docs/quad-sfp28-fmc/overview/
[MCIO PCIe Host FMC]: https://opsero.com/product/mcio-pcie-host-fmc
[TI DS320PR810]: https://www.ti.com/product/DS320PR810
[2x QSFP28 FMC]: https://opsero.com/product/2x-qsfp28-fmc
