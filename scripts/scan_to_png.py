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
import json
import math
import os
import re
import sys

try:
    import numpy as np
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.colors import BoundaryNorm, ListedColormap
except ImportError as e:
    print("ERROR: matplotlib / numpy not available:", e, file=sys.stderr)
    print("Install with: pip install matplotlib numpy  (or apt install python3-matplotlib python3-numpy)",
          file=sys.stderr)
    sys.exit(1)


# ---------------- Vivado IBERT eye-scan color scale ----------------
# 12 discrete bins matching the ones Vivado's Hardware Manager shows for an
# eye scan. Each colour represents a range of BER values; the label is the
# "centre" BER of that range and is positioned at the geometric mean of the
# bin's lower and upper edges so that on a log scale it lands in the middle
# of the cell.
#
# The internal boundaries are the geometric means of adjacent labels:
#     b[i] = sqrt(label[i-1] * label[i])
# Bin 0 is extended down to 0 to catch every "eye-opening" sample (where
# the scanner saw fewer errors than its Dwell BER target and therefore
# reports an effectively-zero BER), and bin 11 is extended up to 1.0 so
# any worst-case BER is clamped into the darkest-red cell.
#
#   bin       BER range                     color       label
#   --------  ----------------------------  ----------  --------
#   0  (low)  [0,         2.236e-06)        #0080ff     1.0e-06
#   1         [2.236e-06, 7.071e-06)        #00d9ff     5.0e-06
#   2         [7.071e-06, 2.236e-05)        #00ffff     1.0e-05
#   3         [2.236e-05, 7.071e-05)        #00ff4c     5.0e-05
#   4         [7.071e-05, 2.236e-04)        #00ff00     1.0e-04
#   5         [2.236e-04, 7.071e-04)        #b2ff00     5.0e-04
#   6         [7.071e-04, 2.236e-03)        #ffff00     1.0e-03
#   7         [2.236e-03, 7.071e-03)        #ffa600     5.0e-03
#   8         [7.071e-03, 2.236e-02)        #ff7f00     1.0e-02
#   9         [2.236e-02, 7.071e-02)        #ff2600     5.0e-02
#  10         [7.071e-02, 1.817e-01)        #ff0000     1.0e-01
#  11 (high)  [1.817e-01, 1.0]              #bd0000     3.3e-01
#
# Note: because the label sequence alternates ratios 5, 2, 5, 2, …, 3.3,
# the labels are approximately (but not exactly) at the log centre of
# their bins — they're offset by at most ~0.1 decades, which is small
# compared with a cell width of ~0.5 decades. Perfect centring would
# require labels in a constant-ratio geometric progression.

VIVADO_COLORS = [
    "#0080ff",  # 1.0e-06  (bottom: eye-opening / lowest BER)
    "#00d9ff",  # 5.0e-06
    "#00ffff",  # 1.0e-05
    "#00ff4c",  # 5.0e-05
    "#00ff00",  # 1.0e-04
    "#b2ff00",  # 5.0e-04
    "#ffff00",  # 1.0e-03
    "#ffa600",  # 5.0e-03
    "#ff7f00",  # 1.0e-02
    "#ff2600",  # 5.0e-02
    "#ff0000",  # 1.0e-01
    "#bd0000",  # 3.3e-01  (top: closed eye / highest BER)
]

# The label values (in number form) that sit at the "centre" of each bin.
_VIVADO_LABEL_VALUES = [
    1.0e-06, 5.0e-06,
    1.0e-05, 5.0e-05,
    1.0e-04, 5.0e-04,
    1.0e-03, 5.0e-03,
    1.0e-02, 5.0e-02,
    1.0e-01, 3.3e-01,
]

# 13 edges for 12 bins. The internal edges are geometric means of adjacent
# labels; the outermost edges are clamped to [0, 1.0].
VIVADO_BOUNDARIES = (
    [0.0]
    + [math.sqrt(_VIVADO_LABEL_VALUES[i] * _VIVADO_LABEL_VALUES[i + 1])
       for i in range(len(_VIVADO_LABEL_VALUES) - 1)]
    + [1.0]
)

# Label shown next to each cell in the colourbar.
VIVADO_LABELS = [
    "1.0e-06", "5.0e-06",
    "1.0e-05", "5.0e-05",
    "1.0e-04", "5.0e-04",
    "1.0e-03", "5.0e-03",
    "1.0e-02", "5.0e-02",
    "1.0e-01", "3.3e-01",
]


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


def _read_target_name(csv_path):
    """Best-effort lookup of the target design name for a scan CSV.

    ibert_test.py writes a metadata.json alongside the per-lane CSVs with
    the target name — pick it up if present, otherwise fall back to the
    parent directory name (which matches the results/<target>/<ts>/ layout
    the Python driver uses). Returns "" if nothing plausible is found.
    """
    meta_path = os.path.join(os.path.dirname(csv_path), "metadata.json")
    if os.path.isfile(meta_path):
        try:
            with open(meta_path, "r", encoding="utf-8") as f:
                target = json.load(f).get("target")
                if target:
                    return str(target)
        except Exception:
            pass
    # Fall back to <target>/<timestamp>/lane_NN.csv path layout
    parent = os.path.basename(os.path.dirname(os.path.dirname(os.path.abspath(csv_path))))
    return parent or ""


def render_eye(csv_path, png_path, title=None):
    x_ui, y_codes, ber, meta = parse_scan_csv(csv_path)

    # The CSV lists y rows top-to-bottom (highest code first). imshow with
    # origin="lower" expects the first row to be the lowest y value.
    if len(y_codes) >= 2 and y_codes[0] > y_codes[-1]:
        y_codes = y_codes[::-1]
        ber = ber[::-1, :]

    # Every pixel gets a discrete colour. Samples below the scanner floor
    # (Dwell BER, ≈ 1e-6) fall into bin 0 and are painted with the lowest
    # colour #0080ff — this is what Vivado uses to fill the eye opening.
    # Samples above the top boundary are clamped into the darkest-red bin.
    cmap = ListedColormap(VIVADO_COLORS)
    cmap.set_under(VIVADO_COLORS[0])
    cmap.set_over(VIVADO_COLORS[-1])
    norm = BoundaryNorm(VIVADO_BOUNDARIES, ncolors=cmap.N, clip=False)

    # Main figure: eye plot on the left, manual 12-cell colourbar on the right.
    fig = plt.figure(figsize=(8.4, 5.0), dpi=130)
    ax    = fig.add_axes([0.09, 0.12, 0.72, 0.76])   # [left, bottom, w, h]
    cb_ax = fig.add_axes([0.86, 0.12, 0.035, 0.76])

    # Use contourf instead of imshow so the boundaries between colour bins
    # are smooth curves instead of pixel stair-steps. contourf draws filled
    # polygon regions between contour levels, and each region gets one of
    # our discrete colours — so the colours stay discrete (12 distinct
    # values, not a gradient) while the *boundaries* between them are
    # smooth interpolated lines. This matches how Vivado's HW Manager
    # displays eye scans.
    X, Y = np.meshgrid(x_ui, y_codes)
    ax.contourf(
        X, Y, ber,
        levels=VIVADO_BOUNDARIES,
        colors=VIVADO_COLORS,
        extend="both",
    )
    ax.set_xlim(x_ui.min(), x_ui.max())
    ax.set_ylim(y_codes.min(), y_codes.max())
    ax.set_xlabel("Time offset (UI)")
    ax.set_ylabel("Voltage offset (codes)")

    # Title and subtitle — prepend the target design name (from the sibling
    # metadata.json or the <target>/<timestamp>/ path layout) to the lane
    # label so each chart clearly identifies which design it came from.
    if title is None:
        lane_label = os.path.basename(csv_path).rsplit(".", 1)[0]
        target = _read_target_name(csv_path)
        main_title = f"{target} - {lane_label}" if target else lane_label
    else:
        main_title = title
    area = meta.get("Open Area")
    hp   = meta.get("Horizontal Percentage")
    vp   = meta.get("Vertical Percentage")
    if area and hp and vp:
        ax.set_title(f"{main_title}\nOpen area {area}  ({hp}% horz × {vp}% vert)", fontsize=9)
    else:
        ax.set_title(main_title)

    # Manual discrete colourbar: 12 colour cells with labels centred on each cell.
    # Matplotlib's built-in colorbar places tick labels on cell edges; Vivado
    # draws them at the visual centre of each cell, so we build our own.
    n = len(VIVADO_COLORS)
    cb_ax.set_xlim(0, 1)
    cb_ax.set_ylim(0, n)
    for i, color in enumerate(VIVADO_COLORS):
        cb_ax.add_patch(plt.Rectangle(
            (0, i), 1, 1,
            facecolor=color,
            edgecolor="black",
            linewidth=0.4,
        ))
    # Labels at the vertical centre of each cell
    for i, label in enumerate(VIVADO_LABELS):
        cb_ax.text(1.25, i + 0.5, label, va="center", ha="left", fontsize=8)
    cb_ax.set_xticks([])
    cb_ax.set_yticks([])
    for spine in cb_ax.spines.values():
        spine.set_visible(False)
    cb_ax.text(0.5, n + 0.25, "BER", va="bottom", ha="center", fontsize=9)

    # Footer: scan ranges and dwell value
    footer_bits = []
    for k in ("Scan Name", "Horizontal Range", "Vertical Range", "Dwell BER"):
        if k in meta:
            footer_bits.append(f"{k}={meta[k]}")
    if footer_bits:
        fig.text(0.01, 0.01, "  ".join(footer_bits), fontsize=7, color="#555")

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
