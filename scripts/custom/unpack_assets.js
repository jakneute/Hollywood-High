/**
 * unpack_assets.js
 * Extracts files from the three binary .pack archives.
 *
 * Usage:
 *   node unpack_assets.js              — interactive menu
 *   node unpack_assets.js all
 *   node unpack_assets.js scenes
 *   node unpack_assets.js sounds
 *   node unpack_assets.js actors
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
    files.forEach(key => {
        const { offset, size } = toc[key];
        const outPath = path.join(destDir, key);
        const outDir  = path.dirname(outPath);
        if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
        if (fs.existsSync(outPath)) console.warn(`    Overwriting: ${key}`);
        fs.writeFileSync(outPath, buf.subarray(offset, offset + size));
        count++;
    });

    console.log(`  [${label}] Extracted ${count} file(s).`);
    return count;
}

// ── Per-pack wrappers ─────────────────────────────────────────────────────────
function unpackScenes() {
    console.log('\n[SCENES]');
    unpack(path.join(datafilesDir, 'scenes.pack'), path.join(unpackedDir, 'scenes'), 'scenes');
}

function unpackSounds() {
    console.log('\n[SOUNDS]');
    unpack(path.join(datafilesDir, 'sounds.pack'), path.join(unpackedDir, 'sounds'), 'sounds');
}

function unpackActors() {
    console.log('\n[ACTORS]');
    unpack(path.join(datafilesDir, 'actors.pack'), path.join(unpackedDir, 'actors'), 'actors');
    console.log('  NOTE: loose files in datafiles/actors/<Name>/config/ take priority over packed versions at runtime.');
}

// ── CLI ───────────────────────────────────────────────────────────────────────
function run(choice) {
    const c = choice.toLowerCase();
    if      (c === '1' || c === 'all')    { unpackScenes(); unpackSounds(); unpackActors(); }
    else if (c === '2' || c === 'scenes') { unpackScenes(); }
    else if (c === '3' || c === 'sounds') { unpackSounds(); }
    else if (c === '4' || c === 'actors') { unpackActors(); }
    else { console.error('Invalid choice.'); process.exit(1); }
    console.log('\nAll done. Edit loose files, then re-pack with pack_assets.js.');
}

const arg = process.argv[2];
if (arg) {
    run(arg);
} else {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    console.log('What would you like to unpack?');
    console.log('  1. All  (scenes, sounds, actors)');
    console.log('  2. Scenes');
    console.log('  3. Sounds');
    console.log('  4. Actors  (sprites + config JSONs)');
    rl.question('Choice [1-4]: ', choice => { rl.close(); run(choice.trim()); });
}
