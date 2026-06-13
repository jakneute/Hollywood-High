const fs = require('fs');
const path = require('path');
const { Jimp } = require('jimp');
const readline = require('readline');

const baseOutDir = path.join(__dirname, 'extracted_assets');
const actorsDir = path.join(baseOutDir, 'actors');
const scenesDir = path.join(baseOutDir, 'scenes');
const soundsDir = path.join(baseOutDir, 'sounds');
const mainDir = path.join(baseOutDir, 'main');
const dumpDir = path.join(baseOutDir, 'dump');

[baseOutDir, actorsDir, scenesDir, soundsDir, mainDir, dumpDir].forEach(dir => {
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

const ACTOR_NAMES = {
    1: "Larry", 2: "Sid", 3: "Tiffanie", 4: "Artie", 5: "Charlotte",
    6: "Chuck", 7: "Billie", 8: "JJ", 9: "Bev", 10: "Lucille",
    11: "Gus", 12: "Lilly", 13: "Matt", 14: "Jenny", 15: "Susan",
    16: "Gary", 17: "Ruth", 18: "Glenn", 19: "Baby", 20: "Stella",
    21: "Anna", 22: "Ed"
};

// Per-ID overrides for poses misindexed on the original CD-ROM
const ACTOR_ID_OVERRIDES = {
    300:   "Charlotte",
    1000:  "Artie",    1002:  "Artie",    1003:  "Charlotte", 1106:  "Lucille",  1410:  "Artie",
    2000:  "Larry",    2002:  "Larry",    2003:  "Larry",     2101:  "Charlotte", 2103:  "Tiffanie",
    2106:  "Larry",    2530:  "Larry",
    3000:  "Sid",      3002:  "Sid",      3003:  "Sid",       3101:  "Sid",       3106:  "Charlotte",
    3151:  "Larry",    3460:  "Larry",    3526:  "Artie",
    4000:  "Tiffanie", 4002:  "Tiffanie", 4003:  "Tiffanie",  4101:  "Tiffanie",  4106:  "Tiffanie",
    4151:  "Tiffanie", 4304:  "Sid",      4401:  "Sid",       4410:  "Tiffanie",  4460:  "Tiffanie",
    4538:  "Charlotte",
    5000:  "Artie",    5002:  "Artie",    5003:  "Artie",     5101:  "Artie",     5106:  "Sid",
    5151:  "Artie",    5410:  "Artie",    5460:  "Artie",
    6000:  "Unknown",
    7000:  "Chuck",    7106:  "Charlotte",
    8000:  "Billie",
    9000:  "JJ",
    10000: "Bev",
    11000: "Jenny",    11002: "Matt",     11208: "Susan",
    12000: "Gus",      12002: "Susan",    12102: "Susan",     12517: "Gus",
    13000: "Lilly",
    14000: "Matt",     14002: "Gus",      14206: "Susan",     14500: "Lilly",
    15000: "Jenny",    15002: "Jenny",    15102: "Matt",      15109: "Jenny",
    16000: "Ruth",     16102: "Glenn",
    17000: "Gary",
    18000: "Ruth",     18473: "Gary",
    19002: "Anna",     19003: "Anna",     19004: "Stella",
    20000: "Baby",     20002: "Ed",       20430: "Ed",
    21000: "Stella",   21102: "Baby",     21495: "Stella",
    22002: "Anna",     22723: "Anna",
};

// Rerouting map to fix CD-ROM compilation index misalignments
const SCENE_REROUTES = {
    352: 52, 360: 35, 362: 47, 370: 36, 380: 37, 381: 40,
    390: 38, 410: 39, 420: 41, 432: 43, 440: 68, 450: 42,
    460: 45, 470: 44, 472: 49, 480: 46, 490: 48, 491: 38,
    500: 49, 501: 45, 510: 50, 511: 68, 531: 67, 532: 66,
    550: 58, 560: 67, 570: 59, 571: 55, 580: 62, 591: 54,
    600: 56, 610: 60, 620: 61, 630: 57, 632: 57, 640: 63,
};

const MANUAL_SCENE_NAMES = {
    15: "jungle", 29: "alley", 50: "music store",
    66: "silent movie", 67: "leaning tower", 68: "pyramid",
};

const SCENE_SOUND_MAPPING = {
    1519: "Art Gallery",         1518: "School Cafeteria",    1517: "Classroom_16",
    1511: "Car",                 1516: "Jungle",              1514: "Kitchen",
    1515: "Mad Scientist's Lab", 1513: "Auditorium",          1512: "Spaceship",
    1520: "Alien Planet",        1524: "Stadium",             1526: "Diner",
    1521: "Car",                 1522: "Dining Room",         1527: "Operating Room",
    1528: "Talk Show",           1525: "Messy Room",          1529: "News Room",
    1523: "Wild West Saloon",    1537: "Arcade",              1536: "Bathroom",
    1538: "Cafe",                1535: "Cheerleader's Gym",   1539: "Living Room Day",
    1547: "Dance Gym",           1541: "Garage",              1544: "Garage",
    1548: "Haunted House",       1540: "Living Room Night",   1545: "Locker",
    1549: "Movie Theater Lobby", 1543: "National Park",       1546: "The Burbs",
    1556: "Beach",               1550: "Bowling Alley",       1557: "Fast Food Counter",
    1555: "Classroom_60",        1551: "Clothing Store",      1558: "Orthodontist",
    1559: "Mall",                1554: "Leaning Tower",       1552: "Pyramid",
    1560: "Airplane",            1562: "Lookout Point",       1561: "City Street",
    1567: "Basketball Gym",      17567: "Basketball Gym"
};

let globalPalette = null;
let colorMappings = {};
let sceneGroupNames = {};
let sceneGroupCrops = {};
let sceneLabels = {};

function decompressPackBits(compressedBuffer) {
    const out = [];
    let inPtr = 0;
    while (inPtr < compressedBuffer.length) {
        const header = compressedBuffer.readInt8(inPtr++);
        if (header >= 0 && header <= 127) {
            const count = header + 1;
            for (let i = 0; i < count; i++) {
                if (inPtr < compressedBuffer.length) out.push(compressedBuffer[inPtr++]);
            }
        } else if (header >= -127 && header <= -1) {
            const count = 1 - header;
            if (inPtr < compressedBuffer.length) {
                const val = compressedBuffer[inPtr++];
                for (let i = 0; i < count; i++) out.push(val);
            }
        }
    }
    return Buffer.from(out);
}

function getGlobalPalette(drive) {
    const palettePath = `${drive}:\\ACTORS1.RF`;
    if (!fs.existsSync(palettePath)) throw new Error(`Palette file not found at ${palettePath}`);
    const fd = fs.openSync(palettePath, 'r');
    const palBuf = Buffer.alloc(2048);
    try {
        fs.readSync(fd, palBuf, 0, 2048, 11946359 + 8);
    } finally {
        fs.closeSync(fd);
    }
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

function sanitizeFilename(name) {
    if (!name) return '';
    return name.replace(/[\\/:*?"<>|]/g, '_').trim();
}

// Decode Macintosh 80-bit extended floats to standard sample rates
function decodeExtendedFloat(buf, offset = 0) {
    if (buf.length < offset + 10) return 22050;
    const exponent = buf.readUInt16BE(offset) & 0x7FFF;
    const mantissaHi = buf.readUInt32BE(offset + 2);
    const mantissaLo = buf.readUInt32BE(offset + 6);
    if (exponent === 0 && mantissaHi === 0 && mantissaLo === 0) return 0;
    const mantissaDouble = mantissaHi * Math.pow(2, -31) + mantissaLo * Math.pow(2, -63);
    const value = mantissaDouble * Math.pow(2, exponent - 16383);
    const rounded = Math.round(value);
    if (Math.abs(rounded - 22255) < 300) return 22050; // 22254 Hz Mac rate → 22050 Hz
    if (Math.abs(rounded - 11127) < 200) return 11025; // 11127 Hz Mac rate → 11025 Hz
    return rounded;
}

function writeWav(pcmData, sampleRate, bitDepth, outPath) {
    const byteRate = (sampleRate * bitDepth) / 8;
    const blockAlign = bitDepth / 8;
    const wavHeader = Buffer.alloc(44);
    wavHeader.write('RIFF', 0);
    wavHeader.writeUInt32LE(36 + pcmData.length, 4);
    wavHeader.write('WAVE', 8);
    wavHeader.write('fmt ', 12);
    wavHeader.writeUInt32LE(16, 16);
    wavHeader.writeUInt16LE(1, 20); // PCM
    wavHeader.writeUInt16LE(1, 22); // mono
    wavHeader.writeUInt32LE(sampleRate, 24);
    wavHeader.writeUInt32LE(byteRate, 28);
    wavHeader.writeUInt16LE(blockAlign, 32);
    wavHeader.writeUInt16LE(bitDepth, 34);
    wavHeader.write('data', 36);
    wavHeader.writeUInt32LE(pcmData.length, 40);
    fs.writeFileSync(outPath, Buffer.concat([wavHeader, pcmData]));
}

function formatFolderName(name) {
    if (!name) return '';
    let formatted = name;
    formatted = formatted.replace(/\s*\(\s*Day\s*\)/gi, " Day");
    formatted = formatted.replace(/\s*\(\s*Night\s*\)/gi, " Night");
    formatted = formatted.replace(/[();]/g, "");
    formatted = formatted.replace(/\s+/g, " ").trim();
    formatted = formatted.replace(/\b\w/g, (char, index, str) => {
        if (index > 0 && str[index - 1] === "'") return char.toLowerCase();
        return char.toUpperCase();
    });
    formatted = formatted.replace(/Cheerleaders.*?Gym/gi, "Cheerleader's Gym");
    formatted = formatted.replace(/Fastfood.*?Counter/gi, "Fast Food Counter");
    formatted = formatted.replace(/Burps/gi, "Burp's");
    formatted = formatted.replace(/Livingroom/gi, "Living Room");
    formatted = formatted.replace(/Wildwest.*?Saloon/gi, "Wild West Saloon");
    formatted = formatted.replace(/Cheerleader.*?Gym/gi, "Cheerleader's Gym");
    formatted = formatted.replace(/Scientist.*?Lab/gi, "Scientist's Lab");

    // Internal image TOC names → audio folder taxonomy
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

function readRFTOC(fd) {
    const header = Buffer.alloc(16);
    fs.readSync(fd, header, 0, 16, 0);
    const tocOffset = header.readUInt32BE(4);
    const tocSize = header.readUInt32BE(12);
    const tocBuffer = Buffer.alloc(tocSize);
    fs.readSync(fd, tocBuffer, 0, tocSize, tocOffset);
    const namesOffset = tocBuffer.readUInt16BE(26);
    const numTypes = tocBuffer.readUInt16BE(28) + 1;

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
    return { types, tocOffset, tocBuffer, namesOffset, getString };
}

function getExtensionForTag(tag, isDump) {
    if (['TEXT', 'STR ', 'STR#'].includes(tag)) return '.txt';
    if (tag === 'scpt') return isDump ? '.scpt' : '.txt';
    if (tag === 'PICT') return '.pict';
    if (['CURS', 'crsr'].includes(tag)) return '.cur';
    if (['ICN#', 'cicn', 'icon'].includes(tag)) return '.ico';
    const safeExt = tag.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
    return safeExt ? '.' + safeExt : '.bin';
}

function readImageResourceHeader(fd, dataOffset) {
    const sizeBuf = Buffer.alloc(48);
    fs.readSync(fd, sizeBuf, 0, 48, dataOffset);
    return {
        dataCompressedSize: sizeBuf.readUInt32BE(0),
        y_offset: sizeBuf.readUInt16BE(4),
        x_offset: sizeBuf.readUInt16BE(6),
        height: sizeBuf.readUInt16BE(8),
        width: sizeBuf.readUInt16BE(10)
    };
}

function readSoundResourceHeader(fd, dataOffset) {
    const sizeBuf = Buffer.alloc(48);
    fs.readSync(fd, sizeBuf, 0, 48, dataOffset);
    return { dataCompressedSize: sizeBuf.readUInt32BE(0) };
}

function readGenericResourceHeader(fd, dataOffset) {
    const sizeBuf = Buffer.alloc(4);
    fs.readSync(fd, sizeBuf, 0, 4, dataOffset);
    return { dataSize: sizeBuf.readUInt32BE(0) };
}

async function extractAndSaveImage(fd, {
    id, dataOffset, dataCompressedSize, width, height, x_offset, y_offset,
    isScene, activeRemap, outPath, cropInfo
}) {
    const compressedData = Buffer.alloc(dataCompressedSize);
    fs.readSync(fd, compressedData, 0, dataCompressedSize, dataOffset + 48);
    const decompressed = decompressPackBits(compressedData);

    let canvasWidth = width, canvasHeight = height, renderX = 0, renderY = 0;
    if (isScene) {
        canvasWidth = 500; canvasHeight = 250;
        renderX = x_offset; renderY = y_offset;
    }

    const image = new Jimp({ width: canvasWidth, height: canvasHeight });
    const rowBytes = Math.ceil(width / 4) * 4;
    let minX = canvasWidth, minY = canvasHeight, maxX = 0, maxY = 0;
    let hasVisiblePixels = false;

    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const srcIdx = y * rowBytes + x;
            if (srcIdx < decompressed.length) {
                const paletteIdx = decompressed[srcIdx];
                let color = globalPalette ? (globalPalette[paletteIdx] || { r: 0, g: 0, b: 0 }) : { r: 0, g: 0, b: 0 };
                if (activeRemap && activeRemap[paletteIdx] !== undefined) {
                    const mapped = activeRemap[paletteIdx].color;
                    color = { r: mapped[0], g: mapped[1], b: mapped[2] };
                }
                const destX = x + renderX, destY = y + renderY;
                if (destX >= 0 && destX < canvasWidth && destY >= 0 && destY < canvasHeight) {
                    const dataIdx = (destY * canvasWidth + destX) * 4;
                    if (paletteIdx === 255) {
                        image.bitmap.data.fill(0, dataIdx, dataIdx + 4);
                    } else {
                        image.bitmap.data[dataIdx] = color.r;
                        image.bitmap.data[dataIdx + 1] = color.g;
                        image.bitmap.data[dataIdx + 2] = color.b;
                        image.bitmap.data[dataIdx + 3] = 255;
                        if (!isScene) {
                            if (destX < minX) minX = destX;
                            if (destX > maxX) maxX = destX;
                            if (destY < minY) minY = destY;
                            if (destY > maxY) maxY = destY;
                            hasVisiblePixels = true;
                        }
                    }
                }
            }
        }
    }

    if (isScene) {
        if (cropInfo) {
            image.crop({ x: cropInfo.minX, y: cropInfo.minY, w: cropInfo.maxX - cropInfo.minX + 1, h: cropInfo.maxY - cropInfo.minY + 1 });
        }
    } else if (hasVisiblePixels) {
        const cropW = maxX - minX + 1, cropH = maxY - minY + 1;
        if (cropW > 0 && cropH > 0) image.crop({ x: minX, y: minY, w: cropW, h: cropH });
    }

    const pngBuf = await image.getBuffer('image/png');
    fs.writeFileSync(outPath, pngBuf);
}

function extractAndSaveSound(fd, { dataOffset, dataCompressedSize, outPath }) {
    const rawData = Buffer.alloc(dataCompressedSize - 48);
    fs.readSync(fd, rawData, 0, rawData.length, dataOffset + 48);
    const sampleRate = decodeExtendedFloat(rawData, 2);
    const sampleSize = rawData.length >= 26 ? rawData.readUInt16BE(24) : 16;
    const pcmBig = rawData.slice(40);
    let pcmData;
    if (sampleSize === 16) {
        pcmData = Buffer.alloc(pcmBig.length);
        for (let j = 0; j < pcmBig.length; j += 2) {
            if (j + 1 < pcmBig.length) pcmData.writeUInt16LE(pcmBig.readUInt16BE(j), j);
        }
    } else {
        pcmData = pcmBig;
    }
    writeWav(pcmData, sampleRate, sampleSize, outPath);
}

function extractAndSaveGeneric(fd, { dataOffset, dataSize, tag, getString, nameOff, id, targetDir, isDump }) {
    if (dataSize <= 0 || dataSize > 50000000) return false;
    const rawData = Buffer.alloc(dataSize);
    fs.readSync(fd, rawData, 0, dataSize, dataOffset + 4);
    if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });
    const name = getString(nameOff);
    const safeTag = sanitizeFilename(tag.trim()) || 'UNKNOWN';
    const cleanName = sanitizeFilename(name) || `${safeTag}_${id}`;
    const ext = getExtensionForTag(tag, isDump);
    fs.writeFileSync(path.join(targetDir, `${cleanName}${ext}`), rawData);
    return true;
}

function preScanSceneNames(drive) {
    const foundNames = {};
    const resourcesByGroup = {};
    const resourceMetadata = {};

    const sceneFiles = [
        `${drive}:\\SCENES1.RF`,
        `${drive}:\\SCENES2.RF`,
        `${drive}:\\SCENES3.RF`
    ];

    for (const filePath of sceneFiles) {
        if (!fs.existsSync(filePath)) continue;
        const fd = fs.openSync(filePath, 'r');
        const { types, getString, tocBuffer } = readRFTOC(fd);

        const typeEntry = types.find(t => t.tag === 'Im08');
        if (typeEntry) {
            const actualStart = 30 + typeEntry.typeOffset;
            for (let i = 0; i < typeEntry.count; i++) {
                const chunk = tocBuffer.slice(actualStart + i * 12, actualStart + i * 12 + 12);
                const nameOff = chunk.readUInt16BE(0);
                const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
                const id = chunk.readUInt16BE(10);
                const dataOffset = 256 + relativeOffset;
                const { y_offset, x_offset, height, width } = readImageResourceHeader(fd, dataOffset);

                resourceMetadata[id] = { file: filePath, offset: dataOffset, x_off: x_offset, y_off: y_offset, w: width, h: height };

                const cleanName = sanitizeFilename(getString(nameOff));
                const groupId = SCENE_REROUTES[id] !== undefined ? SCENE_REROUTES[id] : Math.floor(id / 10);
                if (cleanName) foundNames[groupId] = cleanName;
                if (!resourcesByGroup[groupId]) resourcesByGroup[groupId] = [];
                resourcesByGroup[groupId].push({ id, width, height, lastDigit: id % 10 });
            }
        }

        const typeEntrySCNE = types.find(t => t.tag === 'SCNE');
        if (typeEntrySCNE) {
            const actualStart = 30 + typeEntrySCNE.typeOffset;
            for (let i = 0; i < typeEntrySCNE.count; i++) {
                const chunk = tocBuffer.slice(actualStart + i * 12, actualStart + i * 12 + 12);
                const nameOff = chunk.readUInt16BE(0);
                const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
                const cleanName = sanitizeFilename(getString(nameOff));
                if (cleanName) {
                    const dataOffset = 256 + relativeOffset;
                    const scneData = Buffer.alloc(12);
                    fs.readSync(fd, scneData, 0, 12, dataOffset);
                    const scneImgGroupId = scneData.readUInt16BE(10);
                    if (scneImgGroupId > 0 && scneImgGroupId < 100) foundNames[scneImgGroupId] = cleanName;
                }
            }
        }

        fs.closeSync(fd);
    }

    // Assign background/foreground/mask labels based on visual layer heights (width >= 200)
    for (const groupId in resourcesByGroup) {
        const list = resourcesByGroup[groupId];
        const visualLayers = list.filter(r => r.width >= 200);
        if (visualLayers.length === 0) continue;

        const maxVisualHeight = Math.max(...visualLayers.map(v => v.height));
        const backgrounds = visualLayers.filter(v => v.height === maxVisualHeight);
        const overlays = visualLayers.filter(v => v.height < maxVisualHeight);
        overlays.sort((a, b) => {
            if (b.height !== a.height) return b.height - a.height;
            if (b.width !== a.width) return b.width - a.width;
            return a.lastDigit - b.lastDigit;
        });

        for (const bg of backgrounds) sceneLabels[bg.id] = 'background';
        if (overlays.length > 0) sceneLabels[overlays[0].id] = 'foreground';
        for (let i = 1; i < overlays.length; i++) {
            sceneLabels[overlays[i].id] = i === 1 ? 'mask' : `mask_${i}`;
        }
    }

    // Calculate group-wide crop bounds from background pixel data
    for (const groupId in resourcesByGroup) {
        const list = resourcesByGroup[groupId];
        const backgrounds = list.filter(r => sceneLabels[r.id] === 'background');
        let minX = 500, minY = 250, maxX = 0, maxY = 0, foundAny = false;

        for (const bgInfo of backgrounds) {
            const meta = resourceMetadata[bgInfo.id];
            if (!meta) continue;
            const fd = fs.openSync(meta.file, 'r');
            try {
                const sizeBuf = Buffer.alloc(4);
                fs.readSync(fd, sizeBuf, 0, 4, meta.offset);
                const dataCompressedSize = sizeBuf.readUInt32BE(0);
                const compressedData = Buffer.alloc(dataCompressedSize);
                fs.readSync(fd, compressedData, 0, dataCompressedSize, meta.offset + 48);
                const decompressed = decompressPackBits(compressedData);
                const rowBytes = Math.ceil(meta.w / 4) * 4;
                for (let y = 0; y < meta.h; y++) {
                    for (let x = 0; x < meta.w; x++) {
                        const srcIdx = y * rowBytes + x;
                        if (srcIdx < decompressed.length && decompressed[srcIdx] !== 255) {
                            const destX = x + meta.x_off, destY = y + meta.y_off;
                            if (destX >= 0 && destX < 500 && destY >= 0 && destY < 250) {
                                if (destX < minX) minX = destX;
                                if (destX > maxX) maxX = destX;
                                if (destY < minY) minY = destY;
                                if (destY > maxY) maxY = destY;
                                foundAny = true;
                            }
                        }
                    }
                }
            } finally {
                fs.closeSync(fd);
            }
        }
        if (foundAny) sceneGroupCrops[groupId] = { minX, minY, maxX, maxY };
    }

    // Resolve case-insensitive name collisions
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

    for (const id in MANUAL_SCENE_NAMES) foundNames[id] = MANUAL_SCENE_NAMES[id];
    return foundNames;
}

async function processImageExtraction(fd, types, filePath, mode, getString, tocOffset, tocBuffer) {
    const isActorFile = mode === 'actors';
    const isSceneFile = mode === 'scenes';
    const isMainFile = mode === 'main';

    const typeEntry = types.find(t => t.tag === 'Im08');
    if (!typeEntry) return;

    const actualStart = 30 + typeEntry.typeOffset;
    let extractedCount = 0;

    for (let i = 0; i < typeEntry.count; i++) {
        const chunk = tocBuffer.slice(actualStart + i * 12, actualStart + i * 12 + 12);
        const nameOff = chunk.readUInt16BE(0);
        const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
        const id = chunk.readUInt16BE(10);
        const dataOffset = 256 + relativeOffset;

        if (dataOffset >= tocOffset || dataOffset < 256) continue;

        try {
            const { dataCompressedSize, y_offset, x_offset, height, width } = readImageResourceHeader(fd, dataOffset);
            if (dataCompressedSize <= 0 || dataCompressedSize > 10000000) continue;
            if (width <= 0 || height <= 0 || width > 2000 || height > 2000) continue;
            if (isSceneFile && width < 200) continue; // Skip thumbnails

            let outPath = '';
            const activeRemap = colorMappings;

            if (isActorFile) {
                const characterName = ACTOR_ID_OVERRIDES[id] || ACTOR_NAMES[Math.floor(id / 1000)] || "Unknown";
                const characterDir = path.join(actorsDir, characterName);
                if (!fs.existsSync(characterDir)) fs.mkdirSync(characterDir, { recursive: true });
                outPath = path.join(characterDir, `pose_${id}.png`);
            } else if (isSceneFile) {
                const groupId = SCENE_REROUTES[id] !== undefined ? SCENE_REROUTES[id] : Math.floor(id / 10);
                const lastDigit = id % 10;
                let groupName = MANUAL_SCENE_NAMES[groupId] || sceneGroupNames[groupId] || `scene_group_${groupId}`;
                groupName = formatFolderName(groupName);
                let typeSuffix = sceneLabels[id] || '';
                if (!typeSuffix) {
                    if (lastDigit === 0) typeSuffix = 'walkmask';
                    else if (lastDigit === 1) typeSuffix = 'background';
                    else if (lastDigit === 2) typeSuffix = 'foreground';
                    else if (lastDigit === 3) typeSuffix = 'mask';
                    else typeSuffix = 'unknown';
                }
                const sceneSpecificDir = path.join(scenesDir, groupName);
                if (!fs.existsSync(sceneSpecificDir)) fs.mkdirSync(sceneSpecificDir, { recursive: true });
                outPath = path.join(sceneSpecificDir, `${groupName}_${typeSuffix}_${id}.png`);
            } else if (isMainFile) {
                const outImgDir = path.join(mainDir, 'images');
                if (!fs.existsSync(outImgDir)) fs.mkdirSync(outImgDir, { recursive: true });
                const cleanName = sanitizeFilename(getString(nameOff)) || `image_${id}`;
                outPath = path.join(outImgDir, `${cleanName}.png`);
            }

            const groupId = SCENE_REROUTES[id] !== undefined ? SCENE_REROUTES[id] : Math.floor(id / 10);
            const cropInfo = isSceneFile ? sceneGroupCrops[groupId] : null;

            await extractAndSaveImage(fd, {
                id, dataOffset, dataCompressedSize, width, height, x_offset, y_offset,
                isScene: isSceneFile, activeRemap, outPath, cropInfo
            });
            extractedCount++;
        } catch (err) {
            console.error(`Error processing image ID ${id} in ${filePath}:`, err.message);
        }

        if (i > 0 && i % 250 === 0) console.log(`    Processed ${i}/${typeEntry.count} images...`);
    }
    console.log(`  Finished image extraction for ${filePath}: Extracted ${extractedCount} items successfully.`);
}

async function processSoundExtraction(fd, types, filePath, mode, getString, tocOffset, tocBuffer) {
    const isActorFile = mode === 'actors';
    const isSceneFile = mode === 'scenes';
    const isMainFile = mode === 'main';

    const typeEntry = types.find(t => t.tag === 'snd ');
    if (!typeEntry) return;

    const actualStart = 30 + typeEntry.typeOffset;
    let extractedCount = 0;

    for (let i = 0; i < typeEntry.count; i++) {
        const chunk = tocBuffer.slice(actualStart + i * 12, actualStart + i * 12 + 12);
        const nameOff = chunk.readUInt16BE(0);
        const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
        const id = chunk.readUInt16BE(10);
        const dataOffset = 256 + relativeOffset;

        if (dataOffset >= tocOffset || dataOffset < 256) continue;

        try {
            const { dataCompressedSize } = readSoundResourceHeader(fd, dataOffset);
            if (dataCompressedSize <= 48) continue;

            const cleanName = sanitizeFilename(getString(nameOff));
            let targetDir = soundsDir;

            if (isActorFile) {
                const characterName = ACTOR_ID_OVERRIDES[id] || ACTOR_NAMES[Math.floor(id / 1000)] || "Unknown";
                targetDir = path.join(actorsDir, characterName, 'audio');
            } else if (isSceneFile) {
                let groupName = SCENE_SOUND_MAPPING[id];
                if (!groupName) {
                    const groupId = SCENE_REROUTES[id] !== undefined ? SCENE_REROUTES[id] : Math.floor(id / 10);
                    groupName = MANUAL_SCENE_NAMES[groupId] || sceneGroupNames[groupId] || `scene_group_${groupId}`;
                }
                groupName = formatFolderName(groupName);
                targetDir = path.join(scenesDir, groupName);
            } else if (isMainFile) {
                targetDir = path.join(mainDir, 'sounds');
            }

            if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });
            const soundFilename = cleanName ? `${cleanName}_${id}.wav` : `sound_${id}.wav`;
            extractAndSaveSound(fd, { dataOffset, dataCompressedSize, outPath: path.join(targetDir, soundFilename) });
            extractedCount++;
        } catch (err) {
            console.error(`Error processing sound ID ${id} in ${filePath}:`, err.message);
        }

        if (i > 0 && i % 250 === 0) console.log(`    Processed ${i}/${typeEntry.count} sounds...`);
    }
    console.log(`  Finished sound extraction for ${filePath}: Extracted ${extractedCount} items successfully.`);
}

async function processGenericExtraction(fd, types, filePath, getString, tocOffset, tocBuffer) {
    for (const typeEntry of types) {
        if (typeEntry.tag === 'Im08' || typeEntry.tag === 'snd ') continue;

        const actualStart = 30 + typeEntry.typeOffset;
        let extractedCount = 0;
        const safeTag = sanitizeFilename(typeEntry.tag.trim()) || 'UNKNOWN';
        const targetDir = path.join(mainDir, safeTag);

        for (let i = 0; i < typeEntry.count; i++) {
            const chunk = tocBuffer.slice(actualStart + i * 12, actualStart + i * 12 + 12);
            const nameOff = chunk.readUInt16BE(0);
            const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
            const id = chunk.readUInt16BE(10);
            const dataOffset = 256 + relativeOffset;

            if (dataOffset >= tocOffset || dataOffset < 256) continue;

            try {
                const { dataSize } = readGenericResourceHeader(fd, dataOffset);
                const saved = extractAndSaveGeneric(fd, {
                    dataOffset, dataSize, tag: typeEntry.tag, getString, nameOff, id, targetDir, isDump: false
                });
                if (saved) extractedCount++;
            } catch (err) {
                console.error(`Error processing ${typeEntry.tag} ID ${id} in ${filePath}:`, err.message);
            }
        }
        if (extractedCount > 0) console.log(`  Finished generic extraction for ${typeEntry.tag}: Extracted ${extractedCount} items successfully.`);
    }
}

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

async function processRFFile(filePath, mode) {
    if (!fs.existsSync(filePath)) {
        console.log(`Skipping missing file: ${filePath}`);
        return;
    }
    console.log(`\nProcessing ${filePath}...`);
    const fd = fs.openSync(filePath, 'r');
    const { types, getString, tocOffset, tocBuffer } = readRFTOC(fd);
    try {
        if (mode === 'actors' || mode === 'scenes' || mode === 'main') {
            await processImageExtraction(fd, types, filePath, mode, getString, tocOffset, tocBuffer);
        }
        if (mode === 'sounds' || mode === 'actors' || mode === 'scenes' || mode === 'main') {
            await processSoundExtraction(fd, types, filePath, mode, getString, tocOffset, tocBuffer);
        }
        if (mode === 'main') {
            await processGenericExtraction(fd, types, filePath, getString, tocOffset, tocBuffer);
        }
    } finally {
        fs.closeSync(fd);
    }
}

async function dumpRFFile(filePath) {
    if (!fs.existsSync(filePath)) {
        console.log(`Skipping missing file: ${filePath}`);
        return;
    }
    const filename = path.basename(filePath);
    console.log(`\nDumping ${filename}...`);
    const fd = fs.openSync(filePath, 'r');
    const { types, getString, tocOffset, tocBuffer } = readRFTOC(fd);
    const fileOutDir = path.join(dumpDir, sanitizeFilename(filename));
    const isSceneDump = filename.toUpperCase().startsWith('SCENES');

    try {
        for (const typeEntry of types) {
            const actualStart = 30 + typeEntry.typeOffset;
            let extractedCount = 0;
            const safeTag = sanitizeFilename(typeEntry.tag.trim()) || 'UNKNOWN';
            const targetDir = path.join(fileOutDir, safeTag);

            for (let i = 0; i < typeEntry.count; i++) {
                const chunk = tocBuffer.slice(actualStart + i * 12, actualStart + i * 12 + 12);
                const nameOff = chunk.readUInt16BE(0);
                const relativeOffset = chunk.readUInt32BE(2) & 0x00FFFFFF;
                const id = chunk.readUInt16BE(10);
                const dataOffset = 256 + relativeOffset;

                if (dataOffset >= tocOffset || dataOffset < 256) continue;

                try {
                    if (typeEntry.tag === 'Im08') {
                        const { dataCompressedSize, y_offset, x_offset, height, width } = readImageResourceHeader(fd, dataOffset);
                        if (dataCompressedSize <= 0 || dataCompressedSize > 50000000) continue;
                        if (width <= 0 || height <= 0 || width > 2000 || height > 2000) continue;
                        if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });
                        const cleanName = sanitizeFilename(getString(nameOff)) || `${safeTag}_${id}`;
                        const groupId = SCENE_REROUTES[id] !== undefined ? SCENE_REROUTES[id] : Math.floor(id / 10);
                        await extractAndSaveImage(fd, {
                            id, dataOffset, dataCompressedSize, width, height, x_offset, y_offset,
                            isScene: isSceneDump, activeRemap: null,
                            outPath: path.join(targetDir, `${cleanName}.png`),
                            cropInfo: isSceneDump ? sceneGroupCrops[groupId] : null
                        });
                        extractedCount++;
                    } else if (typeEntry.tag === 'snd ') {
                        const { dataCompressedSize } = readSoundResourceHeader(fd, dataOffset);
                        if (dataCompressedSize <= 48) continue;
                        if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });
                        const cleanName = sanitizeFilename(getString(nameOff)) || `${safeTag}_${id}`;
                        extractAndSaveSound(fd, { dataOffset, dataCompressedSize, outPath: path.join(targetDir, `${cleanName}.wav`) });
                        extractedCount++;
                    } else {
                        const { dataSize } = readGenericResourceHeader(fd, dataOffset);
                        const saved = extractAndSaveGeneric(fd, {
                            dataOffset, dataSize, tag: typeEntry.tag, getString, nameOff, id, targetDir, isDump: true
                        });
                        if (saved) extractedCount++;
                    }
                } catch (err) {
                    console.error(`Error dumping ${typeEntry.tag} ID ${id} in ${filename}:`, err.message);
                }
            }
            if (extractedCount > 0) console.log(`  Dumped ${extractedCount} items for tag: ${typeEntry.tag}`);
        }
    } finally {
        fs.closeSync(fd);
    }
}

async function runExtractor(drive, choice) {
    console.log(`Starting Unified CD Asset Extractor to: ${baseOutDir}`);
    try {
        globalPalette = getGlobalPalette(drive);
    } catch (err) {
        console.warn('Warning: Could not load global palette. Images may not extract correctly.', err.message);
    }

    if (choice === '6') {
        console.log('\nPERFORMING FULL RAW BINARY DUMP');
        const driveRoot = `${drive}:\\`;
        try {
            if (fs.existsSync(driveRoot)) {
                const files = fs.readdirSync(driveRoot).filter(f => f.toUpperCase().endsWith('.RF'));
                for (const file of files) await dumpRFFile(path.join(driveRoot, file));
            } else {
                console.log(`Could not read drive root: ${driveRoot}`);
            }
        } catch (err) {
            console.log(`Error reading drive: ${err.message}`);
        }
        console.log(`\nDump complete: ${dumpDir}`);
        return;
    }

    if (choice === '1' || choice === '3') {
        console.log('Pre-scanning scene files for names...');
        sceneGroupNames = preScanSceneNames(drive);
        console.log(`Pre-scan complete. Found names for ${Object.keys(sceneGroupNames).length} groups.`);
    }

    if (choice === '1' || choice === '2') {
        console.log('\nEXTRACTING CHARACTER SPRITES & AUDIO (ACTORS)');
        await processRFFile(`${drive}:\\ACTORS1.RF`, 'actors');
        await processRFFile(`${drive}:\\ACTORS2.RF`, 'actors');
        await processRFFile(`${drive}:\\ACTORS3.RF`, 'actors');
        await processRFFile(`${drive}:\\ACTORS4.RF`, 'actors');
    }

    if (choice === '1' || choice === '3') {
        console.log('\nEXTRACTING BACKGROUND IMAGES & AUDIO (SCENES)');
        await processRFFile(`${drive}:\\SCENES1.RF`, 'scenes');
        await processRFFile(`${drive}:\\SCENES2.RF`, 'scenes');
        await processRFFile(`${drive}:\\SCENES3.RF`, 'scenes');
    }

    if (choice === '1' || choice === '4') {
        console.log('\nEXTRACTING AUDIO TRACKS (SOUNDS)');
        await processRFFile(`${drive}:\\SOUND1.RF`, 'sounds');
        await processRFFile(`${drive}:\\SOUND2.RF`, 'sounds');
        await processRFFile(`${drive}:\\SOUND3.RF`, 'sounds');
        await processRFFile(`${drive}:\\SOUND4.RF`, 'sounds');
        await processRFFile(`${drive}:\\SOUND5.RF`, 'sounds');
    }

    if (choice === '1' || choice === '5') {
        console.log('\nEXTRACTING GENERIC ASSETS (MAIN)');
        await processRFFile(`${drive}:\\MAIN.RF`, 'main');
    }

    console.log(`\nExtraction complete: ${baseOutDir}`);
}

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
rl.question('Drive letter for Hollywood High CD-ROM (e.g., J): ', (driveLetter) => {
    driveLetter = driveLetter.trim().toUpperCase() || 'J';
    console.log('\nWhat would you like to extract?');
    console.log('  1. Everything (actors, scenes, sounds, main)');
    console.log('  2. Actors only');
    console.log('  3. Scenes only');
    console.log('  4. Sounds only');
    console.log('  5. Main assets only');
    console.log('  6. Full RAW Binary Dump (All .RF files)');
    rl.question('Choice [1-6]: ', (choice) => {
        choice = choice.trim();
        rl.close();
        if (!['1', '2', '3', '4', '5', '6'].includes(choice)) {
            console.error('Invalid choice.');
            process.exit(1);
        }
        runExtractor(driveLetter, choice).catch(console.error);
    });
});
