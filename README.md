# Shiori

A lightweight visual novel engine for Godot 4.

Shiori runs a scene written in a small text format (`.vn`): dialogue lines,
narration, background/music/pose directives and branching choices. It ships
the parser, a signal-driven runner, JSON save slots, a dialogue history log,
a music player with crossfade, user settings, a typewriter label and a
choice panel. UI layout and assets stay on the game side.

Work in progress.

## Components (`addons/shiori/scripts/`)

| File | Class | Purpose |
|---|---|---|
| `vn_parser.gd` | `VNParser` | `.vn` text → command dictionaries |
| `vn_runner.gd` | `VNRunner` | executes commands, emits signals, branch state snapshots |
| `vn_history.gd` | `VNHistory` | dialogue history ring buffer (300 entries) |
| `vn_save_manager.gd` | `VNSaveManager` | versioned JSON save slots in `user://saves` |
| `vn_audio.gd` | `VNAudio` | two-player music crossfade |
| `vn_settings.gd` | `VNSettings` | text speed / music volume / fullscreen, persisted |
| `typewriter.gd` | `Typewriter` | `Label` that prints text character by character |
| `choice_panel.gd` | `ChoicePanel` | vertical list of option buttons |
| `vn_layout_target.gd` | `VNLayoutTarget` | editable Control/Sprite2D geometry |
| `vn_layout_editor.gd` | `VNLayoutEditor` | visual layout editor with JSON persistence |

## Script format

```
# comment
@bg forest
@music theme
@pose calm            # or @pose none to hide the character
[narration text]
Alice|calm: Hello.    # pose switch is optional
Bob: Hi.
>choice
  - First option.     # options indented 2 spaces relative to >choice
      narration or dialogue inside the branch (indented 4 spaces)
  - Second option.
      ...
@end
```

One source line is one dialogue box. `\n` inside text produces a newline.

## Runner API

`VNRunner` is a `Node`. Load parsed commands, react to signals, drive it
with `advance()` and `select_option(index)`:

```gdscript
var parsed := VNParser.parse(text)
runner.load_script(parsed.commands)
runner.said.connect(func(speaker, text): show_line(speaker, text))
runner.advance()
```

`get_state()` / `restore_state()` snapshot progress (including mid-choice)
as JSON-friendly dictionaries, which is how save slots work.

## Layout editor

`VNLayoutEditor` edits registered Controls and Sprite2Ds without knowing about
the host scene. Supply optional reference artwork, icon textures, and a JSON
path; custom geometry callbacks handle exceptional anchored elements.

```gdscript
const VNLayoutEditor := preload("res://addons/shiori/addons/shiori/scripts/vn_layout_editor.gd")

var editor := VNLayoutEditor.new()
editor.layout_path = "user://layout.json"
editor.reference_texture = reference
add_child(editor)
editor.register_target("portrait", portrait)
editor.register_target("dialogue", dialogue)
editor.register_icon("marker", marker_texture)
```

The inspector supports dragging, proportional scaling, locks, additional
icons, and a translucent reference. `save_layout()` and `load_layout()` use a
versioned JSON schema. `reset_layout()` removes the configured file and emits
`layout_reset`, leaving scene reload behavior to the host.

## Using Shiori in a project

Add it as a git submodule:

```
git submodule add https://github.com/PeacefulMole/shiori.git addons/shiori
```

The engine classes are then available under
`res://addons/shiori/addons/shiori/scripts/`. Because the Shiori repository
keeps its own `project.godot` for standalone development, the host editor
skips indexing the folder, so reference the scripts with `preload()` and
exact paths instead of global class names:

```gdscript
const VNParser := preload("res://addons/shiori/addons/shiori/scripts/vn_parser.gd")
const VNRunner := preload("res://addons/shiori/addons/shiori/scripts/vn_runner.gd")
```

Register the support singletons you need as autoloads in the host project
(`History`, `Saves`, `Audio`, `Settings`).

## Running the tests

The repository is a standalone Godot project:

```
godot --headless --editor --quit --path .   # refresh the class cache once
godot --headless --path . -s tests/run_tests.gd
```
