#!/usr/bin/env python3
"""Build an editable Roblox XML place from the Rojo project, without dependencies."""
import argparse
import json
from itertools import count
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
REFERENTS = count(1)


def add_item(parent, name, class_name, source=None):
    item = ET.SubElement(parent, "Item", {"class": class_name, "referent": f"RBX{next(REFERENTS)}"})
    properties = ET.SubElement(item, "Properties")
    ET.SubElement(properties, "string", {"name": "Name"}).text = name
    if source is not None:
        ET.SubElement(properties, "ProtectedString", {"name": "Source"}).text = source
    return item


def add_source(parent, path, name=None):
    if path.is_dir():
        folder = add_item(parent, name or path.name, "Folder")
        for child in sorted(path.iterdir()):
            if child.suffix == ".lua":
                add_source(folder, child)
        return folder
    filename = path.name
    if filename.endswith(".server.lua"):
        kind, inferred_name = "Script", filename[:-11]
    elif filename.endswith(".client.lua"):
        kind, inferred_name = "LocalScript", filename[:-11]
    elif filename.endswith(".lua"):
        kind, inferred_name = "ModuleScript", filename[:-4]
    else:
        raise ValueError(f"Unsupported source: {path}")
    return add_item(parent, name or inferred_name, kind, path.read_text(encoding="utf-8"))


def add_tree(parent, name, node):
    if "$path" in node:
        return add_source(parent, ROOT / node["$path"], name)
    item = add_item(parent, name, node.get("$className", "Folder"))
    for child_name, child in node.items():
        if not child_name.startswith("$"):
            add_tree(item, child_name, child)
    return item


def build(output):
    global REFERENTS
    REFERENTS = count(1)
    project = json.loads((ROOT / "default.project.json").read_text())
    root = ET.Element("roblox", {"version": "4"})
    ET.SubElement(root, "External").text = "null"
    ET.SubElement(root, "External").text = "nil"
    add_item(root, "Workspace", "Workspace")
    add_item(root, "Lighting", "Lighting")
    for name, node in project["tree"].items():
        if not name.startswith("$"):
            add_tree(root, name, node)
    output.parent.mkdir(parents=True, exist_ok=True)
    ET.indent(root)
    ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)
    scripts = root.findall(".//ProtectedString")
    print(f"Built {output}: {len(scripts)} scripts/modules")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "build" / "HandClash.rbxlx")
    build(parser.parse_args().output.resolve())
