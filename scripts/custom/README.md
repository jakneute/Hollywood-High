# Hollywood High CD-ROM Asset Extractor

This utility allows you to extract the original high-fidelity graphics and sound assets directly from the **Hollywood High CD-ROM** and convert them to modern, standard formats.

---

## What It Extracts
1. **Character Sprites (Actors)**: All 22 characters and their full pose sets, exported as transparent `.png` files with perfectly corrected character palette shading, outlines, and eye colors mapped from `character_color_mappings.json`.
2. **Backgrounds (Scenes)**: Full-size backgrounds exported as `.png` files.
3. **Dialogue & Sound Effects (Sounds)**: Original uncompressed Mac audio formats converted to standard mono 16-bit `.wav` files at their native sampling rates, with dynamic filename labeling matched from the CD-ROM's Table of Contents.

---

## Step-by-Step Instructions

### Step 1: Mount the CD-ROM
To extract the assets, the original Hollywood High CD-ROM must be accessible to your computer.
* **If you have a physical disc**: Insert it into your CD/DVD drive. Note down the drive letter (e.g., `D:`, `E:`, `J:`).
* **If you have a digital disc image (ISO / BIN / CUE)**: 
  * Right-click the `.iso` or disc image file in Windows Explorer and select **Mount**.
  * Windows will assign a virtual CD-ROM drive letter to it. Note down this letter (e.g., `J:`).

### Step 2: Install Dependencies
Open your terminal (PowerShell, Command Prompt, or bash) and navigate to this folder:
```bash
cd "scripts/custom"
```

Install the required extraction dependencies by running:
```bash
npm install
```

### Step 3: Run the Extractor
Start the automated extraction process:
```bash
node extract_hhi.js
```

### Step 4: Specify the CD Drive Letter
When prompted, type the drive letter corresponding to your mounted CD-ROM (e.g., `J` or `D`) and press **Enter**:
```text
Please enter the drive letter for the Hollywood High CD-ROM (e.g., J): J
```

The script will automatically detect the resource files and process all actors, scenes, and audio tracks in one swift, seamless run! The outputs will be placed neatly inside a new `extracted_assets/` subfolder.
