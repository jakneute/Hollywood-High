const fs = require('fs');
const path = require('path');
const { Jimp } = require('jimp');
const readline = require('readline');

// Load color mappings FIRST to build the folder structure
const mappingPath = path.join(__dirname, 'color_mappings.json');
let colorMappings = {};
if (fs.existsSync(mappingPath)) {
    try {
        colorMappings = JSON.parse(fs.readFileSync(mappingPath, 'utf8'));
    } catch (e) {
        console.error('Error reading color_mappings.json:', e);
        process.exit(1);
    }
} else {
    console.error('Error: color_mappings.json not found!');
    process.exit(1);
}

const characters = Object.keys(colorMappings);
if (characters.length === 0) {
    console.error('No characters found in color_mappings.json');
    process.exit(1);
}

const testImagesDir = path.join(__dirname, 'test_images');
const outImagesDir = path.join(testImagesDir, '_output');

let createdNewDirs = false;
if (!fs.existsSync(testImagesDir)) {
    fs.mkdirSync(testImagesDir, { recursive: true });
    createdNewDirs = true;
}

// Ensure character subfolders exist
characters.forEach(char => {
    const charDir = path.join(testImagesDir, char);
    if (!fs.existsSync(charDir)) {
        fs.mkdirSync(charDir, { recursive: true });
        createdNewDirs = true;
    }
});

if (createdNewDirs) {
    console.log(`Created missing character directories in: ${testImagesDir}`);
}

const filesByCharacter = {};
let totalFiles = 0;
characters.forEach(char => {
    const charDir = path.join(testImagesDir, char);
    if (fs.existsSync(charDir)) {
        const files = fs.readdirSync(charDir).filter(f => f.toLowerCase().endsWith('.png'));
        if (files.length > 0) {
            filesByCharacter[char] = files;
            totalFiles += files.length;
        }
    }
});

if (totalFiles === 0) {
    console.log(`No PNG files found in any character subfolders inside ${testImagesDir}`);
    console.log('Please place PNG images in their respective character subfolders and run the script again.');
    process.exit(0);
}

if (!fs.existsSync(outImagesDir)) {
    fs.mkdirSync(outImagesDir, { recursive: true });
}

// PackBits Decompressor
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

// Fetch EXACT raw image from CD-ROM via ID
function getImageDataFromCD(drive, targetId) {
    const rfFiles = ['ACTORS1.RF', 'ACTORS2.RF', 'ACTORS3.RF', 'ACTORS4.RF', 'SCENES1.RF', 'SCENES2.RF', 'SCENES3.RF'];
    for (const file of rfFiles) {
        const filePath = `${drive}:\\${file}`;
        if (!fs.existsSync(filePath)) continue;

        const fd = fs.openSync(filePath, 'r');
        const header = Buffer.alloc(16);
        fs.readSync(fd, header, 0, 16, 0);

        const tocOffset = header.readUInt32BE(4);
        const tocSize = header.readUInt32BE(12);

        const tocBuffer = Buffer.alloc(tocSize);
        fs.readSync(fd, tocBuffer, 0, tocSize, tocOffset);

        const numTypesMinus1 = tocBuffer.readUInt16BE(28);
        const numTypes = numTypesMinus1 + 1;

        let offsetInTOC = 30;
        let im08Type = null;
        for (let i = 0; i < numTypes; i++) {
            const tag = tocBuffer.slice(offsetInTOC, offsetInTOC + 4).toString('ascii');
            const count = tocBuffer.readUInt16BE(offsetInTOC + 4);
            const typeOffset = tocBuffer.readUInt16BE(offsetInTOC + 6);
            if (tag === 'Im08') { im08Type = { count, typeOffset }; break; }
            offsetInTOC += 8;
        }

        if (im08Type) {
            const actualStart = 30 + im08Type.typeOffset;
            const entrySize = 12;
            for (let i = 0; i < im08Type.count; i++) {
                const entryOffset = actualStart + i * entrySize;
                const relativeOffset = tocBuffer.readUInt32BE(entryOffset + 2) & 0x00FFFFFF;
                const id = tocBuffer.readUInt16BE(entryOffset + 10);

                if (id === targetId) {
                    const dataOffset = 256 + relativeOffset;
                    if (dataOffset >= tocOffset || dataOffset < 256) continue;
                    const sizeBuf = Buffer.alloc(48);
                    fs.readSync(fd, sizeBuf, 0, 48, dataOffset);
                    const dataCompressedSize = sizeBuf.readUInt32BE(0);
                    if (dataCompressedSize <= 0 || dataCompressedSize > 10000000) { fs.closeSync(fd); return null; }
                    const height = sizeBuf.readUInt16BE(8);
                    const width = sizeBuf.readUInt16BE(10);
                    if (width <= 0 || height <= 0 || width > 2000 || height > 2000) { fs.closeSync(fd); return null; }
                    const compressedData = Buffer.alloc(dataCompressedSize);
                    fs.readSync(fd, compressedData, 0, dataCompressedSize, dataOffset + 48);
                    const decompressed = decompressPackBits(compressedData);
                    fs.closeSync(fd);
                    return { width, height, decompressed, sourceFile: file };
                }
            }
        }
        fs.closeSync(fd);
    }
    return null;
}

// Extract Global Palette
function getGlobalPalette(drive) {
    const actorFiles = ['ACTORS1.RF', 'ACTORS2.RF', 'ACTORS3.RF', 'ACTORS4.RF'];
    let palettePath = null;

    for (const file of actorFiles) {
        const checkPath = `${drive}:\\${file}`;
        if (fs.existsSync(checkPath)) {
            palettePath = checkPath;
            break;
        }
    }

    if (!palettePath) {
        throw new Error(`No ACTORS files found on drive ${drive}:\\ to read palette.`);
    }

    const fd = fs.openSync(palettePath, 'r');
    const palBuf = Buffer.alloc(2048);
    try {
        fs.readSync(fd, palBuf, 0, 2048, 11946359 + 8);
    } catch (e) {
        console.warn(`Warning: Failed to read palette at expected offset in ${palettePath}.`);
    }
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

// Properly polyfill Jimp buffer resolution for older and newer versions
async function getBufferPromise(img, mime = 'image/png') {
    if (typeof img.getBufferAsync === 'function') {
        return await img.getBufferAsync(mime);
    }
    try {
        const res = img.getBuffer(mime);
        if (res && typeof res.then === 'function') return await res;
        if (Buffer.isBuffer(res)) return res;
    } catch (e) {
        // Ignore and fall back to callback method
    }
    return new Promise((resolve, reject) => {
        img.getBuffer(mime, (err, buffer) => {
            if (err) reject(err);
            else resolve(buffer);
        });
    });
}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

rl.question('Drive letter for Hollywood High CD-ROM to read global palette (e.g., J): ', async (driveLetter) => {
    driveLetter = driveLetter.trim().toUpperCase() || 'J';
    
    let globalPalette;
    try {
        globalPalette = getGlobalPalette(driveLetter);
        console.log('Successfully loaded global palette from CD-ROM.');
    } catch (err) {
        console.error(err.message);
        rl.close();
        process.exit(1);
    }

        // Build RGB to indices map (handles instances where the 8-bit palette contains duplicate RGB values)
        const rgbToIndices = {};
        for (let i = 0; i < 256; i++) {
            const c = globalPalette[i];
            const key = `${c.r},${c.g},${c.b}`;
            if (!rgbToIndices[key]) rgbToIndices[key] = [];
            rgbToIndices[key].push(i);
        }

        for (const selectedCharacter of characters) {
            const files = filesByCharacter[selectedCharacter];
            if (!files || files.length === 0) continue;

            const activeRemap = colorMappings[selectedCharacter] || {};
            console.log(`\nApplying palette for ${selectedCharacter}...`);

            const charOutDir = path.join(outImagesDir, selectedCharacter);
            if (!fs.existsSync(charOutDir)) {
                fs.mkdirSync(charOutDir, { recursive: true });
            }

        for (const file of files) {
            const inPath = path.join(testImagesDir, selectedCharacter, file);
            const ext = path.extname(file);
            const outPath = path.join(charOutDir, file);
            console.log(`Processing ${file}...`);

            try {
                let imageCorrected;
                
                const match = file.match(/(\d+)\.png$/i);
                let cdData = null;
                if (match) {
                    const targetId = parseInt(match[1], 10);
                    console.log(`  -> Detected ID ${targetId} in filename. Fetching exactly from CD-ROM...`);
                    cdData = getImageDataFromCD(driveLetter, targetId);
                }

                if (cdData) {
                    const width = cdData.width;
                    const height = cdData.height;
                    const rowBytes = Math.ceil(width / 4) * 4;
                    
                    imageCorrected = new Jimp({ width, height });
                    
                    for (let y = 0; y < height; y++) {
                        for (let x = 0; x < width; x++) {
                            const srcIdx = y * rowBytes + x;
                            if (srcIdx < cdData.decompressed.length) {
                                const paletteIdx = cdData.decompressed[srcIdx];
                                
                                if (paletteIdx === 255) continue; // Always transparent

                                const origColor = globalPalette[paletteIdx] || { r: 0, g: 0, b: 0 };
                                let mappedRGB = null;
                                
                                if (activeRemap[paletteIdx] !== undefined) {
                                    mappedRGB = activeRemap[paletteIdx].color;
                                }

                                const dataIdx = (y * width + x) * 4;

                                // Corrected Image
                                if (mappedRGB) {
                                    imageCorrected.bitmap.data[dataIdx] = mappedRGB[0];
                                    imageCorrected.bitmap.data[dataIdx + 1] = mappedRGB[1];
                                    imageCorrected.bitmap.data[dataIdx + 2] = mappedRGB[2];
                                } else {
                                    imageCorrected.bitmap.data[dataIdx] = origColor.r;
                                    imageCorrected.bitmap.data[dataIdx + 1] = origColor.g;
                                    imageCorrected.bitmap.data[dataIdx + 2] = origColor.b;
                                }
                                imageCorrected.bitmap.data[dataIdx + 3] = 255;
                            }
                        }
                    }
                    
                    const pngBufCorrected = await getBufferPromise(imageCorrected);
                    fs.writeFileSync(outPath, pngBufCorrected);

                } else {
                    if (match) {
                        console.log(`  -> ID ${match[1]} not found on CD-ROM. Falling back to RGB reverse-lookup...`);
                    }
                    imageCorrected = await Jimp.read(inPath);
                    
                    // Scan pixels and replace colors (RGB Reverse-Lookup Fallback)
                    for (let y = 0; y < imageCorrected.bitmap.height; y++) {
                        for (let x = 0; x < imageCorrected.bitmap.width; x++) {
                            const dataIdx = (y * imageCorrected.bitmap.width + x) * 4;
                            const r = imageCorrected.bitmap.data[dataIdx];
                            const g = imageCorrected.bitmap.data[dataIdx + 1];
                            const b = imageCorrected.bitmap.data[dataIdx + 2];
                            const a = imageCorrected.bitmap.data[dataIdx + 3];

                            if (a === 0) continue; 

                            const key = `${r},${g},${b}`;
                            const possibleIndices = rgbToIndices[key];

                            let mappedRGB = null;

                            if (possibleIndices) {
                                for (const idx of possibleIndices) {
                                    if (activeRemap[idx] !== undefined) {
                                        mappedRGB = activeRemap[idx].color;
                                        break; 
                                    }
                                }
                            }

                            if (mappedRGB) {
                                imageCorrected.bitmap.data[dataIdx] = mappedRGB[0];
                                imageCorrected.bitmap.data[dataIdx + 1] = mappedRGB[1];
                                imageCorrected.bitmap.data[dataIdx + 2] = mappedRGB[2];
                            }
                        }
                    }
                    const pngBuf = await getBufferPromise(imageCorrected);
                    fs.writeFileSync(outPath, pngBuf);
                }
            } catch (err) {
                console.error(`Error processing ${file}:`, err.message);
            }
        }
        }

        console.log(`\nDone! All modified images saved to:\n${outImagesDir}`);
        rl.close();
});