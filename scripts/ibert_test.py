# Opsero Electronic Design Inc. (C) 2025
#
# IBERT link bring-up and eye-scan runner for the opsero-fmc-ibert reference designs.
#
# Usage:
#   vitis -s scripts/ibert_test.py <target>
#
# Example:
#   vitis -s scripts/ibert_test.py vck190_fmcp1_op120_28g
#
# What it does:
#   1. Reads config/data.json to learn the target board/part and IBERT params.
#   2. Programs the Vivado-generated PDI over JTAG using the xsdb Python API.
#   3. For designs that include a Vitis app (baremetal=true), downloads and
#      runs the ELF first so the on-board redrivers get initialised.
#   4. Closes the xsdb session to release the JTAG target.
#   5. Spawns `vivado -mode batch -source scripts/ibert_helper.tcl` which opens
#      the Hardware Manager, creates per-lane SIO links (TX+RX on the same GT,
#      external 1:1 loopback), applies GT pass-through properties, runs 2D eye
#      scans and writes one CSV per lane plus a link_status.json.
#   6. Collects the results into results/<target>/<YYYYMMDD-HHMMSS>/ and writes
#      a summary.csv and metadata.json.
#
# The script runs with the Python that ships inside Vitis, so no extra install
# is needed on Linux or Windows. Vivado and Vitis must both be on PATH before
# invoking (i.e. source settings64.sh / settings64.bat first).

import json
import os
import platform
import shutil
import subprocess
import sys
import time
from datetime import datetime


SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT   = os.path.normpath(os.path.join(SCRIPT_DIR, ".."))
CONFIG_JSON = os.path.join(REPO_ROOT, "config", "data.json")
VIVADO_DIR  = os.path.join(REPO_ROOT, "Vivado")
VITIS_DIR   = os.path.join(REPO_ROOT, "Vitis")
RESULTS_DIR = os.path.join(REPO_ROOT, "results")
HELPER_TCL  = os.path.join(SCRIPT_DIR, "ibert_helper.tcl")


def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def info(msg):
    print(msg, flush=True)


def banner(msg):
    bar = "=" * len(msg)
    print(f"\n{bar}\n{msg}\n{bar}", flush=True)


def load_data_json():
    if not os.path.isfile(CONFIG_JSON):
        die(f"data.json not found: {CONFIG_JSON}")
    with open(CONFIG_JSON, "r", encoding="utf-8") as f:
        return json.load(f)


def find_design(data, target):
    for d in data.get("designs", []):
        if d.get("label") == target:
            return d
    valid = [d.get("label") for d in data.get("designs", [])]
    die(f"Target '{target}' not found in data.json. Valid targets:\n  " + "\n  ".join(valid))


def find_boardgt(data, boardname):
    for b in data.get("boardgts", []):
        if b.get("boardname") == boardname:
            return b
    die(f"No boardgts entry for boardname '{boardname}' in data.json")


def merge_ibert_params(data, design):
    """Merge top-level ibert_params with any per-design override."""
    base = data.get("ibert_params", {}) or {}
    override = design.get("ibert_params", {}) or {}

    merged = {
        "tx_pattern": base.get("tx_pattern", "PRBS 31"),
        "rx_pattern": base.get("rx_pattern", "PRBS 31"),
        "settle_sec": base.get("settle_sec", 10),
        "scan": dict(base.get("scan", {}) or {}),
        "tx_properties": dict(base.get("tx_properties", {}) or {}),
        "rx_properties": dict(base.get("rx_properties", {}) or {}),
    }
    if "tx_pattern" in override: merged["tx_pattern"] = override["tx_pattern"]
    if "rx_pattern" in override: merged["rx_pattern"] = override["rx_pattern"]
    if "settle_sec" in override: merged["settle_sec"] = override["settle_sec"]
    merged["scan"].update(override.get("scan", {}) or {})
    merged["tx_properties"].update(override.get("tx_properties", {}) or {})
    merged["rx_properties"].update(override.get("rx_properties", {}) or {})

    merged["scan"].setdefault("horizontal_increment", "2")
    merged["scan"].setdefault("vertical_increment", "2")
    merged["scan"].setdefault("horizontal_range", "-0.500 UI to 0.500 UI")
    merged["scan"].setdefault("vertical_range", "100%")
    merged["scan"].setdefault("dwell_ber", "1e-6")
    return merged


def locate_pdi(target):
    bd_name = "versal_ibert"
    pdi = os.path.join(VIVADO_DIR, target, f"{target}.runs", "impl_1", f"{bd_name}_wrapper.pdi")
    if not os.path.isfile(pdi):
        die(f"PDI not found: {pdi}\nBuild the Vivado project first: "
            f"cd Vivado && make xsa TARGET={target}")
    return pdi


def locate_elf(target):
    app_name = "ibert_test"
    elf = os.path.join(VITIS_DIR, f"{target}_workspace", app_name, "build", f"{app_name}.elf")
    if not os.path.isfile(elf):
        die(f"Baremetal app configured but ELF not found: {elf}\n"
            f"Build the Vitis workspace first: cd Vitis && make workspace TARGET={target}")
    return elf


def program_and_boot(target, pdi, elf):
    """Connect to hw_server, program the PDI, optionally download and run the ELF."""
    try:
        import xsdb
    except ImportError:
        die("The xsdb Python module is not available. Run this script via:\n"
            "  vitis -s scripts/ibert_test.py <target>")

    banner("Connecting to hw_server")
    session = xsdb.start_debug_session()
    session.connect()

    # Wait for the Versal target to appear
    deadline = time.time() + 15
    last_err = None
    while time.time() < deadline:
        try:
            session.targets("-s", "-n", filter="name=~Versal*")
            break
        except Exception as e:
            last_err = e
            time.sleep(1)
    else:
        info("Available targets:")
        try:    session.targets()
        except Exception: pass
        session.dispose()
        die(f"No Versal JTAG target detected after 15s. Last error: {last_err}")

    banner(f"Programming PDI: {os.path.basename(pdi)}")
    session.configparams("force-mem-accesses", 1)
    session.targets("-s", "-n", filter="name=~Versal*").rst(type="system")
    time.sleep(3)
    session.targets("-s", "-n", filter="name=~PMC").device_program(file=pdi)

    if elf:
        banner(f"Downloading ELF: {os.path.basename(elf)}")
        a72 = session.targets("-s", "-n", filter="name=~*A72*#0")
        a72.rst(type="processor")
        a72.dow(file=elf)
        a72.con()
        session.configparams("force-mem-accesses", 0)
        info("App is running. Redrivers should now be initialised.")
        # Give the app a moment to finish its init sequence before we release JTAG.
        time.sleep(2)
    else:
        info("No baremetal app configured for this target; PDI programmed directly.")

    info("Closing xsdb session (releases JTAG to Vivado HW Manager)...")
    try:
        session.dispose()
    except Exception:
        pass
    # Give hw_server a moment to drop the xsdb connection cleanly.
    time.sleep(2)


def run_ibert_helper(target, design, boardgt, params, results_dir):
    """Spawn Vivado in batch mode and run the IBERT helper Tcl script."""
    # Write a temp context JSON that the Tcl helper reads.
    ctx = {
        "target": target,
        "num_lanes": len(design.get("lanes", [])),
        "part": boardgt.get("part", ""),
        "boardname": boardgt.get("boardname", ""),
        "tx_pattern": params["tx_pattern"],
        "rx_pattern": params["rx_pattern"],
        "settle_sec": params["settle_sec"],
        "scan": params["scan"],
        "tx_properties": params["tx_properties"],
        "rx_properties": params["rx_properties"],
    }
    ctx_path = os.path.join(results_dir, "run_context.json")
    with open(ctx_path, "w", encoding="utf-8") as f:
        json.dump(ctx, f, indent=2)

    log_path = os.path.join(results_dir, "vivado.log")
    jou_path = os.path.join(results_dir, "vivado.jou")

    vivado = shutil.which("vivado")
    if not vivado:
        die("`vivado` not found on PATH. Source Vivado/settings64.sh first.")

    cmd = [
        vivado, "-mode", "batch", "-notrace",
        "-source", HELPER_TCL,
        "-log", log_path,
        "-journal", jou_path,
        "-tclargs", ctx_path, results_dir,
    ]
    banner("Launching Vivado Hardware Manager")
    info(" ".join(cmd))

    rc = subprocess.call(cmd, cwd=results_dir)
    if rc != 0:
        die(f"Vivado helper returned non-zero exit code {rc}. See {log_path}")


def write_metadata(results_dir, target, design, boardgt, params, had_elf):
    vivado_ver = os.environ.get("XILINX_VIVADO", "")
    vitis_ver  = os.environ.get("XILINX_VITIS",  "")
    meta = {
        "target": target,
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "host": platform.node(),
        "os": f"{platform.system()} {platform.release()}",
        "boardname": design.get("boardname"),
        "part": boardgt.get("part"),
        "linkspeed_gbps": design.get("linkspeed"),
        "num_lanes": len(design.get("lanes", [])),
        "baremetal_app_used": had_elf,
        "xilinx_vivado": os.path.basename(os.path.dirname(vivado_ver)) if vivado_ver else "unknown",
        "xilinx_vitis":  os.path.basename(os.path.dirname(vitis_ver))  if vitis_ver  else "unknown",
        "ibert_params": params,
    }
    with open(os.path.join(results_dir, "metadata.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)


def write_summary_csv(results_dir):
    """Read link_status.json produced by the Tcl helper and write summary.csv."""
    status_path = os.path.join(results_dir, "link_status.json")
    summary_path = os.path.join(results_dir, "summary.csv")
    if not os.path.isfile(status_path):
        info("WARNING: link_status.json not produced by helper; skipping summary.csv")
        return

    with open(status_path, "r", encoding="utf-8") as f:
        status = json.load(f)
    lanes = status.get("lanes", [])
    if not lanes:
        info("WARNING: link_status.json has no lanes; summary.csv will be empty")

    cols = ["lane", "gt", "tx_pattern", "rx_pattern", "link_status",
            "prbs_locked", "prbs_ber", "prbs_errors",
            "open_area", "open_percentage", "horizontal_opening", "vertical_opening",
            "csv"]
    with open(summary_path, "w", encoding="utf-8") as f:
        f.write(",".join(cols) + "\n")
        for lane in lanes:
            row = []
            for c in cols:
                v = str(lane.get(c, ""))
                if "," in v: v = f'"{v}"'
                row.append(v)
            f.write(",".join(row) + "\n")
    info(f"Wrote summary: {summary_path}")


def main():
    argv = sys.argv[1:]
    skip_program = False
    filtered = []
    for a in argv:
        if a in ("-h", "--help"):
            print(__doc__); sys.exit(0)
        if a == "--skip-program":
            skip_program = True
            continue
        filtered.append(a)
    if len(filtered) != 1:
        print("Usage: vitis -s scripts/ibert_test.py [--skip-program] <target>")
        sys.exit(1)

    target = filtered[0]

    data    = load_data_json()
    design  = find_design(data, target)
    boardgt = find_boardgt(data, design.get("boardname"))
    params  = merge_ibert_params(data, design)

    pdi = locate_pdi(target)
    elf = locate_elf(target) if design.get("baremetal") else None

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    results_dir = os.path.join(RESULTS_DIR, target, timestamp)
    os.makedirs(results_dir, exist_ok=True)

    banner(f"IBERT test: {target}")
    info(f"  part        : {boardgt.get('part')}")
    info(f"  boardname   : {design.get('boardname')}")
    info(f"  linkspeed   : {design.get('linkspeed')} Gb/s")
    info(f"  lanes       : {len(design.get('lanes', []))}")
    info(f"  baremetal   : {bool(elf)}")
    info(f"  pdi         : {pdi}")
    if elf: info(f"  elf         : {elf}")
    info(f"  tx_pattern  : {params['tx_pattern']}")
    info(f"  rx_pattern  : {params['rx_pattern']}")
    info(f"  scan        : {params['scan']}")
    info(f"  results dir : {results_dir}")

    if skip_program:
        info("\n[--skip-program] Skipping PDI/ELF load; assuming device is already programmed.")
    else:
        program_and_boot(target, pdi, elf)
    run_ibert_helper(target, design, boardgt, params, results_dir)
    write_metadata(results_dir, target, design, boardgt, params, bool(elf))
    write_summary_csv(results_dir)

    banner("DONE")
    info(f"Results: {results_dir}")


if __name__ == "__main__":
    main()
