# Hollywood High

A modern take on old Windows 95 edutainment software. Write screenplays, cast characters, and watch them perform with synthesized voices, animations, and sound effects.

---

## Requirements

- Windows 10 or newer

---

## Features

**Writing**
- Script editor with Voice, Action, Scene, and Particle blocks — reorder, delete, and splice anywhere in the timeline
- Expanded script view hides the scene window for distraction-free writing
- Full keyboard editing in voice blocks: caret navigation, selection, Ctrl+A/C/V, Ctrl+S quick-save

**Performance**
- Theater Mode — full-screen playback with automated character positioning, movement, and voice-over
- Block linking — play two blocks simultaneously to layer dialogue, movement, and effects without manual timing

**Characters & Voice**
- Each character has a unique synthesized voice; per-block overrides via **Alter Voice**
- Fine-grained voice controls: pitch, speed, quality, effort, and timbre
- TTS pronunciation dictionary for overriding specific words globally

**Staging & Visuals**
- Drag and position characters directly in the scene window; positions saved per scene block
- 23 real-time scene effects: fog, rain, snow, CRT, sepia, night vision, heat haze, and more
- Particle system for scripted visual effects tied to blocks
- Canned animations: pre-scripted multi-frame character animations with optional sound sync

**Actions**
- Move, enter/exit, pose, expression, title card, SFX, disappear (multiple styles), and injure
- Injury system: knock down or decapitate characters, with recovery actions (stand up, reform, roll over)
- SFX library browser with support for built-in and custom sounds

**File & Assets**
- Save/load `.hhi` script files; export as readable `.txt` or `.fountain` screenplay
- Import and export custom scenes and sounds
- Unsaved changes warning with `*` indicator in the file menu

---

## File Menu

| Option | Description |
|---|---|
| **New Script** | Clears the current script and resets to a blank slate. Warns if there are unsaved changes. |
| **Save Script** | Saves the full script (blocks, character voice settings, dictionary) to a `.hhi` file. |
| **Load Script** | Opens a `.hhi` file. Warns if there are unsaved changes. |
| **Save Screenplay** | Exports the script as a readable `.txt` or `.fountain` text file (dialogue and actions only, no voice metadata). |
| **Import Assets** | Import custom background scenes or sound effects into the project. |
| **Export Script** | Packages the script and all referenced assets for distribution. |

---

## Script Block Types

| Block | Purpose |
|---|---|
| **Voice** | A line of dialogue spoken by a character via TTS. Use **Alter Voice** to edit voice settings for that block only. |
| **Action** | A character action: move, enter, exit, pose, expression, display title, play SFX, disappear, or injure. |
| **Scene** | Sets the background and initializes character staging for that scene. |
| **Particle** | Attaches a particle effect to the scene at a configurable position/direction. |

---

## Injuries & Recovery

Characters can be injured as part of the story. Injuries are persistent — an injured character stays in their injured state for the rest of the scene unless you add a recovery action.

### Injury types

**Knock Down** — The character falls to the ground. Two fall directions are available:

- **Forwards** — falls toward the viewer
- **Backwards** — falls away from the viewer

**Decapitate** — The character's head is removed. Two modes are available:

- **Remove Head** — the body remains standing, headless
- **Remove Body** — the head floats, body disappears

Both injuries can be combined on the same character — a character can be knocked down *and* decapitated at the same time.

### Recovery actions

Injured characters can recover using action blocks:

| Action | Applies to | What it does |
|---|---|---|
| **Stands Up** | Knocked down | Character rises back to their feet. |
| **Reforms** | Decapitated | Head reattaches; character is whole again. |
| **Rolls Over** | Knocked down | Character flips from face-down to face-up (or vice versa) while staying on the ground. |

Recovery actions are added to the script like any other action block. A character can stand up and still be decapitated, or reform their head while still on the ground — the two injury states are independent.

---

## Scene FX

Each scene block can have one visual effect applied to it. The effect runs continuously during playback whenever that scene is active.

To set an effect, open **Staging Mode** for a scene block and click the **FX** button above the scene window. A dropdown lists all available effects — select one to apply it, or choose **OFF** to remove it.

Effects are per-scene — each scene block stores its own FX setting independently.

### Available Effects

| Effect | Description |
|---|---|
| **OFF** | No effect. |
| **B&W Film** | Desaturates the scene to black and white. |
| **Brighten** | Increases overall brightness. |
| **Candlelight** | Warm flickering orange glow. |
| **CRT** | Scanlines and screen curvature, like an old TV. |
| **Darken** | Reduces overall brightness. |
| **Dream** | Soft, blurred glow with a dreamy wash. |
| **Drunk** | Wobbling distortion. |
| **Embers** | Glowing floating embers drifting upward. |
| **Filth** | Gritty noise and color degradation. |
| **Fog** | Rolling fog layer over the scene. |
| **Frigid** | Cold blue tint with frost-like distortion. |
| **Golden Hour** | Warm amber tone, like late afternoon sun. |
| **Heat Haze** | Shimmering air distortion rising from the ground. |
| **Infrared** | False-color infrared camera look. |
| **Moonlight** | Cool blue night tint. |
| **Night Vision** | Green-tinted grainy night vision camera look. |
| **Rain** | Streaking rain over the scene. |
| **Sepia** | Warm brown monochrome, like an old photograph. |
| **Snow** | Falling snow. |
| **TV Static** | Noise and interference over the image. |
| **Stoned** | Rippling psychedelic color distortion. |
| **Sunlight** | Bright warm wash, like direct sunlight. |
| **Underwater** | Wavering blue-green distortion. |

---

## Linking Blocks

By default, blocks play one at a time — each block finishes before the next begins. **Linking** lets two consecutive blocks play simultaneously, so you can layer actions and dialogue without manual timing.

A small **LINK** button appears in the gap between blocks in the script editor. Click it to link or unlink the pair:

- **Gray** — not linked (blocks play in sequence)
- **Green** — linked (blocks play at the same time)

### What linking is useful for

- Playing a sound effect at the same moment a character speaks
- Moving a character while their dialogue plays
- Triggering a particle effect or title card alongside an action
- Layering two characters' actions at once

### Rules

- Only compatible block combinations can be linked. For example, two scene-setting blocks cannot be linked.
- Links chain — if A is linked to B and B is linked to C, all three play together.
- Linking does not affect the order blocks appear in the script, only when they fire during playback.

---

## Characters & Voices

- Characters are selected from the sidebar. The **+ VOICE** button (green) adds a new dialogue block for the selected character.
- The **VOICE** button (amber) opens the global voice studio for the selected character — changes here apply to all unaltered blocks for that character.
- Clicking **Alter Voice** on a voice block opens the voice studio scoped to that block only.
- Altered blocks are indicated in the block header and are not affected by subsequent global voice changes.

### Voice Studio — Advanced Tweaks

Enable **Advanced Voice Tweaks** in the voice studio to access fine-grained synthesis controls:

| Control | Description |
|---|---|
| **Pitch** | Fundamental frequency of the voice (0–100). |
| **Speed** | Speaking rate (0–100). |
| **Quality** | F0 contour style: Normal, Monotone, or Sung. |
| **Effort** | Voicing mode: Normal, Breathy, or Whispered. |
| **Timbre** | Glottal source model (off / 0–5). Controls the timbral texture of the voice. Value 5 is recommended for the cleanest, most uniform sound across all characters. |

---

## Custom Content

You can add your own background images and sound effects. The game merges custom files with the built-in content automatically at startup.

### Custom Background Scenes

Place image files in:
```
scenes/
```

**Supported formats:** `.png`, `.jpg`, `.jpeg`

The filename (without extension) becomes the scene name and appears in the scene picker with a `(Custom)` label. If a custom scene name matches a built-in scene, the built-in version takes precedence.

#### Adding a Foreground Mask

A mask lets part of the background appear **in front of** characters — useful for desks, counters, walls, or pillars.

Place a second image in the same folder named exactly:
```
<scene_name>_mask.png
```

For example, if your scene is `classroom.png`, the mask is `classroom_mask.png`.

**Mask image rules:**
- Must be a **PNG with an alpha channel** (transparency).
- **Transparent areas** — characters appear normally in front of the background.
- **Opaque areas** — the mask is composited on top of characters, making them appear to stand behind that part of the scene.
- The mask scales to fit the scene window automatically.
- Mask files do not appear as selectable backgrounds in the scene picker.

### Custom Sound Effects

Place `.wav` files inside named subfolders under:
```
sounds/
```

**The folder structure must be exactly one level deep:**
```
sounds/myCategory/explosion.wav
sounds/myCategory/whoosh.wav
sounds/otherCategory/ding.wav
```

Files placed directly in `sounds/` (not in a subfolder) will **not** be detected.

**Supported format:** `.wav` only.

Custom folders and files are merged with the built-in content and appear in the SFX browser alongside them. If a custom file has the same folder/filename as a built-in file, the built-in version takes precedence.

---

## License

All rights reserved. &copy; 2026
