#!/usr/bin/env python3
"""
Split sicp-pocket.texi into books/en_US/ hierarchy for easier translation.

Usage: python3 scripts/split-texi.py
Run from repo root.
"""

import os
import re
import sys

INPUT_FILE = "src/sicp-pocket.texi"
OUTPUT_DIR = "books/en_US"

FRONT_NODES = {"UTF", "Dedication", "Foreword", "Preface", "Preface 1e", "Acknowledgments"}
BACK_NODES = {"References", "Exercises", "Figures", "Term Index", "Colophon"}

FRONT_SLUGS = {
    "UTF": "utf",
    "Dedication": "dedication",
    "Foreword": "foreword",
    "Preface": "preface",
    "Preface 1e": "preface-1e",
    "Acknowledgments": "acknowledgments",
}
BACK_SLUGS = {
    "References": "references",
    "Exercises": "exercises",
    "Figures": "figures",
    "Term Index": "term-index",
    "Colophon": "colophon",
}


def parse_node_directive(line):
    """Return (name, next_node, prev_node, up_node) or None."""
    m = re.match(r"^@node\s+(.*)", line.rstrip())
    if not m:
        return None
    parts = [p.strip() for p in m.group(1).split(",")]
    while len(parts) < 4:
        parts.append("")
    return tuple(parts[:4])


def detect_heading_type(lines, node_idx):
    """Look for the heading type in the lines after @node."""
    for i in range(node_idx + 1, min(node_idx + 6, len(lines))):
        l = lines[i].strip()
        for prefix, htype in [
            ("@subsubsection", "subsubsection"),
            ("@subsection", "subsection"),
            ("@section", "section"),
            ("@chapter", "chapter"),
            ("@unnumbered", "unnumbered"),
            ("@appendix", "appendix"),
            ("@top", "top"),
        ]:
            if l.startswith(prefix + " ") or l == prefix:
                return htype
    return "unknown"


def node_name_to_nums(name):
    """If name looks like '1', '1.2', '1.2.3', '1.2.3.4', return int list. Else None."""
    if re.match(r"^\d+(\.\d+)*$", name):
        return [int(x) for x in name.split(".")]
    return None


def chapter_name_to_num(name):
    """'Chapter 3' -> 3, else None."""
    m = re.match(r"^Chapter\s+(\d+)$", name, re.IGNORECASE)
    return int(m.group(1)) if m else None


def node_to_relpath(name):
    """
    Return (directory_relative_to_en_US, filename) for a node.
    directory is '' for files that go directly in en_US/.
    """
    name = name.strip()

    if name == "Top":
        return ("", "top.texi")

    if name in FRONT_NODES:
        return ("front", FRONT_SLUGS[name] + ".texi")

    if name in BACK_NODES:
        return ("back", BACK_SLUGS[name] + ".texi")

    chnum = chapter_name_to_num(name)
    if chnum is not None:
        return (f"ch{chnum:02d}", "index.texi")

    nums = node_name_to_nums(name)
    if nums:
        if len(nums) == 1:
            return (f"ch{nums[0]:02d}", "index.texi")
        if len(nums) == 2:
            return (f"ch{nums[0]:02d}/s{nums[1]:02d}", "index.texi")
        if len(nums) == 3:
            # might be intermediate (has subsubsections) or leaf — we'll fix later
            return (f"ch{nums[0]:02d}/s{nums[1]:02d}", f"ss{nums[2]:02d}.texi")
        if len(nums) == 4:
            return (f"ch{nums[0]:02d}/s{nums[1]:02d}/ss{nums[2]:02d}", f"sss{nums[3]:02d}.texi")

    # fallback
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return ("misc", slug + ".texi")


def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(content)


def main():
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # --- Pass 1: find all @node boundaries ---
    chunks = []  # list of dict: {name, next, prev, up, htype, start, end}
    for i, line in enumerate(lines):
        if line.startswith("@node"):
            parsed = parse_node_directive(line)
            if parsed:
                name, nxt, prv, up = parsed
                htype = detect_heading_type(lines, i)
                chunks.append({"name": name, "next": nxt, "prev": prv, "up": up,
                                "htype": htype, "start": i, "end": None})

    for j in range(len(chunks) - 1):
        chunks[j]["end"] = chunks[j + 1]["start"]
    if chunks:
        # last chunk ends at @bye or EOF
        for i in range(len(lines) - 1, -1, -1):
            if lines[i].strip() == "@bye":
                chunks[-1]["end"] = i
                break
        else:
            chunks[-1]["end"] = len(lines)

    # --- Pass 2: build parent -> [children] map (ordered) ---
    children_map = {}  # up_node -> [child_name, ...]
    for ch in chunks:
        up = ch["up"]
        if up and up not in ("(dir)", ""):
            children_map.setdefault(up, [])
            if ch["name"] not in children_map[up]:
                children_map[up].append(ch["name"])

    # Detect subsections that have children (subsubsections) -> must be directories
    intermediate_nodes = set(children_map.keys())

    # --- Pass 3: fix paths for intermediate subsections ---
    def get_relpath(name):
        """Get relpath, adjusting subsections that have children to index.texi."""
        d, fn = node_to_relpath(name)
        if name in intermediate_nodes and fn != "index.texi":
            # make it a directory
            base = fn.replace(".texi", "")
            d = f"{d}/{base}" if d else base
            fn = "index.texi"
        return (d, fn)

    # Build lookup: node_name -> chunk
    chunk_by_name = {ch["name"]: ch for ch in chunks}

    # --- Pass 4: identify header block (before first @node) ---
    header_end = chunks[0]["start"] if chunks else len(lines)
    header_lines = lines[:header_end]

    # --- Pass 5: write content files ---
    # For each chunk, write its content:
    # - For intermediate nodes: heading + intro text (up to first child @node) + @include for children
    # - For leaf nodes: heading + all content

    def write_chunk(ch):
        name = ch["name"]
        if name == "Top":
            return  # Top node stays in master file

        d, fn = get_relpath(name)
        out_path = os.path.join(OUTPUT_DIR, d, fn)

        chunk_lines = lines[ch["start"]: ch["end"]]

        if name in intermediate_nodes:
            # Find where the first child starts within chunk_lines
            child_names = children_map[name]
            first_child_local = len(chunk_lines)
            for child in child_names:
                cc = chunk_by_name.get(child)
                if cc and ch["start"] <= cc["start"] < ch["end"]:
                    local_idx = cc["start"] - ch["start"]
                    first_child_local = min(first_child_local, local_idx)

            intro = chunk_lines[:first_child_local]
            # Remove trailing blank lines before adding includes
            while intro and intro[-1].strip() == "":
                intro.pop()
            intro.append("\n")

            includes = []
            for child in child_names:
                cc = chunk_by_name.get(child)
                if cc is None:
                    continue
                cd, cfn = get_relpath(child)
                # compute relative path from d to cd/cfn
                rel = os.path.relpath(os.path.join(OUTPUT_DIR, cd, cfn),
                                      os.path.join(OUTPUT_DIR, d))
                includes.append(f"@include {rel}\n")

            content = intro + includes
        else:
            content = chunk_lines

        write_file(out_path, content)

    for ch in chunks:
        write_chunk(ch)

    # --- Pass 6: write master sicp.texi ---
    top_chunk = chunk_by_name.get("Top")
    top_content = lines[top_chunk["start"]: top_chunk["end"]] if top_chunk else []

    master_lines = header_lines + top_content + ["\n"]

    # Top-level @include order: front matter, chapters, back matter
    top_children = children_map.get("Top", [])
    for child in top_children:
        d, fn = get_relpath(child)
        rel = os.path.relpath(os.path.join(OUTPUT_DIR, d, fn), OUTPUT_DIR)
        master_lines.append(f"@include {rel}\n")

    master_lines.append("\n@bye\n")

    master_path = os.path.join(OUTPUT_DIR, "sicp.texi")
    write_file(master_path, master_lines)

    print(f"Split complete. Output in {OUTPUT_DIR}/")
    print(f"  Master file: {master_path}")
    print(f"  Sections written: {len(chunks)} nodes")


if __name__ == "__main__":
    main()
