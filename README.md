# Hollywood High

A modern take on old Windows 95 edutainment software. Write screenplays, cast characters, and watch them perform with synthesized voices, animations, and sound effects.

---

## Features

- **Screenplay Editor** — Create scripts with Voice, Action, Scene, and Particle blocks. Reorder, delete, and splice blocks anywhere in the timeline.
- **TTS Voice System** — Powered by the TiSpeech engine. Each character has a unique voice with configurable pitch, speed, effort, and quality. Individual blocks can override the character default.
- **Theater Mode** — Full-screen playback of your screenplay with automated character positioning, movement, expressions, and voice-over.
- **Scene Staging** — Place and position characters directly in the scene window. Characters remember their positions per scene block.
- **Particle System** — Add visual effects (rain, fire, sparks, etc.) tied to script blocks.
- **Action Blocks** — Characters can move, enter/exit, change pose and expression, display title cards, play sound effects, or disappear with various animations.
- **Dictionary** — Override TTS pronunciation of specific words globally.
- **SFX Library** — Browse and attach sound effects from a folder-based library. Supports both packed and custom loose files.
- **Expanded Script View** — Toggle a full-screen script editor that hides the scene window for easier writing.
- **Keyboard Shortcuts** — Full keyboard editing in voice blocks and the title card text field: caret navigation, click-to-position, drag-to-select, hold-to-repeat backspace/delete/arrows, Ctrl+A, Ctrl+C, Ctrl+V.

---

## Script Block Types

| Block | Purpose |
|---|---|
| **Voice** | A line of dialogue spoken by a character via TTS. Double-click or use the pencil to edit voice settings per-block. |
| **Action** | A character action: move, enter, exit, pose, expression, display title, play SFX, or disappear. |
| **Scene** | Sets the background and initializes character staging for that scene. |
| **Particle** | Attaches a particle effect to the scene at a configurable position/direction. |

---

## Characters & Voices

- Characters are selected from the sidebar. The **+ VOICE** button (green) adds a new dialogue block for the selected character.
- The **VOICE** button (amber) opens the global voice studio for the selected character — changes here apply to all unaltered blocks for that character.
- Double-clicking a voice block, or using the pencil icon, opens the voice studio scoped to that block only ("alter voice — this block only").
- Altered blocks are indicated in the block header and are not affected by subsequent global voice changes.

---

## Custom Content (Modding)

You can add your own background images and sound effects without touching any code. The game merges custom loose files with the built-in packed content automatically at startup.

### Custom Background Scenes

Place image files in:
```
datafiles/scenes/
```

**Supported formats:** `.png`, `.jpg`, `.jpeg`

The filename (without extension) becomes the internal scene name and appears in the scene picker with a `(Custom)` label. Any custom scene name that matches a built-in packed scene is ignored — the pack version takes precedence.

#### Adding a Foreground Mask

A mask lets part of the background appear **in front of** characters, useful for desks, counters, walls, pillars — anything a character should stand behind.

To add a mask for a scene, place a second image in the same folder named exactly:
```
<scene_name>_mask.png
```

For example, if your scene is `classroom.png`, the mask is `classroom_mask.png`.

**Mask image rules:**
- Must be a **PNG with an alpha channel** (transparency).
- **Transparent areas** — characters appear normally in front of the background here.
- **Opaque areas** — the mask image is composited on top of characters here, making characters appear to stand behind that part of the scene.
- The mask is scaled to fit the scene window automatically.
- Mask files are filtered out of the scene picker — they will not appear as selectable backgrounds.

### Custom Sound Effects

Place `.wav` files inside named subfolders under:
```
datafiles/sounds/
```

**The folder structure must be exactly one level deep:**
```
datafiles/sounds/myCategory/explosion.wav
datafiles/sounds/myCategory/whoosh.wav
datafiles/sounds/otherCategory/ding.wav
```

Files placed directly in `datafiles/sounds/` (not in a subfolder) will **not** be detected. Files must be one level deep inside a named subfolder.

**Supported format:** `.wav` only (the audio pipeline reads raw PCM headers — OGG and MP3 are not supported for loose files).

Folder and file names can be anything you want. Custom folders and files are merged with the built-in packed content and appear in the SFX browser alongside them. If a custom file has the same folder/filename as a packed file, the pack version takes precedence.

---

## Project Structure

```
objects/         Core game logic and UI (oHollywoodUI)
scripts/         Helper functions: TTS bridge, sequencer, scene loader, utils
datafiles/       External assets: talkit bridge, scenes/, sounds/, config/
rooms/           Main application room
```

---

## Development

Built with **GameMaker 2024.14+**. Uses a custom C# bridge (`talkit`) for TTS functionality.

### Requirements

- GameMaker 2024.14.4.222 or newer
- Windows (TTS bridge is Windows-only)

### Build Notes

- Loose files in `datafiles/scenes/` and `datafiles/sounds/` are used during development.
- For distribution, run the pack scripts (`pack_actors.js`, etc.) to bundle assets into `.pack` files. The game reads packed and loose files simultaneously — both work at runtime.
- Actor sprites are loose PNG files during development and packed for distribution. JSON config files (expressions, voices) are always loose.

---

## License

All rights reserved. &copy; 2026
