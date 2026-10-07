import importlib.util
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("build_place", ROOT / "tools/build_place.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


def child(parent, name):
    for item in parent.findall("Item"):
        if item.findtext("Properties/string[@name='Name']") == name:
            return item
    raise AssertionError(f"Missing instance {name}")


class PlaceTests(unittest.TestCase):
    def test_place_contains_exact_sources_in_executable_locations(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "game.rbxlx"
            builder.build(output)
            root = ET.parse(output).getroot()
            self.assertEqual(root.attrib["version"], "4")
            shared = child(child(root, "ReplicatedStorage"), "HandClash")
            server = child(root, "ServerScriptService")
            client = child(child(root, "StarterPlayer"), "StarterPlayerScripts")
            expected = [
                (child(shared, "Config"), "ModuleScript", "src/shared/Config.lua"),
                (child(shared, "Rules"), "ModuleScript", "src/shared/Rules.lua"),
                (child(server, "Game"), "Script", "src/server/Game.server.lua"),
                (child(server, "Arena"), "ModuleScript", "src/server/Arena.lua"),
                (child(client, "Interface"), "LocalScript", "src/client/Interface.client.lua"),
            ]
            for item, kind, source in expected:
                with self.subTest(source=source):
                    self.assertEqual(item.attrib["class"], kind)
                    self.assertEqual(
                        item.findtext("Properties/ProtectedString[@name='Source']"),
                        (ROOT / source).read_text(encoding="utf-8"),
                    )
            self.assertEqual(len(root.findall(".//ProtectedString")), len(expected))
            refs = [item.attrib["referent"] for item in root.findall(".//Item")]
            self.assertEqual(len(refs), len(set(refs)))
            self.assertEqual(child(root, "Workspace").attrib["class"], "Workspace")
            self.assertEqual(child(root, "Lighting").attrib["class"], "Lighting")

    def test_rebuilding_produces_the_same_place(self):
        with tempfile.TemporaryDirectory() as directory:
            first, second = Path(directory) / "first.rbxlx", Path(directory) / "second.rbxlx"
            builder.build(first)
            builder.build(second)
            self.assertEqual(first.read_bytes(), second.read_bytes())


if __name__ == "__main__":
    unittest.main()
