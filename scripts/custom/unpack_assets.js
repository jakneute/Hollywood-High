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
        path.join(datafilesDir, 'scenes'),
        'scenes'
    );
}

// ── Sounds ────────────────────────────────────────────────────────────────────
function unpackSounds() {
    console.log('\n[SOUNDS]');
    unpack(
        path.join(datafilesDir, 'sounds.pack'),
        path.join(datafilesDir, 'sounds'),
        'sounds'
    );
    console.log('  NOTE: sounds/ subdirectories (e.g. Animals/dog.wav) are restored automatically.');
}

// ── Actors ────────────────────────────────────────────────────────────────────
function unpackActors(targetChar) {
    console.log('\n[ACTORS]');
    const actorsDir = path.join(datafilesDir, 'actors');

    if (!fs.existsSync(actorsDir)) {
        console.log('  datafiles/actors not found.');
        return;
    }

    let packs = fs.readdirSync(actorsDir).filter(f => path.extname(f) === '.pack').sort();

    if (targetChar) {
        const match = targetChar + '.pack';
        packs = packs.filter(f => f.toLowerCase() === match.toLowerCase());
        if (packs.length === 0) {
            console.error(`  No pack found for: ${targetChar}`);
            return;
        }
    }

    if (packs.length === 0) {
        console.log('  No .pack files found in datafiles/actors/');
        return;
    }

    packs.forEach(packFile => {
        const charName = path.basename(packFile, '.pack');
        unpack(
            path.join(actorsDir, packFile),
            path.join(actorsDir, charName),
            charName
        );
        console.log(`  NOTE: offsets.json / expressions_config.json are not in the pack — they stay loose.`);
    });
}

// ── CLI ───────────────────────────────────────────────────────────────────────
function run(choice, extra) {
    const c = choice.toLowerCase();
    if      (c === '1' || c === 'all')    { unpackScenes(); unpackSounds(); unpackActors(); }
    else if (c === '2' || c === 'scenes') { unpackScenes(); }
    else if (c === '3' || c === 'sounds') { unpackSounds(); }
    else if (c === '4' || c === 'actors') { unpackActors(extra); }
    else { console.error('Invalid choice.'); process.exit(1); }
    console.log('\nAll done. Edit loose files, then re-pack with pack_assets.js.');
}

const arg   = process.argv[2];
const extra = process.argv[3]; // optional character name for actors

if (arg) {
    run(arg, extra);
} else {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    console.log('What would you like to unpack?');
    console.log('  1. All  (scenes, sounds, actors)');
    console.log('  2. Scenes');
    console.log('  3. Sounds');
    console.log('  4. Actors  (or pass a name: node unpack_assets.js actors Gus)');
    rl.question('Choice [1-4]: ', choice => { rl.close(); run(choice.trim(), null); });
}
