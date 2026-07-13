#!/usr/bin/env python3
"""
txt_to_png.py
Converts Hive query text output files in images/ into styled PNG screenshots.
Usage: python3 scripts/txt_to_png.py <images_dir>
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow not found. Installing...")
    os.system("pip install Pillow 2>/dev/null || pip3 install Pillow 2>/dev/null")
    from PIL import Image, ImageDraw, ImageFont

# ── Styling ──────────────────────────────────────────────────────────────────
BG_COLOR      = (15, 23, 42)        # dark navy background
HEADER_COLOR  = (30, 41, 59)        # slightly lighter header bar
TEXT_COLOR    = (226, 232, 240)     # light gray text
TITLE_COLOR   = (96, 165, 250)      # blue title
BORDER_COLOR  = (37, 99, 235)       # accent border
LINE_COLOR    = (51, 65, 85)        # separator lines
PADDING       = 32
LINE_H        = 22
FONT_SIZE     = 15
HEADER_SIZE   = 18
MIN_WIDTH     = 900

# ── Title map ─────────────────────────────────────────────────────────────────
TITLES = {
    "01_hdfs_upload":           "HDFS Upload — EmployeeDataset.csv → /data/employee/",
    "02_raw_table_load":        "Task 0 — Create Staging Table emp_raw & Load Data",
    "03_missing_experience":    "Problem 1 — Missing Values in experience_years",
    "04_duplicate_jobids":      "Problem 2 — Duplicate job_id Values",
    "05_inconsistent_casing":   "Problem 3 — Inconsistent Casing in education_level",
    "06_outlier_salary":        "Problem 4 — Outlier Salary Values (< $1,000)",
    "07_remote_location":       "Problem 5 — 'Remote' Used as Location Value",
    "08_cleaned_table":         "Fix Applied — Cleaned Table emp_no_dup (ORC + Snappy)",
    "09_split_title":           "Task 2 — Split job_title: first_title_word | remaining_title",
    "10_phd_experience_country":"Task 3 — PhD Holders with < 10 Years Experience by Country",
    "11_skills_count_asc":      "Task 4 — Skills Count in Ascending Order",
    "12_growth_rate_detail":    "Task 5 — Growth Rate of call_log (Row-by-Row)",
    "13_growth_rate_summary":   "Task 5 Summary — Average Growth Rate per Education Level",
    "14_future_prediction":     "Task 6 — Predicted Future call_log Values (Compound Growth)",
}

def load_font(size):
    """Try to load a monospace font, fall back to default."""
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
        "/usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf",
        "C:/Windows/Fonts/consola.ttf",
        "C:/Windows/Fonts/cour.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()

def render_txt_to_png(txt_path: Path, out_path: Path, title: str):
    """Render a .txt file to a styled PNG image."""
    lines = txt_path.read_text(errors="replace").splitlines()
    # Remove empty leading/trailing lines
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()

    font       = load_font(FONT_SIZE)
    font_bold  = load_font(HEADER_SIZE)

    # Measure text
    dummy = Image.new("RGB", (1, 1))
    dc    = ImageDraw.Draw(dummy)
    max_w = max((dc.textlength(l, font=font) for l in lines), default=0)
    max_w = max(max_w, dc.textlength(title, font=font_bold))

    img_w = int(max(max_w + PADDING * 2 + 16, MIN_WIDTH))
    img_h = int(PADDING * 3 + HEADER_SIZE + 8 + len(lines) * LINE_H + PADDING)

    img  = Image.new("RGB", (img_w, img_h), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Left accent bar
    draw.rectangle([(0, 0), (5, img_h)], fill=BORDER_COLOR)

    # Header bar
    draw.rectangle([(6, 0), (img_w, PADDING * 2 + HEADER_SIZE)], fill=HEADER_COLOR)

    # Title
    draw.text((PADDING, PADDING), title, font=font_bold, fill=TITLE_COLOR)

    # Separator
    y = PADDING * 2 + HEADER_SIZE + 4
    draw.line([(6, y), (img_w, y)], fill=BORDER_COLOR, width=2)
    y += 8

    # Content lines
    for i, line in enumerate(lines):
        color = TITLE_COLOR if line.startswith("====") else TEXT_COLOR
        draw.text((PADDING, y + i * LINE_H), line, font=font, fill=color)

    # Bottom border
    draw.line([(6, img_h - 2), (img_w, img_h - 2)], fill=BORDER_COLOR, width=2)

    img.save(out_path, "PNG", optimize=True)
    print(f"  ✓  {out_path.name}")

def main():
    images_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("images")
    if not images_dir.exists():
        print(f"Directory not found: {images_dir}")
        sys.exit(1)

    print(f"\n=== Converting text outputs → PNG in {images_dir} ===\n")
    converted = 0
    for txt_file in sorted(images_dir.glob("*.txt")):
        stem  = txt_file.stem
        title = TITLES.get(stem, stem.replace("_", " ").title())
        # Map stem to final PNG name used in LaTeX
        png_name = stem.replace("01_", "hdfs_upload") \
                       .replace("02_", "raw_table_load") \
                       .replace("03_", "missing_experience") \
                       .replace("04_", "duplicate_jobids") \
                       .replace("05_", "inconsistent_casing") \
                       .replace("06_", "outlier_salary") \
                       .replace("07_", "remote_location") \
                       .replace("08_", "cleaned_table") \
                       .replace("09_", "split_title") \
                       .replace("10_", "phd_experience_country") \
                       .replace("11_", "skills_count_asc") \
                       .replace("12_", "growth_rate_detail") \
                       .replace("13_", "growth_rate_summary") \
                       .replace("14_", "future_prediction")

        # If name still has digits prefix, strip it
        import re
        png_name = re.sub(r"^\d+_", "", stem)
        png_file = images_dir / f"{png_name}.png"
        render_txt_to_png(txt_file, png_file, title)
        converted += 1

    print(f"\n=== Done. {converted} PNG(s) written to {images_dir} ===\n")

if __name__ == "__main__":
    main()
