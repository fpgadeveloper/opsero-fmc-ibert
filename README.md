# IBERT Projects for testing Opsero FMCs

## Description

These projects can be used to test several Opsero FMCs in loopback using IBERT. We use these
projects internally for development and test purposes, but feel free to use them to build your
own similar test setups.

## Requirements

This project is designed for version 2025.2 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/opsero-fmc-ibert/tags "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2025.2
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
| [VEK280]              | OP063<br>OP073<br>XM107 | `vek280_op063_10g`           | 8x          | FMCP        | Enterprise |
| [VEK280]              | OP081                | `vek280_op081_10g`           | 8x          | FMCP        | Enterprise |
| [VEK280]              | OP120                | `vek280_op120_10g`           | 8x          | FMCP        | Enterprise |
| [VCK190]              | OP063<br>OP073<br>XM107 | `vck190_fmcp1_op063_10g`     | 8x          | FMCP1       | Enterprise |
| [VCK190]              | OP081                | `vck190_fmcp1_op081_10g`     | 8x          | FMCP1       | Enterprise |
| [VCK190]              | OP120                | `vck190_fmcp1_op120_10g`     | 8x          | FMCP1       | Enterprise |

### 16G designs

| Target board          | Target FMCs          | Target design                | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------------------------|-------------|-------------|-------|
| [VEK280]              | OP063<br>OP073<br>XM107 | `vek280_op063_16g`           | 8x          | FMCP        | Enterprise |
| [VCK190]              | OP063<br>OP073<br>XM107 | `vck190_fmcp1_op063_16g`     | 8x          | FMCP1       | Enterprise |
| [VCK190]              | OP103                | `vck190_fmcp1_op103_16g`     | 8x          | FMCP1       | Enterprise |

### 28G designs

| Target board          | Target FMCs          | Target design                | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------------------------|-------------|-------------|-------|
| [VEK280]              | OP063<br>OP073<br>XM107 | `vek280_op063_28g`           | 8x          | FMCP        | Enterprise |
| [VEK280]              | OP081                | `vek280_op081_28g`           | 8x          | FMCP        | Enterprise |
| [VEK280]              | OP120                | `vek280_op120_28g`           | 8x          | FMCP        | Enterprise |
| [VCK190]              | OP063<br>OP073<br>XM107 | `vck190_fmcp1_op063_28g`     | 8x          | FMCP1       | Enterprise |
| [VCK190]              | OP081                | `vck190_fmcp1_op081_28g`     | 8x          | FMCP1       | Enterprise |
| [VCK190]              | OP103                | `vck190_fmcp1_op103_28g`     | 8x          | FMCP1       | Enterprise |
| [VCK190]              | OP120                | `vck190_fmcp1_op120_28g`     | 8x          | FMCP1       | Enterprise |

### 32G designs

| Target board          | Target FMCs          | Target design                | GT lanes    | FMC Slot    | Vivado<br> Edition |
|-----------------------|----------------------|------------------------------|-------------|-------------|-------|
| [VEK280]              | OP063<br>OP073<br>XM107 | `vek280_op063_32g`           | 8x          | FMCP        | Enterprise |

### GT Settings

The table below shows the GT selections and settings used to create these designs.
All designs use local fixed clock sources, ensuring independence from the FMC card being tested and
eliminating the need for software-based configuration.

| Target board          | Target part                       | FMC GT Lanes | GT Quad         | Ref Clk Source     | Ref Clk Freq (MHz) |
|-----------------------|-----------------------------------|--------------|-----------------|--------------------|--------------|
| [VEK280]              | `xcve2802-vsvh1760-2MP-e-S`       | DP0-DP3      | `GTYP QUAD 205` | `GTYP REFCLK X1Y6` | 100        |
|                       |                                   | DP4-DP7      | `GTYP QUAD 206` | `GTYP REFCLK X1Y8` | 100        |
| [VCK190]              | `xcvc1902-vsva2197-2MP-e-S`       | DP0-DP3      | `GTY QUAD 201`  | `GTY REFCLK X1Y2`  | 100        |
|                       |                                   | DP4-DP7      | `GTY QUAD 202`  | `GTY QUAD 201`     | 100        |

[VEK280]: https://www.xilinx.com/vek280
[VCK190]: https://www.xilinx.com/vck190
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
source <path-to-xilinx-tools>/2025.2/Vivado/settings64.sh
```

To build the 10G IBERT project for [VEK280 ES Rev-B] and OP081:

```
cd opsero-fmc-ibert/Vivado
make xsa TARGET=vek280_es_revb_op081_10g
```

Replace the target label in these commands with the one corresponding to the target design of your
choice from the tables above.

## Automated IBERT test script

The `scripts/ibert_test.py` script automates the full IBERT test flow for any of the target
designs listed above. Given a target name it will:

1. Program the target's PDI over JTAG.
2. If the design has a Vitis bare-metal application (OP100, OP103), download and run the
   ELF first so that the on-board redrivers are initialised before the link is characterised.
3. Open Vivado Hardware Manager, create one SIO link per GT lane (TX and RX on the same
   channel, relying on the external loopback), set the configured PRBS pattern, reset the
   links and PRBS counters, then run a 2D full-eye scan on every lane.
4. Write a per-lane eye-scan CSV, a `summary.csv`, a `link_status.json` and a
   `metadata.json` into `results/<target>/<YYYYMMDD-HHMMSS>/`.

The script runs under the Python that ships with Vitis, so **no separate Python installation
is required** on Linux or Windows — only the Vivado and Vitis tools need to be on `PATH`.

### Hardware prerequisite: install the loopbacks

**Before running the script, the loopback hardware must be installed on the FMC.** Each lane
of the design is tested by looping the TX of a given channel back to the RX of the *same*
channel. The exact loopback device differs between products but the intent is identical:

* **OP063 / OP073:** 2x [M.2 loopback] (PN: OP157) — one per M.2 slot
* **OP081:** active or passive SFP28 loopback modules
* **OP100 / OP103:** passive MCIO loopback connectors
* **OP120:** 2x QSFP28 loopback modules — one per QSFP28 cage
* **XM107:** built-in loopback on the card itself

The script does not verify that loopbacks are in place. If you run it without them, the
PRBS checker will report "Unlocked" and the eye scans will show a closed eye.

### Running the script on Linux

```
source <path-to-xilinx-tools>/2025.2/Vivado/settings64.sh
source <path-to-xilinx-tools>/2025.2/Vitis/settings64.sh
cd opsero-fmc-ibert
vitis -s scripts/ibert_test.py vck190_fmcp1_op120_28g
```

### Running the script on Windows

Open a regular Command Prompt and source the tool settings batch files, then launch
the script the same way:

```
call C:\Xilinx\2025.2\Vivado\settings64.bat
call C:\Xilinx\2025.2\Vitis\settings64.bat
cd opsero-fmc-ibert
vitis -s scripts\ibert_test.py vck190_fmcp1_op120_28g
```

Replace `vck190_fmcp1_op120_28g` with the target label of your choice from the tables above.
The Vivado project and (if applicable) the Vitis workspace must have been built for the
selected target before running the script — see [Build instructions](#build-instructions).

### Output

After the run completes, the results directory will contain:

```
results/vck190_fmcp1_op120_28g/20260415-143718/
├── summary.csv         per-lane PRBS status + eye-scan open area / percentages
├── lane_00.csv         raw Vivado eye-scan CSV for lane 0 (re-openable in HW Manager)
├── lane_01.csv
├── ... (lanes 2..7)
├── link_status.json    structured per-lane status (same data as summary.csv)
├── metadata.json       target, timestamp, tool versions, IBERT params used
├── run_context.json    parameters handed to the Vivado Tcl helper
└── vivado.log          Vivado batch log
```

The `lane_NN.csv` files can be re-opened in Vivado Hardware Manager for visual inspection,
or rendered to PNGs using the `scan_to_png.py` converter described below.

### Tuning scan parameters

The script reads its scan configuration from `config/data.json` under the top-level
`ibert_params` key:

```json
"ibert_params": {
  "tx_pattern": "PRBS 31",
  "rx_pattern": "PRBS 31",
  "settle_sec": 10,
  "scan": {
    "horizontal_increment": "4",
    "vertical_increment": "4",
    "horizontal_range": "-0.500 UI to 0.500 UI",
    "vertical_range": "100%",
    "dwell_ber": "1e-6"
  },
  "tx_properties": {},
  "rx_properties": {}
}
```

* `tx_pattern` / `rx_pattern` — valid values: `User Design`, `PRBS Disabled`,
  `PRBS 7`, `PRBS 9`, `PRBS 15`, `PRBS 23`, `PRBS 31`, `Configurable data pattern`,
  `Square wave (2 * UI)`, `Square wave (Int data width * UI)`.
* `settle_sec` — how long to wait after setting the patterns before reading the PRBS
  counters and running the eye scans. Needs to be long enough for the PRBS checker
  to finish its initial sync. The reported BER field is `errors / bits_received` and
  this ratio asymptotically approaches the real value the longer this window is;
  bumping `settle_sec` to 30 or 60 gives a much cleaner BER if the link is healthy.
* `horizontal_increment` / `vertical_increment` — `"1"` (finest) through `"16"`
  (fastest). The default `"4"` gives roughly 2 seconds per lane at dwell BER `1e-6`.
* `horizontal_range` — one of `-0.500 UI to 0.500 UI`, `-0.400 UI to 0.400 UI`,
  `-0.300 UI to 0.300 UI`, `-0.200 UI to 0.200 UI`, `-0.100 UI to 0.100 UI`.
* `vertical_range` — `100%` through `10%` in 10% steps.
* `dwell_ber` — target BER for the sweep, one of `1e-5`, `1e-6`, ..., `1e-19`.
  Lower values are more thorough but significantly slower.
* `tx_properties` / `rx_properties` — pass-through dictionaries. Any key you add here
  is applied verbatim to every TX (or RX) SIO object on every lane. The script
  auto-resolves the per-channel prefix, so writing `"TX_DIFF_CTRL": "938 mV"` becomes
  `CH0_TX_DIFF_CTRL` on lane 0, `CH1_TX_DIFF_CTRL` on lane 1, and so on.

Any individual design entry under `"designs"` can override these with a nested
`ibert_params` block of its own for target-specific tuning.

#### Tunable TX / RX properties

The table below lists every writable enum property you can set via `tx_properties`
and `rx_properties` on the Versal GTY/GTYP serial I/O objects that these designs
expose. Use the short name (without the `CH?_` channel prefix) as the key in the
JSON — the script resolves the prefix per channel at set time. Values are enums;
if you pass an invalid value Vivado rejects the write and the script prints a
warning for that lane.

**TX properties** (apply to all 8 TX channels via `tx_properties`):

| Property | Valid values |
|---|---|
| `TX_DATA_WIDTH` | `Default`, `16 bits`, `20 bits`, `32 bits`, `40 bits`, `64 bits`, `80 bits`, `128 bits`, `160 bits` |
| `TX_DIFF_CTRL` | `User Design`, `223 mV`, `246 mV`, `269 mV`, `291 mV`, `314 mV`, `338 mV`, `361 mV`, `384 mV`, `408 mV`, `431 mV`, `455 mV`, `478 mV`, `502 mV`, `528 mV`, `552 mV`, `574 mV`, `597 mV`, `622 mV`, `644 mV`, `667 mV`, `691 mV`, `716 mV`, `732 mV`, `756 mV`, `780 mV`, `804 mV`, `827 mV`, `851 mV`, `873 mV`, `895 mV`, `918 mV`, `938 mV` |
| `TX_ERROR_INJECTION.MODE` | `Level`, `Edge` |
| `TX_INT_DATA_WIDTH` | `16 bits`, `32 bits`, `64 bits` |
| `TX_PATTERN` | `User Design`, `PRBS Disabled`, `PRBS 7`, `PRBS 9`, `PRBS 15`, `PRBS 23`, `PRBS 31`, `Configurable data pattern`, `Square wave (2 * UI)`, `Square wave (Int data width * UI)` — use the top-level `tx_pattern` field instead of setting this here |
| `TX_PLL_TYPE` | `RPLL0`, `LCPLL0`, `RPLL0 (PI bypassed)`, `LCPLL0 (PI bypassed)` |
| `TX_POLARITY` | `User Design`, `Not Inverted`, `Inverted` |
| `TX_POST_CURSOR` | `User Design`, `0 dB`, `0.21 dB`, `0.29 dB`, `0.77 dB`, `1.27 dB`, `1.81 dB`, `2.38 dB`, `3.01 dB`, `3.63 dB`, `4.35 dB`, `5.24 dB`, `6.16 dB`, `7.19 dB`, `8.31 dB`, `9.65 dB`, `11.20 dB`, `13.10 dB`, `15.40 dB`, `18.80 dB` |
| `TX_PRE_CURSOR` | `User Design`, `0 dB`, `0.60 dB`, `1.03 dB`, `1.50 dB`, `2.00 dB`, `2.53 dB`, `3.11 dB`, `3.73 dB`, `4.40 dB` |

**RX properties** (apply to all 8 RX channels via `rx_properties`):

| Property | Valid values |
|---|---|
| `LOOPBACK` | `User Design`, `None`, `Near-End PCS`, `Far-End PCS`, `Near-End PMA`, `Far-End PMA` |
| `RX_COMMON_MODE` | `AVTT`, `Floating`, `Programmable` |
| `RX_DATA_WIDTH` | `Default`, `16 bits`, `20 bits`, `32 bits`, `40 bits`, `64 bits`, `80 bits`, `128 bits`, `160 bits` |
| `RX_DFE_ENABLED` | `Yes`, `No` |
| `RX_INT_DATA_WIDTH` | `16 bits`, `32 bits`, `64 bits` |
| `RX_PATTERN` | `User Design`, `PRBS Disabled`, `PRBS 7`, `PRBS 9`, `PRBS 15`, `PRBS 23`, `PRBS 31` — use the top-level `rx_pattern` field instead of setting this here |
| `RX_PLL_TYPE` | `RPLL0`, `LCPLL0` |
| `RX_POLARITY` | `User Design`, `Not Inverted`, `Inverted` |
| `RX_TERMINATION_VOLTAGE` | `300mv`, `350mv`, `400mv`, `450mv`, `500mv`, `550mv`, `600mv`, `650mv`, `700mv`, `750mv`, `800mv`, `850mv`, `900mv`, `950mv`, `1000mv`, `1100mv` |

The `*_CFG*` and `*_DBG_SIG_*` properties on the TX/RX objects (not shown) are
raw register-level overrides for advanced users; they take hex strings like
`0xABCD` and bypass the enum system. If you need them, run `report_property`
on a TX or RX object in Vivado's Tcl console to see their current values, and
paste the property name verbatim (e.g. `"CH0_TX_DRV_CFG0": "0x1234"`) — for these
the script will not auto-resolve the per-channel prefix, so you would have to
apply them per target rather than via the generic pass-through dictionary.

#### Example: maximum TX swing with moderate equalisation

Here's a worked example of an `ibert_params` block that sets the TX output to
the largest diff swing, applies a moderate amount of pre/post-cursor EQ, inverts
RX polarity (for a board where the differential pair is swapped), and bumps the
RX termination voltage:

```json
"ibert_params": {
  "tx_pattern": "PRBS 31",
  "rx_pattern": "PRBS 31",
  "settle_sec": 30,
  "scan": {
    "horizontal_increment": "4",
    "vertical_increment": "4",
    "horizontal_range": "-0.500 UI to 0.500 UI",
    "vertical_range": "100%",
    "dwell_ber": "1e-6"
  },
  "tx_properties": {
    "TX_DIFF_CTRL":  "938 mV",
    "TX_PRE_CURSOR":  "1.50 dB",
    "TX_POST_CURSOR": "3.01 dB",
    "TX_POLARITY":    "Not Inverted"
  },
  "rx_properties": {
    "RX_POLARITY":            "Inverted",
    "RX_TERMINATION_VOLTAGE": "500mv",
    "RX_COMMON_MODE":         "AVTT",
    "RX_DFE_ENABLED":         "Yes",
    "LOOPBACK":               "None"
  }
}
```

## Eye-diagram post-processing (CSV to PNG)

The `scripts/scan_to_png.py` script renders the Vivado eye-scan CSVs produced by the test
script into PNG eye diagrams — useful for sharing results or reviewing several lanes at
once without opening Vivado Hardware Manager.

### Prerequisites

Unlike `ibert_test.py`, this script runs under a standalone Python interpreter and needs
`matplotlib` and `numpy` to be installed. Any Python 3.8 or newer is fine.

* **Ubuntu / Debian:** `sudo apt install python3-matplotlib python3-numpy`
* **Fedora / RHEL:** `sudo dnf install python3-matplotlib python3-numpy`
* **Windows (or any venv):** `pip install matplotlib numpy`

### Running the converter

Point the script at a results directory to render every `lane_*.csv` inside it:

```
python3 scripts/scan_to_png.py results/vck190_fmcp1_op120_28g/20260415-143718
```

Or pass a single CSV to render just that one file:

```
python3 scripts/scan_to_png.py results/vck190_fmcp1_op120_28g/20260415-143718/lane_00.csv
```

Each PNG is written next to its CSV with the same basename — `lane_00.csv` becomes
`lane_00.png`.

### How it works

Vivado's 2D full-eye CSV is laid out like this:

1. A metadata preamble (`Open Area`, `Horizontal Range`, `Dwell BER`, etc.) as `key,value` pairs.
2. A `Scan Start` marker line.
3. A header row with the internal horizontal code values (e.g. `-32, -30, ..., 30, 32`).
4. Data rows of the form `<vertical_code>, <BER>, <BER>, ..., <BER>`.

The parser walks the file, collects the metadata, finds the `Scan Start` marker, reads the
header and the BER grid, then linearly rescales the internal horizontal codes onto unit
intervals using the `Horizontal Range` value from the metadata. The result is that the
rendered plot's x-axis always reads `-0.5 UI` to `+0.5 UI` (or whatever range was configured),
regardless of the underlying sample count. The BER is drawn on a log color scale so the eye
opening appears as the dark diamond in the centre of the plot. Key metadata — open area,
horizontal/vertical open percentage, dwell BER, scan name and the scan ranges — are shown
as subtitle and footer text on each PNG.

## MCIO PCIe FMC

The project for the [MCIO PCIe FMC] contains a bare-metal application that can be used to dynamically
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
[MCIO PCIe FMC]: https://opsero.com/product/mcio-pcie-fmc
[TI DS320PR810]: https://www.ti.com/product/DS320PR810
[2x QSFP28 FMC]: https://opsero.com/product/2x-qsfp28-fmc
