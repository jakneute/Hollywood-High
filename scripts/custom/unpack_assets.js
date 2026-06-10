/**
 * unpack_assets.js
 * Extracts scenes, sounds, and/or actor PNGs from binary .pack archives.
 *
 * Usage:
 *   node unpack_assets.js                  — interactive menu
 *   node unpack_assets.js all
 *   node unpack_assets.js scenes
 *   node unpack_assets.js sounds
 *   node unpack_assets.js actors           — all actor packs
 *   node unpack_assets.js actors Gus       — single character
 *
 * After extracting, edit the loose files, then re-pack with pack_assets.js.
 */

'use strict';
const fs       = require('fs');
const path     = require('path');
const readline = require('readline');

const projectDir   = path.join(__dirname, '..', '..');
const datafilesDir = path.join(projectDir, 'datafiles');
const unpackedDir  = path.join(__dirname, 'unpacked_assets');

// ── Core unpacker ─────────────────────────────────────────────────────────────
function unpack(packPath, destDir, label) {
    if (!fs.existsSync(packPath)) {
        console.log(`  [${label}] Not found: ${packPath}`);
        return 0;
    }

    console.log(`  [${label}] Reading ${path.basename(packPath)}...`);
    const buf        = fs.readFileSync(packPath);
    const headerSize = buf.readUInt32LE(0);

    let toc;
    try {
        toc = JSON.parse(buf.toString('utf8', 4, 4 + headerSize));
    } catch (e) {
        console.error(`  [${label}] Failed to parse header: ${e.message}`);
        return 0;
    }

    const files = Object.keys(toc);
    console.log(`  [${label}] ${files.length} file(s) → ${destDir}`);

    let count = 0;
    files.forEach(filename => {
        const { offset, size } = toc[filename];
        const outPath = path.join(destDir, filename);
        const outDir  = path.dirname(outPath);
        if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
        if (fs.existsSync(outPath)) console.warn(`    Overwriting: ${filename}`);
        fs.writeFileSync(outPath, buf.subarray(offset, offset + size));
        count++;
    });

    console.log(`  [${label}] Extracted ${count} file(s).`);
    return count;
}

// ── Scenes ────────────────────────────────────────────────────────────────────
function unpackScenes() {
    console.log('\n[SCENES]');
    unpack(
        path.join(datafilesDir, 'scenes.pack'),
        path.join(unpackedDir, 'scenes'),
        'scenes'
    );
}

// ── Sounds ────────────────────────────────────────────────────────────────────
function unpackSounds() {
    console.log('\n[SOUNDS]');
    unpack(
        path.join(datafilesDir, 'sounds.pack'),
        path.join(unpackedDir, 'sounds'),
        'sounds'
    );
    console.log('  NOTE: sounds/ subdirectories (e.g. Animals/dog.wav) are restored automatically.');
}

// ── Actors ────────────────────────────────────────────────────────────────────
function unpackActors(targetChar) {
    console.log('\n[ACTORS]');
    const packPath  = path.join(datafilesDir, 'actors.pack');
    const actorsDir = path.join(unpackedDir, 'actors');

    if (!fs.existsSync(packPath)) {
        console.log(`  actors.pack not found at ${packPath}`);
        return;
    }

    console.log(`  Reading actors.pack...`);
    const buf        = fs.readFileSync(packPath);
    const headerSize = buf.readUInt32LE(0);

    let toc;
    try {
        toc = JSON.parse(buf.toString('utf8', 4, 4 + headerSize));
    } catch (e) {
        console.error(`  Failed to parse actors.pack header: ${e.message}`);
        return;
    }

    const filter = targetChar ? targetChar.toLowerCase() : null;
    let count = 0;
    let skipped = 0;

    Object.keys(toc).forEach(key => {
        const slash = key.indexOf('/');
        if (slash < 0) return;
        const charDir  = key.slice(0, slash);
        const filename = key.slice(slash + 1);

        // Sprites are keyed lowercase; configs use original case — normalise for filter
        if (filter && charDir.toLowerCase() !== filter) { skipped++; return; }

        if (!filename.endsWith('.png')) return; // configs extracted separately

        const { offset, size } = toc[key];
        const outDir = path.join(actorsDir, charDir);
        if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

        const outPath = path.join(outDir, filename);
        fs.writeFileSync(outPath, buf.subarray(offset, offset + size));
        count++;
    });

    const total = Object.keys(toc).filter(k => k.endsWith('.png')).length;
    if (filter) {
        console.log(`  Extracted ${count} PNG(s) for "${targetChar}" (${skipped} others skipped).`);
    } else {
        console.log(`  Extracted ${count}/${total} PNG(s) → scripts/custom/unpacked_assets/actors/`);
    }
}

// ── Config JSONs ──────────────────────────────────────────────────────────────
function unpackConfigs(targetChar) {
    console.log('\n[CONFIGS]');
    const packPath  = path.join(datafilesDir, 'actors.pack');
    const actorsDir = path.join(unpackedDir, 'actors');

    if (!fs.existsSync(packPath)) {
        console.log(`  actors.pack not found at ${packPath}`);
        return;
    }

    console.log(`  Reading actors.pack...`);
    const buf        = fs.readFileSync(packPath);
    const headerSize = buf.readUInt32LE(0);

    let toc;
    try {
        toc = JSON.parse(buf.toString('utf8', 4, 4 + headerSize));
    } catch (e) {
        console.error(`  Failed to parse actors.pack header: ${e.message}`);
        return;
    }

    const filter = targetChar ? targetChar.toLowerCase() : null;
    let count = 0;
    let skipped = 0;

    // Keys are: "charname/config/filename.json"
    Object.keys(toc).forEach(key => {
        if (!key.endsWith('.json')) return;
        const parts = key.split('/');
        if (parts.length !== 3 || parts[1] !== 'config') return;
        const charDir  = parts[0];
        const filename = parts[2];

        if (filter && charDir !== filter) { skipped++; return; }

        const { offset, size } = toc[key];
        const outDir = path.join(actorsDir, charDir, 'config');
        if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

        const outPath = path.join(outDir, filename);
        if (fs.existsSync(outPath)) console.warn(`    Overwriting: ${key}`);
        fs.writeFileSync(outPath, buf.subarray(offset, offset + size));
        count++;
    });

    if (filter) {
        console.log(`  Extracted ${count} JSON(s) for "${targetChar}" (${skipped} others skipped) → unpacked_assets/actors/<Name>/config/`);
    } else {
        console.log(`  Extracted ${count} JSON(s) → unpacked_assets/actors/<Name>/config/`);
    }
    console.log(`  NOTE: loose files in datafiles/actors/<Name>/config/ take priority over packed versions at runtime.`);
}

// ── CLI ───────────────────────────────────────────────────────────────────────
function run(choice, extra) {
    const c = choice.toLowerCase();
    if      (c === '1' || c === 'all')     { unpackScenes(); unpackSounds(); unpackActors(); unpackConfigs(); }
    else if (c === '2' || c === 'scenes')  { unpackScenes(); }
    else if (c === '3' || c === 'sounds')  { unpackSounds(); }
    else if (c === '4' || c === 'actors')  { unpackActors(extra); }
    else if (c === '5' || c === 'configs') { unpackConfigs(extra); }
    else { console.error('Invalid choice.'); process.exit(1); }
    console.log('\nAll done. Edit loose files, then re-pack with pack_assets.js.');
}

const arg   = process.argv[2];
const extra = process.argv[3]; // optional character name for actors/configs

if (arg) {
    run(arg, extra);
} else {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    console.log('What would you like to unpack?');
    console.log('  1. All  (scenes, sounds, actors, configs)');
    console.log('  2. Scenes');
    console.log('  3. Sounds');
    console.log('  4. Actors  (or pass a name: node unpack_assets.js actors Gus)');
    console.log('  5. Configs  (or pass a name: node unpack_assets.js configs Gus)');
    rl.question('Choice [1-5]: ', choice => { rl.close(); run(choice.trim(), null); });
}
