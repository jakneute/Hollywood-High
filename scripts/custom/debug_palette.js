const fs = require('fs');
const path = require('path');
const { Jimp } = require('jimp');
const readline = require('readline');

const outDir = path.join(__dirname, 'debug_output');
if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
}

// Load JSON color mappings safely
const mappingPath = path.join(__dirname, 'color_mappings.json');
let colorMappings = {};
if (fs.existsSync(mappingPath)) {
    try {
        colorMappings = JSON.parse(fs.readFileSync(mappingPath, 'utf8'));
    } catch (e) {
        console.error('\n❌ ERROR: Your color_mappings.json file has a syntax error!');
        console.error(e.message);
        console.error('Please fix the typo in your JSON file, save it, and try again.\n');
        process.exit(1);
    }
}

const actrNames = {
    1: "Larry", 2: "Sid", 3: "Tiffanie", 4: "Artie", 5: "Charlotte",
    6: "Chuck", 7: "Billie", 8: "JJ", 9: "Bev", 10: "Lucille",
    11: "Gus", 12: "Lilly", 13: "Matt", 14: "Jenny", 15: "Susan",
    16: "Gary", 17: "Ruth", 18: "Glenn", 19: "Baby", 20: "Stella",
    21: "Anna", 22: "Ed"
};

// Properly polyfill Jimp buffer resolution
async function getBufferPromise(img, mime = 'image/png') {
    if (typeof img.getBufferAsync === 'function') return await img.getBufferAsync(mime);
    try {
        const res = img.getBuffer(mime);
        if (res && typeof res.then === 'function') return await res;
        if (Buffer.isBuffer(res)) return res;
    } catch (e) {}
    return new Promise((resolve, reject) => { img.getBuffer(mime, (err, buf) => err ? reject(err) : resolve(buf)); });
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
        if (fs.existsSync(checkPath)) { palettePath = checkPath; break; }
    }
    if (!palettePath) throw new Error(`No ACTORS files found on drive ${drive}:\\ to read palette.`);

    const fd = fs.openSync(palettePath, 'r');
    const palBuf = Buffer.alloc(2048);
    try { fs.readSync(fd, palBuf, 0, 2048, 11946359 + 8); } catch (e) {}
    fs.closeSync(fd);

    const palette = [];
    for (let i = 0; i < 256; i++) {
        const idx = i * 8;
        if (idx + 7 < palBuf.length) palette.push({ r: palBuf[idx + 3], g: palBuf[idx + 5], b: palBuf[idx + 7] });
        else palette.push({ r: 0, g: 0, b: 0 });
    }
    return palette;
}

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

rl.question('Drive letter for CD-ROM (e.g., J): ', (driveLetter) => {
    driveLetter = driveLetter.trim().toUpperCase() || 'J';
    rl.question('Enter Image ID (e.g., 300 for Actor, 151 for Scene): ', async (idStr) => {
        const targetId = parseInt(idStr.trim(), 10);
        if (isNaN(targetId)) { console.error("Invalid ID."); process.exit(1); }

        console.log(`\nLoading Global Palette from ${driveLetter}:\\...`);
        const globalPalette = getGlobalPalette(driveLetter);

        console.log(`Searching CD-ROM for ID ${targetId}...`);
        const cdData = getImageDataFromCD(driveLetter, targetId);
        
        if (!cdData) {
            console.error(`\nERROR: Image ID ${targetId} not found on CD-ROM.`);
            process.exit(1);
        }

        console.log(`Found image: ${cdData.width}x${cdData.height}. Processing...`);

        let characterName = "Unknown";
        if (cdData.sourceFile.toUpperCase().startsWith('SCENES')) {
            characterName = "Scenes";
        } else {
            const charRouteId = Math.floor(targetId / 1000);
            characterName = actrNames[charRouteId] || "Unknown";
        }
        
        const activeRemap = colorMappings || null;
        
        console.log(`\n-----------------------------------------`);
        console.log(`Category Detected: ${characterName} (from ${cdData.sourceFile})`);
        console.log(`Active Color Overrides: ${activeRemap ? Object.keys(activeRemap).length : 0}`);
        console.log(`-----------------------------------------\n`);

        const width = cdData.width;
        const height = cdData.height;
        const rowBytes = Math.ceil(width / 4) * 4;
        const imageRaw = new Jimp({ width, height });
        const imageCorrected = new Jimp({ width, height });
        const usedIndices = new Map();

        for (let y = 0; y < height; y++) {
            for (let x = 0; x < width; x++) {
                const srcIdx = y * rowBytes + x;
                if (srcIdx < cdData.decompressed.length) {
                    const paletteIdx = cdData.decompressed[srcIdx];
                    
                    if (paletteIdx === 255) continue; // Always transparent

                    const color = globalPalette[paletteIdx] || { r: 0, g: 0, b: 0 };
                    if (!usedIndices.has(paletteIdx)) {
                        usedIndices.set(paletteIdx, { r: color.r, g: color.g, b: color.b, count: 1 });
                    } else {
                        usedIndices.get(paletteIdx).count++;
                    }

                    const dataIdx = (y * width + x) * 4;
                    
                    imageRaw.bitmap.data[dataIdx] = color.r;
                    imageRaw.bitmap.data[dataIdx + 1] = color.g;
                    imageRaw.bitmap.data[dataIdx + 2] = color.b;
                    imageRaw.bitmap.data[dataIdx + 3] = 255;

                    if (activeRemap && activeRemap[paletteIdx] !== undefined) {
                        const mappedRGB = activeRemap[paletteIdx].color;
                        imageCorrected.bitmap.data[dataIdx] = mappedRGB[0];
                        imageCorrected.bitmap.data[dataIdx + 1] = mappedRGB[1];
                        imageCorrected.bitmap.data[dataIdx + 2] = mappedRGB[2];
                    } else {
                        imageCorrected.bitmap.data[dataIdx] = color.r;
                        imageCorrected.bitmap.data[dataIdx + 1] = color.g;
                        imageCorrected.bitmap.data[dataIdx + 2] = color.b;
                    }
                    imageCorrected.bitmap.data[dataIdx + 3] = 255;
                }
            }
        }

        const rawImgName = `pose_${targetId}.png`;
        const correctedImgName = `pose_${targetId}_corrected.png`;

        const rawBuf = await getBufferPromise(imageRaw);
        const correctedBuf = await getBufferPromise(imageCorrected);
        fs.writeFileSync(path.join(outDir, rawImgName), rawBuf);
        fs.writeFileSync(path.join(outDir, correctedImgName), correctedBuf);
        const rawBase64 = "data:image/png;base64," + rawBuf.toString('base64');
        const correctedBase64 = "data:image/png;base64," + correctedBuf.toString('base64');

        const sortedIndices = Array.from(usedIndices.entries()).sort((a, b) => a[0] - b[0]);
        let htmlColors = '';
        let rgbToIndexMap = {};
        for (const [idx, col] of sortedIndices) {
            const key = `${col.r},${col.g},${col.b}`;
            if (!rgbToIndexMap[key]) rgbToIndexMap[key] = [];
            rgbToIndexMap[key].push(idx);
            
            let alteredHtml = '';
            let isAltered = false;
            
            if (activeRemap && activeRemap[idx] !== undefined) {
                const mappedRGB = activeRemap[idx].color;
                isAltered = true;
                alteredHtml = `
            <div style="margin-top: 8px; border-top: 1px solid #555; padding-top: 8px;" class="color-row">
                <span class="color-swatch" style="width: 16px; height: 16px; background: rgb(${mappedRGB[0]},${mappedRGB[1]},${mappedRGB[2]}); border-color: #4caf50;"></span>
                <span style="color: #4caf50; font-size: 12px;">Mapped: (${mappedRGB[0]}, ${mappedRGB[1]}, ${mappedRGB[2]})</span>
            </div>`;
            }
            
            const borderStyle = isAltered ? 'border-color: #4caf50;' : '';

            htmlColors += `
        <div class="color-card" style="${borderStyle}" onclick="highlightColor(${col.r}, ${col.g}, ${col.b})">
            <div class="color-row">
                <span class="color-swatch" style="background: rgb(${col.r},${col.g},${col.b});"></span>
                <span>Index: <b>${idx}</b><br><small>Raw: (${col.r}, ${col.g}, ${col.b})</small><br><small>Pixels: ${col.count}</small></span>
            </div>
            ${alteredHtml}
        </div>`;
        }

        const html = `<!DOCTYPE html>
<html>
<head>
    <title>Palette Debug - ID ${targetId}</title>
    <style>
        body { font-family: sans-serif; background: #222; color: #eee; margin: 0; padding: 20px; box-sizing: border-box; height: 100vh; display: flex; flex-direction: column; overflow: hidden; }
        h1 { margin-top: 0; flex-shrink: 0; }
        .container { display: flex; gap: 20px; align-items: stretch; flex: 1; min-height: 0; }
        .img-panel { background: #111; padding: 20px; border-radius: 8px; text-align: center; flex: 1; display: flex; flex-direction: column; overflow: hidden; }
        .img-panel p { flex-shrink: 0; }
        .img-panel h3 { margin-top: 0; flex-shrink: 0; }
        .canvas-container { flex: 1; min-height: 0; display: flex; align-items: center; justify-content: center; overflow: hidden; }
        canvas { cursor: pointer; max-width: 100%; max-height: 100%; border: 1px solid #555; background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><rect width="10" height="10" fill="gray"/><rect x="10" y="10" width="10" height="10" fill="gray"/><rect x="10" width="10" height="10" fill="darkgray"/><rect y="10" width="10" height="10" fill="darkgray"/></svg>'); }
        .middle-panel { flex: 0 0 420px; display: flex; flex-direction: column; background: #111; padding: 20px; border-radius: 8px; overflow: hidden; }
        .middle-panel h3 { margin-top: 0; flex-shrink: 0; }
        .color-list { display: flex; flex-wrap: wrap; gap: 10px; align-content: flex-start; overflow-y: auto; flex: 1; padding-right: 10px; }
        .color-list::-webkit-scrollbar { width: 8px; }
        .color-list::-webkit-scrollbar-track { background: #222; border-radius: 4px; }
        .color-list::-webkit-scrollbar-thumb { background: #555; border-radius: 4px; }
        .color-list::-webkit-scrollbar-thumb:hover { background: #777; }
        .color-card { background: #333; padding: 10px; border-radius: 6px; display: flex; flex-direction: column; width: calc(50% - 5px); box-sizing: border-box; cursor: pointer; border: 1px solid transparent; transition: 0.2s; }
        .color-card:hover { border-color: #888; background: #444; }
        .color-row { display: flex; align-items: center; width: 100%; }
        .color-swatch { width: 32px; height: 32px; border: 1px solid #000; border-radius: 4px; margin-right: 12px; flex-shrink: 0; }
    </style>
</head>
<body>
    <h1>Palette Debug - Image ID: ${targetId} (${characterName})</h1>
    <h2 id="selectedIndexLabel" style="margin-top: -10px; margin-bottom: 20px; color: #aaa; font-size: 18px;">Selected Index: None</h2>
    <div class="container">
        <div class="img-panel">
            <h3>Raw Image</h3>
            <p style="font-size:12px; color:#aaa;">Click a swatch or a pixel to highlight. Click background to reset.</p>
            <div class="canvas-container">
                <canvas id="canvas" onclick="canvasClick(event, false)"></canvas>
            </div>
        </div>
        <div class="middle-panel">
            <h3>Used Colors (${sortedIndices.length} total)</h3>
            <div class="color-list">${htmlColors}</div>
        </div>
        <div class="img-panel">
            <h3>Corrected Image</h3>
            <p style="font-size:12px; color:#aaa;">Click a swatch or a pixel to highlight. Click background to reset.</p>
            <div class="canvas-container">
                <canvas id="canvasCorrected" onclick="canvasClick(event, true)"></canvas>
            </div>
        </div>
    </div>
    <script>
        const imgRaw = new Image();
        const imgCorrected = new Image();
        
        let originalData = null;
        let originalDataCorrected = null;
        let canvas, ctx, canvasCorrected, ctxCorrected;
        let blinkInterval = null;
        let activeHighlight = null;

        let loadedCount = 0;
        function onImageLoad() {
            loadedCount++;
            if (loadedCount === 2) {
                canvas = document.getElementById('canvas');
                ctx = canvas.getContext('2d');
                canvas.width = imgRaw.width;
                canvas.height = imgRaw.height;
                ctx.drawImage(imgRaw, 0, 0);
                originalData = ctx.getImageData(0, 0, canvas.width, canvas.height);

                canvasCorrected = document.getElementById('canvasCorrected');
                ctxCorrected = canvasCorrected.getContext('2d');
                canvasCorrected.width = imgCorrected.width;
                canvasCorrected.height = imgCorrected.height;
                ctxCorrected.drawImage(imgCorrected, 0, 0);
                originalDataCorrected = ctxCorrected.getImageData(0, 0, canvasCorrected.width, canvasCorrected.height);
            }
        }

        imgRaw.onload = onImageLoad;
        imgCorrected.onload = onImageLoad;

        // Base64 URIs prevent strict local-file CORS policies from crashing getImageData!
        imgRaw.src = "${rawBase64}";
        imgCorrected.src = "${correctedBase64}";

        const rgbToIndex = ${JSON.stringify(rgbToIndexMap)};

        function highlightColor(r, g, b) {
            if (!originalData || !originalDataCorrected) return;
            
            const key = r + ',' + g + ',' + b;
            if (activeHighlight === key) {
                resetImage();
                return;
            }
            activeHighlight = key;

            const indices = rgbToIndex[key];
            document.getElementById('selectedIndexLabel').innerText = 'Selected Index: ' + (indices ? indices.join(', ') : 'Unknown');

            if (blinkInterval) clearInterval(blinkInterval);

            let toggle = true;

            function drawFrame() {
                const dataRaw = new Uint8ClampedArray(originalData.data);
                const dataCorr = new Uint8ClampedArray(originalDataCorrected.data);
                
                for (let i = 0; i < dataRaw.length; i += 4) {
                    const pr = originalData.data[i];
                    const pg = originalData.data[i+1];
                    const pb = originalData.data[i+2];
                    const pa = originalData.data[i+3];

                    if (pa === 0) continue;

                    if (pr === r && pg === g && pb === b) {
                        if (toggle) {
                            dataRaw[i] = 255; dataRaw[i+1] = 0; dataRaw[i+2] = 255;
                            dataCorr[i] = 255; dataCorr[i+1] = 0; dataCorr[i+2] = 255;
                        }
                    } else {
                        // Dark mask over everything else
                        dataRaw[i] = Math.floor(pr * 0.15);
                        dataRaw[i+1] = Math.floor(pg * 0.15);
                        dataRaw[i+2] = Math.floor(pb * 0.15);
                        
                        dataCorr[i] = Math.floor(originalDataCorrected.data[i] * 0.15);
                        dataCorr[i+1] = Math.floor(originalDataCorrected.data[i+1] * 0.15);
                        dataCorr[i+2] = Math.floor(originalDataCorrected.data[i+2] * 0.15);
                    }
                }
                ctx.putImageData(new ImageData(dataRaw, canvas.width, canvas.height), 0, 0);
                ctxCorrected.putImageData(new ImageData(dataCorr, canvasCorrected.width, canvasCorrected.height), 0, 0);
                toggle = !toggle;
            }

            drawFrame();
            blinkInterval = setInterval(drawFrame, 500); // Blink effect
        }

        function resetImage() {
            activeHighlight = null;
            document.getElementById('selectedIndexLabel').innerText = 'Selected Index: None';
            if (blinkInterval) clearInterval(blinkInterval);
            if (originalData) ctx.putImageData(originalData, 0, 0);
            if (originalDataCorrected) ctxCorrected.putImageData(originalDataCorrected, 0, 0);
        }

        function canvasClick(event, isCorrected) {
            if (!originalData) return;
            const targetCanvas = isCorrected ? canvasCorrected : canvas;
            const rect = targetCanvas.getBoundingClientRect();
            const scaleX = targetCanvas.width / rect.width;
            const scaleY = targetCanvas.height / rect.height;
            const x = Math.floor((event.clientX - rect.left) * scaleX);
            const y = Math.floor((event.clientY - rect.top) * scaleY);
            
            const idx = (y * targetCanvas.width + x) * 4;
            const r = originalData.data[idx];
            const g = originalData.data[idx+1];
            const b = originalData.data[idx+2];
            const a = originalData.data[idx+3];
            
            if (a === 0) resetImage();
            else highlightColor(r, g, b);
        }
    </script>
</body>
</html>`;

        const htmlPath = path.join(outDir, `report_${targetId}.html`);
        fs.writeFileSync(htmlPath, html);

        console.log(`\nDone! Saved to ${outDir}`);
        console.log(`Open ${htmlPath} in your browser.`);
        rl.close();
    });
});