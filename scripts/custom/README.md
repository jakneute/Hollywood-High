# Hollywood High — Custom Scripts

This folder contains Node.js utilities for extracting, unpacking, and repacking
the game's binary asset archives, as well as planning documents for the custom
actor system.

---

## Scripts

### `extract_hhi.js` — CD-ROM Asset Extractor
Extracts original assets directly from the Hollywood High CD-ROM and converts
them to modern formats. Outputs to `extracted_assets/` in this folder.

**What it extracts:**
- **Actors** — all 22 characters and their full pose sets as transparent `.png` files,
  with palette corrections applied from `color_mappings.json`
- **Scenes** — full-size background images as `.png` files
- **Sounds** — original Mac audio converted to standard mono 16-bit `.wav` files
- **Main** — source scripts, UI graphics, and other binary assets from `MAIN.RF`

**Usage:**
```bash
npm install        # first time only
node extract_hhi.js
```
Enter your CD-ROM drive letter when prompted. Choose what to extract from the menu.
Output lands in `extracted_assets/` — review and move assets manually from there.

---

### `unpack_assets.js` — Pack File Extractor
Extracts scenes, sounds, or actor sprites from the game's binary `.pack` archives.
Reads `.pack` files from `datafiles/` and outputs loose files to `unpacked_assets/`
in this folder, keeping them away from the live project until you're ready.

**Usage:**
```bash
node unpack_assets.js
```
Choose what to unpack from the menu. Extracted files land in `unpacked_assets/`.
Review and make edits there before moving anything into `datafiles/`.

---

### `pack_assets.js` — Pack File Builder
Packs loose files back into binary `.pack` archives.
Writes the new `.pack` file to the directory you run the script from,
so you can verify it before manually overwriting the one in `datafiles/`.

When packing actors, config JSONs (`offsets.json`, `expressions.json`, `animations.json`) are
read from `datafiles/config/<Name>/` and included in `actors.pack` automatically.

**Usage:**
```bash
node pack_assets.js
```
Choose what to pack from the menu. Move the resulting `.pack` to `datafiles/` when ready.

---

### `update_offsets.js` — Character Offset Updater
Re-reads the original `.RF` actor files from the CD-ROM scratch copy and writes updated position offset data to each character's `datafiles/config/<Name>/offsets.json`. Run this after re-extracting actors or adjusting sprite origins.

**Usage:**
```bash
node update_offsets.js
```

---

## Config JSON priority

At runtime, a loose file in `datafiles/actors/<Name>/config/` always wins over the packed version in `actors.pack`. This means:

- The expression configurator and animation editor write loose files as normal — no repacking needed during development.
- Packing configs is purely for distribution: once packed, the loose files can be deleted and the game reads from the pack.
- To edit a packed config, either unpack it first (`node unpack_assets.js configs <Name>`) or just drop a new loose file in `datafiles/actors/<Name>/config/` — it will override the pack immediately.

---

## Workflow

The intended pipeline for updating assets:

```
CD-ROM  →  extract_hhi.js  →  extracted_assets/   (review here)
                                      ↓  move manually
                              unpacked_assets/      (edit here)
                                      ↓  pack_assets.js
                              new .pack file        (verify here)
                                      ↓  move manually
                              datafiles/            (live)
```

Nothing moves forward automatically. Every handoff is intentional.

---

## Custom Assets

Custom scenes, sounds, and actors can be added without touching the CD-ROM pipeline at all.

- **Custom scenes** — drop a `.png` into `datafiles/scenes/`
- **Custom sounds** — drop a `.wav` into the appropriate `datafiles/sounds/` category subfolder
- **Custom actors** — see `custom_actor_plan.md` for the full system design

Both scenes and sounds are picked up automatically with no additional configuration.

---

## Files

| File | Purpose |
|---|---|
| `extract_hhi.js` | CD-ROM extractor |
| `unpack_assets.js` | Unpack `.pack` archives to loose files |
| `pack_assets.js` | Repack loose files into `.pack` archives |
| `update_offsets.js` | Re-reads `.RF` files to refresh per-character position offsets in `datafiles/config/` |
| `color_mappings.json` | Palette correction overrides for actor extraction |
| `extracted_assets/` | Output folder for CD-ROM extraction |
| `unpacked_assets/` | Staging folder for unpacked assets |
