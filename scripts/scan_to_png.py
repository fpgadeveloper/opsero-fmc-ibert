#!/usr/bin/env python3
# Opsero Electronic Design Inc. (C) 2025
#
# Render Vivado eye-scan CSV files into PNG eye diagrams.
#
# Usage:
#   python3 scripts/scan_to_png.py <results_dir>
#   python3 scripts/scan_to_png.py <lane_NN.csv>
#
# If a directory is given, every lane_*.csv inside it is rendered.
# If a CSV is given, only that file is rendered.
# PNGs are written alongside each CSV with the same basename (.png).
#
# Dependencies (user-installed, NOT bundled with Vitis):
#   - Python 3.8+
#   - matplotlib, numpy
#
# On Ubuntu:
#   sudo apt install python3-matplotlib python3-numpy
# or (inside a venv):
#   pip install matplotlib numpy
#
# On Windows:
#   pip install matplotlib numpy
#
# Vivado's 2D eye-scan CSV format:
#   - First lines are "# key,value" metadata (horizontal range, units, etc.).
#   - A "Scan Start" marker precedes the data matrix.
#   - The data matrix has voltage offsets (V) in the first column and time
#     offsets (UI) in the header row. Each cell is a BER value (float).
#
# This script is format-tolerant: it scans for the first numeric row+column
# header it can find and treats everything else as the BER grid.

import argparse
import glob
import os
import re
import sys

try:
    import numpy as np
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.colors import LogNorm
except ImportError as e:
    print("ERROR: matplotlib / numpy not available:", e, file=sys.stderr)
    print("Install with: pip install matplotlib numpy  (or apt install python3-matplotlib python3-numpy)",
          file=sys.stderr)
    sys.exit(1)


def parse_scan_csv(path):
    """Parse a Vivado eye-scan CSV into (x_ui, y_codes, ber_grid, meta).

    Vivado 2025.2 eye-scan CSV layout:
      line 1..N-1: "key,value" metadata
      "Scan Start" marker line
      header line: "<scan_type>,-32,-30,...,30,32"
                    ^^ string label we ignore; rest is integer x-codes
      data rows:   "<y_code>,<ber>,<ber>,...,<ber>"   (y rows top-to-bottom)

    The integer codes are internal eye-scan units; the full horizontal span
    covers the Horizontal Range from metadata (default -0.500..+0.500 UI), so
    we can rescale the codes into UI with a linear map from (min,max) codes
    onto (-halfrange, +halfrange) UI.
    """
    meta = {}
    x_codes = None
    data_rows = []   # list of (y_code, [ber...])

    with open(path, "r", encoding="utf-8", errors="replace") as f:
        state = "meta"   # meta → header → data
        for raw in f:
            line = raw.rstrip("\r\n")
            if not line.strip():
                continue

            if state == "meta":
                if line.strip().lower() == "scan start":
                    state = "header"
                    continue
                if "," in line:
                    k, _, v = line.partition(",")
                    meta[k.strip()] = v.strip()
                continue

            parts = [p.strip() for p in line.split(",")]

            if state == "header":
                try:
                    x_codes = [float(p) for p in parts[1:]]
                except ValueError:
                    x_codes = [float(p) for p in parts if _is_number(p)]
                state = "data"
                continue

            try:
                y = float(parts[0])
                row = [float(p) for p in parts[1:]]
            except ValueError:
                continue
            if x_codes is not None and len(row) != len(x_codes):
                continue
            data_rows.append((y, row))

    if not data_rows or not x_codes:
        raise ValueError(f"No scan data found in {path}")

    y_codes  = np.array([r[0] for r in data_rows], dtype=float)
    ber_grid = np.array([r[1] for r in data_rows], dtype=float)
    x_codes_arr = np.array(x_codes, dtype=float)

    # Rescale x codes to UI using the Horizontal Range metadata if available.
    # Format: "-0.500 UI to 0.500 UI"
    ui_half = 0.5
    hr = meta.get("Horizontal Range", "")
    m = re.match(r"\s*(-?[\d.]+)\s*UI\s*to\s*(-?[\d.]+)\s*UI", hr)
    if m:
        lo, hi = float(m.group(1)), float(m.group(2))
        ui_half = (hi - lo) / 2.0
    code_min, code_max = x_codes_arr.min(), x_codes_arr.max()
    if code_max > code_min:
        x_ui = (x_codes_arr - (code_min + code_max) / 2.0) / ((code_max - code_min) / 2.0) * ui_half
    else:
        x_ui = x_codes_arr

    return x_ui, y_codes, ber_grid, meta


def _is_number(s):
    try:
        float(s); return True
    except ValueError:
        return False


def render_eye(csv_path, png_path, title=None):
    x_ui, y_codes, ber, meta = parse_scan_csv(csv_path)

    # The data comes in with y_codes[0] at the top of the CSV (highest code).
    # imshow with origin="lower" expects the first row to be the lowest.
    # Flip both if rows are in descending y order.
    if len(y_codes) >= 2 and y_codes[0] > y_codes[-1]:
        y_codes = y_codes[::-1]
        ber = ber[::-1, :]

    # Floor zeros so LogNorm doesn't blow up.
    floor = max(1e-12, float(ber[ber > 0].min()) if (ber > 0).any() else 1e-12)
    ber_clip = np.where(ber > 0, ber, floor)

    fig, ax = plt.subplots(figsize=(7.5, 4.8), dpi=130)
    extent = [x_ui.min(), x_ui.max(), y_codes.min(), y_codes.max()]
    im = ax.imshow(
        ber_clip,
        origin="lower",
        aspect="auto",
        extent=extent,
        norm=LogNorm(vmin=floor, vmax=max(1.0, ber_clip.max())),
        cmap="viridis",
        interpolation="nearest",
    )
    ax.set_xlabel("Time offset (UI)")
    ax.set_ylabel("Voltage offset (codes)")

    subtitle_bits = []
    for k in ("Open Area", "Horizontal Percentage", "Vertical Percentage", "Dwell BER"):
        if k in meta: subtitle_bits.append(f"{k}={meta[k]}")
    main_title = title or os.path.basename(csv_path).rsplit(".", 1)[0]
    if subtitle_bits:
        ax.set_title(f"{main_title}\n{'  '.join(subtitle_bits)}", fontsize=9)
    else:
        ax.set_title(main_title)

    cb = plt.colorbar(im, ax=ax)
    cb.set_label("BER")

    footer_bits = []
    for k in ("Scan Name", "Horizontal Range", "Vertical Range"):
        if k in meta: footer_bits.append(f"{k}={meta[k]}")
    if footer_bits:
        fig.text(0.01, 0.01, "  ".join(footer_bits), fontsize=7, color="#555")

    fig.tight_layout()
    fig.savefig(png_path)
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser(description="Render Vivado eye-scan CSVs to PNGs")
    ap.add_argument("path", help="Results directory or a single lane_NN.csv file")
    args = ap.parse_args()

    if os.path.isdir(args.path):
        csvs = sorted(glob.glob(os.path.join(args.path, "lane_*.csv")))
        if not csvs:
            print(f"No lane_*.csv files found in {args.path}", file=sys.stderr)
            sys.exit(1)
    elif os.path.isfile(args.path):
        csvs = [args.path]
    else:
        print(f"Path does not exist: {args.path}", file=sys.stderr)
        sys.exit(1)

    for csv in csvs:
        png = os.path.splitext(csv)[0] + ".png"
        try:
            render_eye(csv, png)
            print(f"  {os.path.basename(csv)} -> {os.path.basename(png)}")
        except Exception as e:
            print(f"  {os.path.basename(csv)} FAILED: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
