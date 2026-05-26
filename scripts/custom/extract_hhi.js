const fs = require('fs');
const path = require('path');
const { Jimp } = require('jimp');
const readline = require('readline');

// Create output folders if they don't exist
const baseOutDir = path.join(__dirname, 'extracted_assets');
const actorsDir = path.join(baseOutDir, 'actors');
const scenesDir = path.join(baseOutDir, 'scenes');
const soundsDir = path.join(baseOutDir, 'sounds');
const mainDir = path.join(baseOutDir, 'main');

[baseOutDir, actorsDir, scenesDir, soundsDir, mainDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

// PackBits Decompressor (used only for Im08 image chunks)
function decompressPackBits(compressedBuffer) {
    const out = [];
    let inPtr = 0;
    while (inPtr < compressedBuffer.length) {
        const header = compressedBuffer.readInt8(inPtr++);
        if (header >= 0 && header <= 127) {
            const count = header + 1;
            for (let i = 0; i < count; i++) {
                if (inPtr < compressedBuffer.length) {
                    out.push(compressedBuffer[inPtr++]);
                }
            }
        } else if (header >= -127 && header <= -1) {
            const count = 1 - header;
            if (inPtr < compressedBuffer.length) {
                const val = compressedBuffer[inPtr++];
                for (let i = 0; i < count; i++) {
                    out.push(val);
                }
            }
        }
    }
    return Buffer.from(out);
}

// Extract Global Palette
function getGlobalPalette(drive) {
    const palettePath = `${drive}:\\ACTORS1.RF`;
    if (!fs.existsSync(palettePath)) {
        throw new Error(`Palette file not found at ${palettePath}`);
    }
    const fd = fs.openSync(palettePath, 'r');
    const palBuf = Buffer.alloc(2048);
    fs.readSync(fd, palBuf, 0, 2048, 11946359 + 8);
    fs.closeSync(fd);

    const palette = [];
    for (let i = 0; i < 256; i++) {
        const idx = i * 8;
        if (idx + 7 < palBuf.length) {
            palette.push({ r: palBuf[idx + 3], g: palBuf[idx + 5], b: palBuf[idx + 7] });
        } else {
            palette.push({ r: 0, g: 0, b: 0 });
        }
    }

    return palette;
}

// Helper to sanitize filenames for Windows OS safety
function sanitizeFilename(name) {
    if (!name) return '';
    return name.replace(/[\\/:*?"<>|]/g, '_').trim();
}

// Pre-scan all scene files to find any named scene resources and automatically label visual layers
function preScanSceneNames(drive) {
    const foundNames = {};
    const resourcesByGroup = {};

    const sceneFiles = [
        `${drive}:\\SCENES1.RF`,
        `${drive}:\\SCENES2.RF`,
        `${drive}:\\SCENES3.RF`
    ];

    for (const filePath of sceneFiles) {
        if (!fs.existsSync(filePath)) continue;

        const fd = fs.openSync(filePath, 'r');
        const header = Buffer.alloc(16);
        fs.readSync(fd, header, 0, 16, 0);

        const tocOffset = header.readUInt32BE(4);
        const tocSize = header.readUInt32BE(12);

        const tocBuffer = Buffer.alloc(tocSize);
        fs.readSync(fd, tocBuffer, 0, tocSize, tocOffset);

        const namesOffset = tocBuffer.readUInt16BE(26);
        const numTypesMinus1 = tocBuffer.readUInt16BE(28);
        const numTypes = numTypesMinus1 + 1;

        function getString(offset) {
            if (offset === 0xffff || offset >= tocBuffer.length - namesOffset) return '';
            const start = namesOffset + offset;
            const len = tocBuffer[start];
            if (len === 0 || start + 1 + len > tocBuffer.length) return '';
            return tocBuffer.slice(start + 1, start + 1 + len).toString('ascii').trim();
        }

        let offsetInTOC = 30;
        const types = [];
        for (let i = 0; i < numTypes; i++) {
            const tag = tocBuffer.slice(offsetInTOC, offsetInTOC + 4).toString('ascii');
            const count = tocBuffer.readUInt16BE(offsetInTOC + 4);
            const typeOffset = tocBuffer.readUInt16BE(offsetInTOC + 6);
            types.push({ tag, count, typeOffset });
            offsetInTOC += 8;
        }

        const typeEntry = types.find(t => t.tag === 'Im08');
        if (typeEntry) {
            const actualStart = 30 + typeEntry.typeOffset;
            const entrySize = 12;
            for (let i = 0; i < typeEntry.count; i++) {
                const entryOffset = actualStart + i * entrySize;
                const chunk = tocBuffer.slice(entryOffset, entryOffset + entrySize);
                const nameOff = chunk.readUInt16BE(0);
                const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
                const id = chunk.readUInt16BE(10);

                const dataOffset = 256 + relativeOffset;
                const sizeBuf = Buffer.alloc(12);
                fs.readSync(fd, sizeBuf, 0, 12, dataOffset);

                const height = sizeBuf.readUInt16BE(8);
                const width = sizeBuf.readUInt16BE(10);

                const name = getString(nameOff);
                const cleanName = name ? sanitizeFilename(name) : '';

                const groupId = sceneReroutes[id] !== undefined ? sceneReroutes[id] : Math.floor(id / 10);
                if (cleanName) {
                    foundNames[groupId] = cleanName;
                }

                if (!resourcesByGroup[groupId]) {
                    resourcesByGroup[groupId] = [];
                }
                resourcesByGroup[groupId].push({ id, width, height, lastDigit: id % 10 });
            }
        }

        // SCNE friendly name parser
        const typeEntrySCNE = types.find(t => t.tag === 'SCNE');
        if (typeEntrySCNE) {
            const actualStart = 30 + typeEntrySCNE.typeOffset;
            const entrySize = 12;
            for (let i = 0; i < typeEntrySCNE.count; i++) {
                const entryOffset = actualStart + i * entrySize;
                const chunk = tocBuffer.slice(entryOffset, entryOffset + entrySize);
                const nameOff = chunk.readUInt16BE(0);
                const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;

                const name = getString(nameOff);
                const cleanName = name ? sanitizeFilename(name) : '';
                if (cleanName) {
                    const dataOffset = 256 + relativeOffset;
                    const scneData = Buffer.alloc(12);
                    fs.readSync(fd, scneData, 0, 12, dataOffset);
                    const scneImgGroupId = scneData.readUInt16BE(10);
                    if (scneImgGroupId > 0 && scneImgGroupId < 100) {
                        foundNames[scneImgGroupId] = cleanName;
                    }
                }
            }
        }

        fs.closeSync(fd);
    }

    // Assign labels dynamically for each group based on visual layers (width >= 200)
    for (const groupId in resourcesByGroup) {
        const list = resourcesByGroup[groupId];
        const visualLayers = list.filter(r => r.width >= 200);
        if (visualLayers.length === 0) continue;

        // Find the maximum height among all visual layers in this group
        const maxVisualHeight = Math.max(...visualLayers.map(v => v.height));

        // Tallest layers are backgrounds
        const backgrounds = visualLayers.filter(v => v.height === maxVisualHeight);

        // Shorter layers are foregrounds/masks, sorted by height descending
        const overlays = visualLayers.filter(v => v.height < maxVisualHeight);
        overlays.sort((a, b) => {
            if (b.height !== a.height) return b.height - a.height;
            if (b.width !== a.width) return b.width - a.width;
            return a.lastDigit - b.lastDigit;
        });

        // Label all backgrounds
        for (const bg of backgrounds) {
            sceneLabels[bg.id] = 'background';
        }

        // Label overlays sequentially
        if (overlays.length > 0) {
            sceneLabels[overlays[0].id] = 'foreground';
        }
        for (let i = 1; i < overlays.length; i++) {
            sceneLabels[overlays[i].id] = i === 1 ? 'mask' : `mask_${i}`;
        }
    }
    // Resolve case-insensitive name collisions (e.g. "Classroom" vs "classroom") before manual overrides
    const lowerNames = {};
    for (const groupId in foundNames) {
        const name = foundNames[groupId];
        const lower = name.toLowerCase();
        if (lowerNames[lower] !== undefined) {
            const otherGroupId = lowerNames[lower];
            foundNames[otherGroupId] = `${foundNames[otherGroupId]}_${otherGroupId}`;
            foundNames[groupId] = `${name}_${groupId}`;
        } else {
            lowerNames[lower] = groupId;
        }
    }

    // Apply manual name overrides last so they always win
    for (const id in manualSceneNames) {
        foundNames[id] = manualSceneNames[id];
    }

    return foundNames;
}

// Decode Macintosh 80-bit extended floats to standard double sampling rates
function decodeExtendedFloat(buf, offset = 0) {
    if (buf.length < offset + 10) return 22050;
    const exponent = buf.readUInt16BE(offset) & 0x7FFF;
    const mantissaHi = buf.readUInt32BE(offset + 2);
    const mantissaLo = buf.readUInt32BE(offset + 6);

    if (exponent === 0 && mantissaHi === 0 && mantissaLo === 0) return 0;

    const mantissaDouble = mantissaHi * Math.pow(2, -31) + mantissaLo * Math.pow(2, -63);
    const value = mantissaDouble * Math.pow(2, exponent - 16383);

    const rounded = Math.round(value);
    if (Math.abs(rounded - 22255) < 300) return 22050; // Map standard 22254 Hz Mac rate to standard 22050 Hz
    if (Math.abs(rounded - 11127) < 200) return 11025; // Map standard 11127 Hz Mac rate to standard 11025 Hz
    return rounded;
}

// Helper to write standard 44-byte RIFF/WAV header along with audio data
function writeWav(pcmData, sampleRate, bitDepth, outPath) {
    const numChannels = 1;
    const byteRate = (sampleRate * numChannels * bitDepth) / 8;
    const blockAlign = (numChannels * bitDepth) / 8;
    const wavHeader = Buffer.alloc(44);

    wavHeader.write('RIFF', 0);
    wavHeader.writeUInt32LE(36 + pcmData.length, 4);
    wavHeader.write('WAVE', 8);

    wavHeader.write('fmt ', 12);
    wavHeader.writeUInt32LE(16, 16);
    wavHeader.writeUInt16LE(1, 20); // Uncompressed PCM Format
    wavHeader.writeUInt16LE(numChannels, 22);
    wavHeader.writeUInt32LE(sampleRate, 24);
    wavHeader.writeUInt32LE(byteRate, 28);
    wavHeader.writeUInt16LE(blockAlign, 32);
    wavHeader.writeUInt16LE(bitDepth, 34);

    wavHeader.write('data', 36);
    wavHeader.writeUInt32LE(pcmData.length, 40);

    const outFd = fs.openSync(outPath, 'w');
    fs.writeSync(outFd, wavHeader);
    fs.writeSync(outFd, pcmData);
    fs.closeSync(outFd);
}

const actrNames = {
    1: "Larry", 2: "Sid", 3: "Tiffanie", 4: "Artie", 5: "Charlotte",
    6: "Chuck", 7: "Billie", 8: "JJ", 9: "Bev", 10: "Lucille",
    11: "Gus", 12: "Lilly", 13: "Matt", 14: "Jenny", 15: "Susan",
    16: "Gary", 17: "Ruth", 18: "Glenn", 19: "Baby", 20: "Stella",
    21: "Anna", 22: "Ed"
};

let globalPalette = null;
let colorMappings = {};
let sceneGroupNames = {};
let sceneLabels = {};

// Hardcoded rerouting map to fix the original CD-ROM's compilation index misalignments!
const sceneReroutes = {
    352: 52, // national park foreground
    360: 35, // bathroom foreground
    362: 47, // bowling alley foreground
    370: 36, // arcade foreground
    380: 37, // cafe foreground
    381: 40, // garage foreground
    390: 38, // living room day background
    410: 39, // living room night foreground
    420: 41, // basketball gym foreground
    432: 43, // dance gym foreground
    440: 68, // pyramid foreground
    450: 42, // cheerleader gym foreground
    460: 45, // the burbs background
    470: 44, // locker foreground
    472: 49, // clothing store foreground
    480: 46, // haunted house foreground
    490: 48, // movie theater lobby foreground
    491: 38, // living room day foreground
    500: 49, // clothing store background
    501: 45, // the burbs foreground
    510: 50, // pyramid background
    511: 68, // music store background
    531: 67, // leaning tower background
    532: 66, // silent movie background
    550: 58, // lookout point foreground
    560: 67, // leaning tower foreground
    570: 59, // city street background
    571: 55, // orthodontist foreground
    580: 62, // movies foreground
    591: 54, // beach foreground
    600: 56, // fastfood counter foreground
    610: 60, // classroom_60 foreground
    620: 61, // airplane foreground
    630: 57, // mall foreground
    632: 57, // mall background
    640: 63, // Eye of the storm background
};

// Manual dictionary to easily assign names to scene groups as you discover them
const manualSceneNames = {
    15: "jungle",
    29: "alley",
    50: "music store",
    66: "silent movie",
    67: "leaning tower",
    68: "pyramid",
};

const sceneSoundMapping = {
    1519: "Art Gallery",
    1518: "School Cafeteria",
    1517: "Classroom_16",
    1511: "Car",
    1516: "Jungle",
    1514: "Kitchen",
    1515: "Mad Scientist's Lab",
    1513: "Auditorium",
    1512: "Spaceship",
    1520: "Alien Planet",
    1524: "Stadium",
    1526: "Diner",
    1521: "Car",
    1522: "Dining Room",
    1527: "Operating Room",
    1528: "Talk Show",
    1525: "Messy Room",
    1529: "News Room",
    1523: "Wild West Saloon",
    1537: "Arcade",
    1536: "Bathroom",
    1538: "Cafe",
    1535: "Cheerleader's Gym",
    1539: "Living Room Day",
    1547: "Dance Gym",
    1541: "Garage",
    1544: "Garage",
    1548: "Haunted House",
    1540: "Living Room Night",
    1545: "Locker",
    1549: "Movie Theater Lobby",
    1543: "National Park",
    1546: "The Burbs",
    1556: "Beach",
    1550: "Bowling Alley",
    1557: "Fast Food Counter",
    1555: "Classroom_60",
    1551: "Clothing Store",
    1558: "Orthodontist",
    1559: "Mall",
    1554: "Leaning Tower",
    1552: "Pyramid",
    1560: "Airplane",
    1562: "Lookout Point",
    1561: "City Street",
    1567: "Basketball Gym",
    17567: "Basketball Gym"
};

function formatFolderName(name) {
    if (!name) return '';
    
    let formatted = name;
    
    // Normalize Day/Night parentheticals and clear weird punctuation from internal names
    formatted = formatted.replace(/\s*\(\s*Day\s*\)/gi, " Day");
    formatted = formatted.replace(/\s*\(\s*Night\s*\)/gi, " Night");
    formatted = formatted.replace(/[();]/g, ""); // Strip any remaining rogue parentheses or semicolons
    formatted = formatted.replace(/\s+/g, " ").trim(); // Collapse multiple spaces

    formatted = formatted.replace(/\b\w/g, (char, index, str) => {
        if (index > 0 && str[index - 1] === "'") return char.toLowerCase();
        return char.toUpperCase();
    });
    
    // Formatting typoes and normalizing specific characters
    formatted = formatted.replace(/Cheerleaders.*?Gym/gi, "Cheerleader's Gym");
    formatted = formatted.replace(/Fastfood.*?Counter/gi, "Fast Food Counter");
    formatted = formatted.replace(/Burps/gi, "Burp's");
    formatted = formatted.replace(/Livingroom/gi, "Living Room");
    formatted = formatted.replace(/Wildwest.*?Saloon/gi, "Wild West Saloon");
    formatted = formatted.replace(/Scientist.*?Lab/gi, "Scientist's Lab");

    // Reconcile underlying internal image TOC names with the target audio folder taxonomy
    const reconciliations = {
        "Movie Lobby": "Movie Theater Lobby",
        "Cafeteria": "School Cafeteria",
        "Suburbia": "The Burbs",
        "Make-Out Spot": "Lookout Point",
        "Make Out Spot": "Lookout Point",
        "Urban House #1": "City Street",
        "Urban House": "City Street",
        "Rushmore": "National Park",
        "Dentist": "Orthodontist",
        "Hospital": "Operating Room",
        "Latenight": "Talk Show",
        "Late Night": "Talk Show",
        "Press Conference": "Auditorium",
        "Gym": "Basketball Gym",
        "Pisa": "Leaning Tower",
        "Saloon": "Wild West Saloon"
    };

    if (reconciliations[formatted]) formatted = reconciliations[formatted];
    if (/scientist.*?lab/i.test(formatted)) formatted = "Mad Scientist's Lab";
    if (formatted.toLowerCase().includes("classroom_16")) formatted = "Classroom_16";
    if (formatted.toLowerCase().includes("classroom_60")) formatted = "Classroom_60";

    return formatted.trim();
}

// Load JSON color mappings safely
const mappingPath = path.join(__dirname, 'color_mappings.json');
if (fs.existsSync(mappingPath)) {
    try {
        colorMappings = JSON.parse(fs.readFileSync(mappingPath, 'utf8'));
        console.log('Successfully loaded color mappings.');
    } catch (e) {
        console.error('Error reading color_mappings.json:', e);
    }
} else {
    console.log('Warning: color_mappings.json not found. Using default palette.');
}

// Parse and extract from an RF file
// mode: 'actors' | 'scenes' | 'sounds'
async function processRFFile(filePath, mode) {
    const isActorFile = mode === 'actors';
    const isSceneFile = mode === 'scenes';
    const isSoundFile = mode === 'sounds';
    const isMainFile = mode === 'main';
    if (!fs.existsSync(filePath)) {
        console.log(`Skipping missing file: ${filePath}`);
        return;
    }

    console.log(`\nProcessing ${filePath}...`);

    const fd = fs.openSync(filePath, 'r');
    const header = Buffer.alloc(16);
    fs.readSync(fd, header, 0, 16, 0);

    const tocOffset = header.readUInt32BE(4);
    const tocSize = header.readUInt32BE(12);

    const tocBuffer = Buffer.alloc(tocSize);
    fs.readSync(fd, tocBuffer, 0, tocSize, tocOffset);

    const namesOffset = tocBuffer.readUInt16BE(26);
    const numTypesMinus1 = tocBuffer.readUInt16BE(28);
    const numTypes = numTypesMinus1 + 1;

    function getString(offset) {
        if (offset === 0xffff || offset >= tocBuffer.length - namesOffset) return '';
        const start = namesOffset + offset;
        const len = tocBuffer[start];
        if (len === 0 || start + 1 + len > tocBuffer.length) return '';
        return tocBuffer.slice(start + 1, start + 1 + len).toString('ascii').trim();
    }

    let offsetInTOC = 30;
    const types = [];
    for (let i = 0; i < numTypes; i++) {
        const tag = tocBuffer.slice(offsetInTOC, offsetInTOC + 4).toString('ascii');
        const count = tocBuffer.readUInt16BE(offsetInTOC + 4);
        const typeOffset = tocBuffer.readUInt16BE(offsetInTOC + 6);
        types.push({ tag, count, typeOffset });
        offsetInTOC += 8;
    }

    // A. Handle Image Extraction (Im08 tag)
    if (isActorFile || isSceneFile || isMainFile) {
        const targetTag = 'Im08';
        const typeEntry = types.find(t => t.tag === targetTag);
        if (typeEntry) {
            const actualStart = 30 + typeEntry.typeOffset;
            const entrySize = 12;
            let extractedCount = 0;

            for (let i = 0; i < typeEntry.count; i++) {
                const entryOffset = actualStart + i * entrySize;
                const chunk = tocBuffer.slice(entryOffset, entryOffset + entrySize);

                const nameOff = chunk.readUInt16BE(0);
                const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
                const id = chunk.readUInt16BE(10);

                const dataOffset = 256 + relativeOffset;

                if (dataOffset >= tocOffset || dataOffset < 256) {
                    continue;
                }

                try {
                    const sizeBuf = Buffer.alloc(48);
                    fs.readSync(fd, sizeBuf, 0, 48, dataOffset);
                    const dataCompressedSize = sizeBuf.readUInt32BE(0);

                    if (dataCompressedSize <= 0 || dataCompressedSize > 10000000) continue;

                    const y_offset = sizeBuf.readUInt16BE(4);
                    const x_offset = sizeBuf.readUInt16BE(6);
                    const height = sizeBuf.readUInt16BE(8);
                    const width = sizeBuf.readUInt16BE(10);

                    if (width <= 0 || height <= 0 || width > 2000 || height > 2000) continue;

                    // Skip small thumbnail / low-res mask images under 200px wide
                    if (isSceneFile && width < 200) continue;

                    let rowBytes = Math.ceil(width / 4) * 4;

                    let outPath = '';
                    let activeRemap = null;
                    let typeSuffix = 'actor';
                    let groupName = '';

                    if (isActorFile) {
                        const charRouteId = Math.floor(id / 1000);
                        const characterName = actrNames[charRouteId] || "Unknown";
                        
                        const characterDir = path.join(actorsDir, characterName);
                        if (!fs.existsSync(characterDir)) {
                            fs.mkdirSync(characterDir, { recursive: true });
                        }
                        outPath = path.join(characterDir, `pose_${id}.png`);
                        activeRemap = colorMappings[characterName] || null;
                    } else if (isSceneFile) {
                        const groupId = sceneReroutes[id] !== undefined ? sceneReroutes[id] : Math.floor(id / 10);
                        const lastDigit = id % 10;

                        // Determine the group name
                        groupName = manualSceneNames[groupId] || sceneGroupNames[groupId] || `scene_group_${groupId}`;
                        groupName = formatFolderName(groupName);

                        // Determine the file type suffix dynamically or fall back to last digit
                        typeSuffix = sceneLabels[id] || '';
                        if (!typeSuffix) {
                            if (lastDigit === 0) {
                                typeSuffix = 'walkmask';
                            } else if (lastDigit === 1) {
                                typeSuffix = 'background';
                            } else if (lastDigit === 2) {
                                typeSuffix = 'foreground';
                            } else if (lastDigit === 3) {
                                typeSuffix = 'mask';
                            } else {
                                typeSuffix = 'unknown';
                            }
                        }

                        const sceneSpecificDir = path.join(scenesDir, groupName);
                        if (!fs.existsSync(sceneSpecificDir)) {
                            fs.mkdirSync(sceneSpecificDir, { recursive: true });
                        }
                        const sceneName = `${groupName}_${typeSuffix}_${id}.png`;
                        outPath = path.join(sceneSpecificDir, sceneName);
                    } else if (isMainFile) {
                        const outImgDir = path.join(mainDir, 'images');
                        if (!fs.existsSync(outImgDir)) {
                            fs.mkdirSync(outImgDir, { recursive: true });
                        }
                        const cleanName = sanitizeFilename(getString(nameOff)) || `image_${id}`;
                        outPath = path.join(outImgDir, `${cleanName}.png`);
                    }

                    const compressedData = Buffer.alloc(dataCompressedSize);
                    fs.readSync(fd, compressedData, 0, dataCompressedSize, dataOffset + 48);

                    const decompressed = decompressPackBits(compressedData);

                    let canvasWidth = width;
                    let canvasHeight = height;
                    let renderX = 0;
                    let renderY = 0;

                    const isVisualScene = isSceneFile && (width > 100 || height > 100);
                    if (isVisualScene) {
                        canvasWidth = 512;
                        canvasHeight = 260;
                        renderX = x_offset;
                        renderY = y_offset;
                    }

                    const image = new Jimp({ width: canvasWidth, height: canvasHeight });

                    for (let y = 0; y < height; y++) {
                        for (let x = 0; x < width; x++) {
                            const srcIdx = y * rowBytes + x;
                            if (srcIdx < decompressed.length) {
                                let paletteIdx = decompressed[srcIdx];

                                let color = globalPalette[paletteIdx] || { r: 0, g: 0, b: 0 };
                                if (activeRemap && activeRemap[paletteIdx] !== undefined) {
                                    const mapped = activeRemap[paletteIdx].color;
                                    color = { r: mapped[0], g: mapped[1], b: mapped[2] };
                                }

                                const destX = x + renderX;
                                const destY = y + renderY;
                                if (destX >= 0 && destX < canvasWidth && destY >= 0 && destY < canvasHeight) {
                                    const dataIdx = (destY * canvasWidth + destX) * 4;
                                    
                                    // True transparency routing: backgrounds/walkmasks render index 0 & 255 as solid colors
									const isTransparent = (isActorFile || isMainFile || typeSuffix === 'foreground' || typeSuffix === 'mask') && 
														  paletteIdx === 255;
                                    
                                    if (isTransparent) {
                                        image.bitmap.data[dataIdx] = 0;
                                        image.bitmap.data[dataIdx + 1] = 0;
                                        image.bitmap.data[dataIdx + 2] = 0;
                                        image.bitmap.data[dataIdx + 3] = 0;
                                    } else {
                                        image.bitmap.data[dataIdx] = color.r;
                                        image.bitmap.data[dataIdx + 1] = color.g;
                                        image.bitmap.data[dataIdx + 2] = color.b;
                                        image.bitmap.data[dataIdx + 3] = 255;
                                    }
                                }
                            }
                        }
                    }

                    // Modern Jimp (v1+) uses getBuffer, older used getBufferAsync.
                    // Pinning to a specific version allows you to remove this check.
                    const pngBuf = await image.getBuffer('image/png');
                    fs.writeFileSync(outPath, pngBuf);
                    extractedCount++;

                } catch (err) {
                    console.error(`Error processing image ID ${id} in ${filePath}:`, err.message);
                }

                if (i > 0 && i % 250 === 0) {
                    console.log(`    Processed ${i}/${typeEntry.count} images...`);
                }
            }
            console.log(`  Finished image extraction for ${filePath}: Extracted ${extractedCount} items successfully.`);
        }
    }

    // B. Handle Sound Extraction (snd tag) - Uncompressed Macintosh snd Resources
    if (isSoundFile || isActorFile || isSceneFile || isMainFile) {
        const targetTag = 'snd ';
        const typeEntry = types.find(t => t.tag === targetTag);
        if (typeEntry) {
            const actualStart = 30 + typeEntry.typeOffset;
            const entrySize = 12;
            let extractedCount = 0;

            for (let i = 0; i < typeEntry.count; i++) {
                const entryOffset = actualStart + i * entrySize;
                const chunk = tocBuffer.slice(entryOffset, entryOffset + entrySize);

                const nameOff = chunk.readUInt16BE(0);
                const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
                const id = chunk.readUInt16BE(10);

                const dataOffset = 256 + relativeOffset;

                if (dataOffset >= tocOffset || dataOffset < 256) {
                    continue;
                }

                try {
                    const sizeBuf = Buffer.alloc(48);
                    fs.readSync(fd, sizeBuf, 0, 48, dataOffset);
                    const dataCompressedSize = sizeBuf.readUInt32BE(0);

                    if (dataCompressedSize <= 48) continue;

                    // Read uncompressed sound resource starting at dataOffset + 48
                    const rawData = Buffer.alloc(dataCompressedSize - 48);
                    fs.readSync(fd, rawData, 0, rawData.length, dataOffset + 48);

                    // ExtendedSoundHeader properties are mapped directly inside the raw uncompressed data
                    const sampleRate = decodeExtendedFloat(rawData, 2);
                    const sampleSize = rawData.length >= 26 ? rawData.readUInt16BE(24) : 16;

                    const pcmBig = rawData.slice(40);
                    let pcmData;

                    if (sampleSize === 16) {
                        pcmData = Buffer.alloc(pcmBig.length);
                        for (let j = 0; j < pcmBig.length; j += 2) {
                            if (j + 1 < pcmBig.length) {
                                pcmData.writeUInt16LE(pcmBig.readUInt16BE(j), j);
                            }
                        }
                    } else {
                        pcmData = pcmBig;
                    }

                    const name = getString(nameOff);
                    const cleanName = sanitizeFilename(name);

                    let targetDir = soundsDir;
                    
                    if (isActorFile) {
                        const charRouteId = Math.floor(id / 1000);
                        const characterName = actrNames[charRouteId] || "Unknown";
                        targetDir = path.join(actorsDir, characterName, 'audio');
                    } else if (isSceneFile) {
                        let groupName = sceneSoundMapping[id];
                        if (!groupName) {
                            const groupId = sceneReroutes[id] !== undefined ? sceneReroutes[id] : Math.floor(id / 10);
                            groupName = manualSceneNames[groupId] || sceneGroupNames[groupId] || `scene_group_${groupId}`;
                        }
                        groupName = formatFolderName(groupName);
                        targetDir = path.join(scenesDir, groupName);
                    } else if (isMainFile) {
                        targetDir = path.join(mainDir, 'sounds');
                    }
                    
                    if (!fs.existsSync(targetDir)) {
                        fs.mkdirSync(targetDir, { recursive: true });
                    }

                    const soundFilename = cleanName ? `${cleanName}_${id}.wav` : `sound_${id}.wav`;
                    const outPath = path.join(targetDir, soundFilename);

                    writeWav(pcmData, sampleRate, sampleSize, outPath);
                    extractedCount++;

                } catch (err) {
                    console.error(`Error processing sound ID ${id} in ${filePath}:`, err.message);
                }

                if (i > 0 && i % 250 === 0) {
                    console.log(`    Processed ${i}/${typeEntry.count} sounds...`);
                }
            }
            console.log(`  Finished sound extraction for ${filePath}: Extracted ${extractedCount} items successfully.`);
        }
    }

    // C. Handle Generic Extraction for Main Files
    if (isMainFile) {
        for (const typeEntry of types) {
            if (typeEntry.tag === 'Im08' || typeEntry.tag === 'snd ') continue; // Handled natively above

            const actualStart = 30 + typeEntry.typeOffset;
            const entrySize = 12;
            let extractedCount = 0;
            const safeTag = sanitizeFilename(typeEntry.tag.trim()) || 'UNKNOWN';
            const targetDir = path.join(mainDir, safeTag);

            for (let i = 0; i < typeEntry.count; i++) {
                const entryOffset = actualStart + i * entrySize;
                const chunk = tocBuffer.slice(entryOffset, entryOffset + entrySize);
                const nameOff = chunk.readUInt16BE(0);
                const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
                const id = chunk.readUInt16BE(10);

                const dataOffset = 256 + relativeOffset;
                if (dataOffset >= tocOffset || dataOffset < 256) continue;

                try {
                    const sizeBuf = Buffer.alloc(4);
                    fs.readSync(fd, sizeBuf, 0, 4, dataOffset);
                    const dataSize = sizeBuf.readUInt32BE(0);

                    if (dataSize <= 0 || dataSize > 50000000) continue; // Skip abnormally large or zero-length

                    const rawData = Buffer.alloc(dataSize);
                    fs.readSync(fd, rawData, 0, dataSize, dataOffset + 4);

                    if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });

                    const name = getString(nameOff);
                    const cleanName = sanitizeFilename(name) || `${safeTag}_${id}`;
                    
                    let ext = '.bin';
                    if (['TEXT', 'STR ', 'STR#', 'scpt'].includes(typeEntry.tag)) ext = '.txt';

                    const outPath = path.join(targetDir, `${cleanName}${ext}`);
                    fs.writeFileSync(outPath, rawData);
                    extractedCount++;
                } catch (err) {
                    console.error(`Error processing ${typeEntry.tag} ID ${id} in ${filePath}:`, err.message);
                }
            }
            if (extractedCount > 0) {
                console.log(`  Finished generic extraction for ${typeEntry.tag}: Extracted ${extractedCount} items successfully.`);
            }
        }
    }

    fs.closeSync(fd);
}

async function runExtractor(drive, choice) {
    console.log(`Starting Unified CD Asset Extractor to: ${baseOutDir}`);

    globalPalette = getGlobalPalette(drive);

    if (choice === '1' || choice === '3') {
        console.log('Pre-scanning scene files for names...');
        sceneGroupNames = preScanSceneNames(drive);
        console.log(`Pre-scan complete. Found names for ${Object.keys(sceneGroupNames).length} groups.`);
    }

    if (choice === '1' || choice === '2') {
        console.log('\n=========================================');
        console.log('EXTRACTING CHARACTER SPRITES & AUDIO (ACTORS)');
        console.log('=========================================');
        await processRFFile(`${drive}:\\ACTORS1.RF`, 'actors');
        await processRFFile(`${drive}:\\ACTORS2.RF`, 'actors');
        await processRFFile(`${drive}:\\ACTORS3.RF`, 'actors');
        await processRFFile(`${drive}:\\ACTORS4.RF`, 'actors');
    }

    if (choice === '1' || choice === '3') {
        console.log('\n=========================================');
        console.log('EXTRACTING BACKGROUND IMAGES & AUDIO (SCENES)');
        console.log('=========================================');
        await processRFFile(`${drive}:\\SCENES1.RF`, 'scenes');
        await processRFFile(`${drive}:\\SCENES2.RF`, 'scenes');
        await processRFFile(`${drive}:\\SCENES3.RF`, 'scenes');
    }

    if (choice === '1' || choice === '4') {
        console.log('\n=========================================');
        console.log('EXTRACTING AUDIO TRACKS (SOUNDS)');
        console.log('=========================================');
        await processRFFile(`${drive}:\\SOUND1.RF`, 'sounds');
        await processRFFile(`${drive}:\\SOUND2.RF`, 'sounds');
        await processRFFile(`${drive}:\\SOUND3.RF`, 'sounds');
        await processRFFile(`${drive}:\\SOUND4.RF`, 'sounds');
        await processRFFile(`${drive}:\\SOUND5.RF`, 'sounds');
    }

    if (choice === '1' || choice === '5') {
        console.log('\n=========================================');
        console.log('EXTRACTING GENERIC ASSETS (MAIN)');
        console.log('=========================================');
        await processRFFile(`${drive}:\\MAIN.RF`, 'main');
    }

    console.log('\n======================================================');
    console.log(`Extraction complete! All assets placed in:\n${baseOutDir}`);
    console.log('======================================================');
}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

rl.question('Drive letter for Hollywood High CD-ROM (e.g., J): ', (driveLetter) => {
    driveLetter = driveLetter.trim().toUpperCase() || 'J';
    console.log('\nWhat would you like to extract?');
    console.log('  1. Everything (actors, scenes, sounds, main)');
    console.log('  2. Actors only');
    console.log('  3. Scenes only');
    console.log('  4. Sounds only');
    console.log('  5. Main assets only');
    rl.question('Choice [1-5]: ', (choice) => {
        choice = choice.trim();
        rl.close();
        if (!['1','2','3','4','5'].includes(choice)) {
            console.error('Invalid choice.');
            process.exit(1);
        }
        runExtractor(driveLetter, choice).catch(console.error);
    });
});