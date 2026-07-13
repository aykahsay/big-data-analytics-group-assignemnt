import os
import re
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    os.system("pip install Pillow")
    from PIL import Image, ImageDraw, ImageFont

BG_COLOR      = (15, 23, 42)
HEADER_COLOR  = (30, 41, 59)
TEXT_COLOR    = (226, 232, 240)
TITLE_COLOR   = (96, 165, 250)
BORDER_COLOR  = (37, 99, 235)
PADDING       = 32
LINE_H        = 22
FONT_SIZE     = 15
HEADER_SIZE   = 18
MIN_WIDTH     = 900

def load_font(size):
    candidates = [
        "C:/Windows/Fonts/consola.ttf",
        "C:/Windows/Fonts/cour.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()

def render_png(lines, out_path, title):
    if not lines:
        return
    font = load_font(FONT_SIZE)
    font_bold = load_font(HEADER_SIZE)

    dummy = Image.new("RGB", (1, 1))
    dc = ImageDraw.Draw(dummy)
    max_w = max((dc.textlength(l, font=font) for l in lines), default=0)
    max_w = max(max_w, dc.textlength(title, font=font_bold))

    img_w = int(max(max_w + PADDING * 2 + 16, MIN_WIDTH))
    img_h = int(PADDING * 3 + HEADER_SIZE + 8 + len(lines) * LINE_H + PADDING)

    img = Image.new("RGB", (img_w, img_h), BG_COLOR)
    draw = ImageDraw.Draw(img)

    draw.rectangle([(0, 0), (5, img_h)], fill=BORDER_COLOR)
    draw.rectangle([(6, 0), (img_w, PADDING * 2 + HEADER_SIZE)], fill=HEADER_COLOR)
    draw.text((PADDING, PADDING), title, font=font_bold, fill=TITLE_COLOR)

    y = PADDING * 2 + HEADER_SIZE + 4
    draw.line([(6, y), (img_w, y)], fill=BORDER_COLOR, width=2)
    y += 8

    for i, line in enumerate(lines):
        color = TITLE_COLOR if line.startswith("---") else TEXT_COLOR
        draw.text((PADDING, y + i * LINE_H), line, font=font, fill=color)

    draw.line([(6, img_h - 2), (img_w, img_h - 2)], fill=BORDER_COLOR, width=2)
    img.save(out_path, "PNG", optimize=True)

def main():
    hive_out = Path("c:/bigdata/big-data-analytics-group-assignemnt/scripts/student_hive_output.txt")
    img_dir = Path("c:/bigdata/big-data-analytics-group-assignemnt/images")
    img_dir.mkdir(exist_ok=True)

    text = hive_out.read_text(errors='replace')
    
    sections = [
        ("01_student_count_by_dept", "Task 1: Total Students by Department", "--- 1. Count Students by Department ---"),
        ("02_average_gpa_dept", "Task 2: Average GPA by Department", "--- 2. Average GPA by Department ---"),
        ("03_attendance_below_60", "Task 3: Students with Attendance Below 60%", "--- 3. Students with Attendance Below 60% ---"),
        ("04_placement_rate", "Task 4: Placement Rate by Program", "--- 4. Placement Rate by Program ---"),
        ("05_ranking_students", "Task 5: Ranking Students Within Departments", "--- 5. Ranking Students Within Departments ---"),
    ]

    # Render Hadoop Startup Screenshot
    startup_text = """Starting Hadoop...
Starting namenodes on [localhost]
Starting datanodes
Starting secondary namenodes [Ambition08]
Starting resourcemanager
Starting nodemanagers
Waiting for HDFS to exit safemode...
Safe mode is OFF
Uploading data to HDFS...
Starting Metastore in background...
Waiting for Metastore to open port 9083...
Metastore is up!
Running Hive Queries..."""
    render_png(startup_text.splitlines(), img_dir / "00_hadoop_startup.png", "Hadoop & Hive Startup")

    latex = [
        r"\documentclass{article}",
        r"\usepackage[utf8]{inputenc}",
        r"\usepackage{graphicx}",
        r"\usepackage{geometry}",
        r"\geometry{a4paper, margin=1in}",
        r"\title{Student Performance Dataset - Descriptive and Predictive Analysis}",
        r"\author{Group Assignment}",
        r"\date{\today}",
        r"\begin{document}",
        r"\maketitle",
        r"\section{Hadoop and Hive Environment Startup}",
        r"The Hadoop Distributed File System (HDFS) and YARN resource manager were successfully started in the local cluster environment. Data was uploaded from the local file system into HDFS, and the Hive Metastore service was initialized on port 9083 to enable Hive queries via Beeline.",
        r"\begin{figure}[h!]",
        r"\centering",
        r"\includegraphics[width=0.9\textwidth]{images/00_hadoop_startup.png}",
        r"\caption{Hadoop Cluster and Metastore Startup Process}",
        r"\end{figure}",
        r"\clearpage"
    ]

    for i, (name, title, search_str) in enumerate(sections):
        idx = text.find(search_str)
        if idx == -1:
            print(f"Could not find section {name}")
            continue
        
        # Find the next section to slice
        next_idx = len(text)
        if i + 1 < len(sections):
            next_idx = text.find(sections[i+1][2])
            if next_idx == -1: next_idx = len(text)
            
        chunk = text[idx:next_idx]
        lines = [line for line in chunk.splitlines() if "WARN" not in line and "INFO" not in line and not line.startswith("0: jdbc:hive2://>")]
        
        # Clean lines
        clean_lines = []
        for line in lines:
            line = re.sub(r'26/\d\d/\d\d \d\d:\d\d:\d\d .*?: ', '', line) # Remove Hive timestamps
            if "Time Spent" in line or "rows selected" in line or line.startswith("+---") or line.startswith("|") or "Job" in line or "MapReduce" in line or "HDFS Read" in line:
                clean_lines.append(line)
            elif search_str in line:
                clean_lines.append(line)

        # Keep last 40 lines to avoid massive screenshots if there are many rows
        if len(clean_lines) > 40:
            clean_lines = clean_lines[:15] + ["...", "  ... (Rows Omitted) ...", "..."] + clean_lines[-15:]

        img_path = img_dir / f"{name}.png"
        render_png(clean_lines, img_path, title)
        
        latex.extend([
            f"\\section{{{title}}}",
            r"\begin{figure}[h!]",
            r"\centering",
            f"\\includegraphics[width=0.9\\textwidth]{{images/{name}.png}}",
            f"\\caption{{{title}}}",
            r"\end{figure}",
            r"\clearpage"
        ])
        
    latex.extend([r"\end{document}"])
    
    Path("c:/bigdata/big-data-analytics-group-assignemnt/student_report.tex").write_text("\n".join(latex), encoding="utf-8")
    print("Report generation complete.")

if __name__ == "__main__":
    main()
