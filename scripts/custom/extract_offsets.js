/**
 * extract_offsets.js
 *
 * Reads ACTORS*.RF files and writes offsets.json into each character's
 * datafiles/images/characters/<Name>/ folder.  No image decompression —
 * header-only scan so it runs in seconds.
 *
 * Usage:
 *   node extract_offsets.js [drive]
 *   node extract_offsets.js D        (default: looks in ../../Scratch/CD)
 *
 * offsets.json format  { "pose_21103": [x_off, y_off], ... }
 * Keys have no .png extension to avoid dot-in-key issues in GML json_parse.
 */

'use strict';
const fs   = require('fs');
const path = require('path');

// ── Config ────────────────────────────────────────────────────────────────────

const ACTOR_NAMES = {
     1: "Larry",  2: "Sid",    3: "Tiffanie", 4: "Artie",    5: "Charlotte",
     6: "Chuck",  7: "Billie", 8: "JJ",       9: "Bev",     10: "Lucille",
    11: "Gus",   12: "Lilly", 13: "Matt",    14: "Jenny",   15: "Susan",
    16: "Gary",  17: "Ruth",  18: "Glenn",   19: "Baby",    20: "Stella",
    21: "Anna",  22: "Ed"
};

const RF_FILES = ['ACTORS1.RF', 'ACTORS2.RF', 'ACTORS3.RF', 'ACTORS4.RF'];

const scriptDir  = __dirname;
const projectDir = path.resolve(scriptDir, '..', '..');
const CD_PATH    = path.join(projectDir, 'Scratch', 'CD');
const CHARS_BASE = path.join(projectDir, 'datafiles', 'images', 'characters');

// ── RF parsing ────────────────────────────────────────────────────────────────

function readRFTOC(fd) {
    const header = Buffer.alloc(16);
    fs.readSync(fd, header, 0, 16, 0);
    const tocOffset = header.readUInt32BE(4);
    const tocSize   = header.readUInt32BE(12);

    const tocBuffer = Buffer.alloc(tocSize);
    fs.readSync(fd, tocBuffer, 0, tocSize, tocOffset);

    const numTypes = tocBuffer.readUInt16BE(28) + 1;
    let offsetInTOC = 30;
    const types = [];
    for (let i = 0; i < numTypes; i++) {
        const tag        = tocBuffer.slice(offsetInTOC, offsetInTOC + 4).toString('ascii');
        const count      = tocBuffer.readUInt16BE(offsetInTOC + 4);
        const typeOffset = tocBuffer.readUInt16BE(offsetInTOC + 6);
        types.push({ tag, count, typeOffset });
        offsetInTOC += 8;
    }
    return { types, tocBuffer };
}

// Interpret uint16 as signed (large values are negative offsets in Mac resource land)
function toSigned16(v) { return v > 32767 ? v - 65536 : v; }

// ── Main ──────────────────────────────────────────────────────────────────────

function main() {
    const offsetsByChar = {};

    for (const rfFile of RF_FILES) {
        const filePath = path.join(CD_PATH, rfFile);
        if (!fs.existsSync(filePath)) {
            console.log(`  skip  ${rfFile} (not found at ${filePath})`);
            continue;
        }

        const fd = fs.openSync(filePath, 'r');
        const { types, tocBuffer } = readRFTOC(fd);

        const typeEntry = types.find(t => t.tag === 'Im08');
        if (!typeEntry) {
            console.log(`  skip  ${rfFile} (no Im08 resources)`);
            fs.closeSync(fd);
            continue;
        }

        const actualStart = 30 + typeEntry.typeOffset;
        const entrySize   = 12;
        let found = 0;

        for (let i = 0; i < typeEntry.count; i++) {
            const entryOffset    = actualStart + i * entrySize;
            const chunk          = tocBuffer.slice(entryOffset, entryOffset + entrySize);
            const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
            const id             = chunk.readUInt16BE(10);

            const charId   = Math.floor(id / 1000);
            const charName = ACTOR_NAMES[charId];
            if (!charName) continue;

            const dataOffset = 256 + relativeOffset;

            // Read just the first 12 bytes of the 48-byte resource header
            const hdr = Buffer.alloc(12);
            fs.readSync(fd, hdr, 0, 12, dataOffset);

            const x_off = toSigned16(hdr.readUInt16BE(6));
            const y_off = toSigned16(hdr.readUInt16BE(4));

            if (!offsetsByChar[charName]) offsetsByChar[charName] = {};
            // Key matches what GML builds: "pose_" + prefix + suffix  (no .png)
            offsetsByChar[charName][`pose_${id}`] = [x_off, y_off];
            found++;
        }

        fs.closeSync(fd);
        console.log(`  ok    ${rfFile}  (${found} character sprites)`);
    }

    // Write one offsets.json per character
    let written = 0;
    for (const [charName, offsets] of Object.entries(offsetsByChar)) {
        const charDir = path.join(CHARS_BASE, charName);
        if (!fs.existsSync(charDir)) {
            console.log(`  warn  ${charName}: directory not found, skipping`);
            continue;
        }
        const outPath = path.join(charDir, 'offsets.json');
        fs.writeFileSync(outPath, JSON.stringify(offsets, null, 2));
        console.log(`  wrote ${charName}/offsets.json  (${Object.keys(offsets).length} entries)`);
        written++;
    }

    console.log(`\nDone. Wrote offsets.json for ${written}/${Object.keys(offsetsByChar).length} characters.`);
}

main();
