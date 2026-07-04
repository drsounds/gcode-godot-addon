# G-Code Tools for Godot

A Godot 4.7 editor plugin that turns **G-code** (`.gcode`) and plain-text (`.txt`) files into first-class Godot resources, then plays them back to drive nodes in your scene — cameras, meshes, lights, or anything else — using CNC-style motion commands.

Think of it as a CNC/3D-printer motion track for your scene objects: author paths and cues as G-code, and let the engine animate your nodes along them.

## Features

- **Custom resource loader** — `.gcode` and `.txt` files are recognized by Godot and imported as `GCodeResource` objects, no manual parsing in your game code.
- **Full-line and inline comment handling** — lines starting with `;` and anything after `;` on a line are stripped.
- **G-code parser** — extracts motion commands (`G0`, `G1`), M-codes (`M3`, …), coordinates (`X`, `Y`, `Z`), feed rate (`F`), and tool selection (`T`).
- **Playback controller** — `CNCController` maps tool numbers to scene nodes and animates their positions with eased tweens based on distance and feed rate.

## Requirements

- Godot **4.7** (this project is configured for the GL Compatibility renderer, but the addon itself is renderer-agnostic).

## Installation

1. Copy the `addons/cnc/` folder into your project's `addons/` directory.
2. In the Godot editor, open **Project → Project Settings → Plugins**.
3. Enable **G-Code Resource Handler**.

Once enabled, the plugin registers a `ResourceFormatLoader`, and Godot will load any `.gcode` or `.txt` file as a `GCodeResource`.

## Usage

### 1. Load a G-code file as a resource

```gdscript
var track: GCodeResource = load("res://tracks/intro.gcode")
```

Each entry in `track.commands` is a `Dictionary`. For example, the line `G1 X10 Y5 F1200` parses to:

```gdscript
{ "type": "G1", "X": 10.0, "Y": 5.0, "F": 1200.0 }
```

- `G` / `M` commands are stored under the `"type"` key as a string (e.g. `"G1"`, `"M3"`).
- Coordinates and other axis letters (`X`, `Y`, `Z`, `F`, `T`, …) are stored as `float` values under their letter key.

### 2. Drive scene nodes with a CNCController

Add a `CNCController` node to your scene and assign which node each **tool number** (`T`) controls:

```gdscript
@onready var cnc: CNCController = $CNCController

func _ready() -> void:
    cnc.target_nodes = {
        1: $Camera3D,           # T1 → the camera
        2: $Water,              # T2 → a MeshInstance3D
        3: $Sun,                # T3 → a DirectionalLight3D
    }
    cnc.execute_track(load("res://tracks/intro.gcode"))
```

### How playback works

- **`T<n>`** selects the active tool — subsequent moves affect whichever node is mapped to that number in `target_nodes`.
- **`G0` / `G1`** move the active node to the given `X` / `Y` / `Z` position. Movement time is derived from the travel distance and the current feed rate (`F`), and tweened with a cubic ease-in-out.
- **`F<value>`** sets the feed rate (units per minute) used to compute move durations.
- **`M3`** invokes a `start_effect()` method on the active node, if it has one — a hook for triggering custom behavior (particles, shaders, sound, …).

Moves run sequentially through a single tween. Calling `execute_track()` again cancels any in-progress track.

## Example G-code

```gcode
; Select the camera and move it into position
T1
G0 X0 Y2 Z10 F3000
G1 X0 Y2 Z5 F1500

; Switch to the sun light and trigger an effect
T3
M3
G1 X10 Y20 Z0 F600
```

## Project layout

```
addons/cnc/
├── plugin.cfg           Plugin metadata
├── plugin.gd            EditorPlugin — registers/unregisters the loader
├── gcode_loader.gd      GCodeFormatLoader — recognizes and parses .gcode/.txt
├── gcode_resource.gd    GCodeResource — holds the parsed command list
└── cnc_controller.gd    CNCController — plays a track back onto scene nodes
```

## Author

Alexander Forselius.

Code generated with help of Gemini
