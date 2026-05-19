const fs = require('fs');
const path = require('path');
const { Jimp } = require('jimp');
const readline = require('readline');

// Create output folders if they don't exist
const baseOutDir = path.join(__dirname, 'extracted_assets');
const actorsDir = path.join(baseOutDir, 'actors');
const scenesDir = path.join(baseOutDir, 'scenes');
const soundsDir = path.join(baseOutDir, 'sounds');

[baseOutDir, actorsDir, scenesDir, soundsDir].forEach(dir => {
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

let globalPalette = null;
let colorMappings = {};

// Load JSON color mappings safely
const mappingPath = path.join(__dirname, 'character_color_mappings.json');
if (fs.existsSync(mappingPath)) {
    try {
        colorMappings = JSON.parse(fs.readFileSync(mappingPath, 'utf8'));
        console.log('Successfully loaded character color mappings.');
    } catch (e) {
        console.error('Error reading character_color_mappings.json:', e);
    }
} else {
    console.log('Warning: character_color_mappings.json not found. Using default palette.');
}

// Parse and extract from an RF file
async function processRFFile(filePath, isActorFile, isSceneFile, isSoundFile) {
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
    if (isActorFile || isSceneFile) {
        const targetTag = 'Im08';
        const typeEntry = types.find(t => t.tag === targetTag);
        if (typeEntry) {
            const actualStart = 30 + typeEntry.typeOffset;
            const entrySize = 12;
            let extractedCount = 0;
            
            const actrNames = {
                1: "Larry", 2: "Sid", 3: "Tiffanie", 4: "Artie", 5: "Charlotte",
                6: "Chuck", 7: "Billie", 8: "JJ", 9: "Bev", 10: "Lucille",
                11: "Gus", 12: "Lilly", 13: "Matt", 14: "Jenny", 15: "Susan",
                16: "Gary", 17: "Ruth", 18: "Glenn", 19: "Baby", 20: "Stella",
                21: "Anna", 22: "Ed"
            };

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
                    
                    const bottom = sizeBuf.readUInt16BE(8);
                    const right = sizeBuf.readUInt16BE(10);
                    
                    let width = right;
                    let height = bottom;
                    
                    if (width <= 0 || height <= 0 || right > 2000 || bottom > 2000) continue;
                    
                    let rowBytes = Math.ceil(right / 4) * 4;
                    
                    let outPath = '';
                    let activeRemap = null;

                    if (isActorFile) {
                        const charRouteId = Math.floor(id / 1000);
                        const characterName = actrNames[charRouteId] || "Unknown";
                        const actorGroupDir = path.join(actorsDir, characterName);
                        if (!fs.existsSync(actorGroupDir)) {
                            fs.mkdirSync(actorGroupDir, { recursive: true });
                        }
                        outPath = path.join(actorGroupDir, `pose_${id}.png`);
                        activeRemap = colorMappings[characterName] || null;
                    } else {
                        const name = getString(nameOff);
                        const cleanName = sanitizeFilename(name);
                        const sceneName = cleanName ? `${cleanName}_${id}.png` : `scene_${id}.png`;
                        outPath = path.join(scenesDir, sceneName);
                    }

                    const compressedData = Buffer.alloc(dataCompressedSize);
                    fs.readSync(fd, compressedData, 0, dataCompressedSize, dataOffset + 48);
                    
                    const decompressed = decompressPackBits(compressedData);
                    
                    const image = new Jimp({ width, height });
                    
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
                               
                                const dataIdx = (y * width + x) * 4;
                                if (paletteIdx === 255 || paletteIdx === 0) {
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
                    
                    let pngBuf;
                    if (typeof image.getBufferAsync === 'function') {
                        pngBuf = await image.getBufferAsync('image/png');
                    } else {
                        pngBuf = await image.getBuffer('image/png');
                    }
                    
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
    if (isSoundFile) {
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
                    const soundFilename = cleanName ? `${cleanName}_${id}.wav` : `sound_${id}.wav`;
                    const outPath = path.join(soundsDir, soundFilename);
                    
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
    
    fs.closeSync(fd);
}

async function runExtractor(drive) {
    console.log(`Starting Unified CD Asset Extractor to: ${baseOutDir}`);
    
    globalPalette = getGlobalPalette(drive);
    
    // 1. Process Actor Files
    console.log('\n=========================================');
    console.log('EXTRACTING CHARACTER SPRITES (ACTORS)');
    console.log('=========================================');
    await processRFFile(`${drive}:\\ACTORS1.RF`, true, false, false);
    await processRFFile(`${drive}:\\ACTORS2.RF`, true, false, false);
    await processRFFile(`${drive}:\\ACTORS3.RF`, true, false, false);
    await processRFFile(`${drive}:\\ACTORS4.RF`, true, false, false);

    // 2. Process Scene Files
    console.log('\n=========================================');
    console.log('EXTRACTING BACKGROUND IMAGES (SCENES)');
    console.log('=========================================');
    await processRFFile(`${drive}:\\SCENES1.RF`, false, true, false);
    await processRFFile(`${drive}:\\SCENES2.RF`, false, true, false);
    await processRFFile(`${drive}:\\SCENES3.RF`, false, true, false);

    // 3. Process Sound Files
    console.log('\n=========================================');
    console.log('EXTRACTING AUDIO TRACKS (SOUNDS)');
    console.log('=========================================');
    await processRFFile(`${drive}:\\SOUND1.RF`, false, false, true);
    await processRFFile(`${drive}:\\SOUND2.RF`, false, false, true);
    await processRFFile(`${drive}:\\SOUND3.RF`, false, false, true);
    await processRFFile(`${drive}:\\SOUND4.RF`, false, false, true);
    await processRFFile(`${drive}:\\SOUND5.RF`, false, false, true);
    
    // Check if there are also dialogue sounds inside scene files
    await processRFFile(`${drive}:\\SCENES1.RF`, false, false, true);
    await processRFFile(`${drive}:\\SCENES2.RF`, false, false, true);
    await processRFFile(`${drive}:\\SCENES3.RF`, false, false, true);

    console.log('\n======================================================');
    console.log(`Extraction complete! All assets placed in:\n${baseOutDir}`);
    console.log('======================================================');
}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

rl.question('Please enter the drive letter for the Hollywood High CD-ROM (e.g., J): ', (driveLetter) => {
    driveLetter = driveLetter.trim().toUpperCase() || 'J';
    rl.close();
    runExtractor(driveLetter).catch(console.error);
});