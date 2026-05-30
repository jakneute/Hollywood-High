const fs = require('fs');
const path = require('path');

const projectDir = path.join(__dirname, '..', '..');
const datafilesDir = path.join(projectDir, 'datafiles');

console.log("=========================================");
console.log("   Hollywood High Pack Extraction Tool   ");
console.log("=========================================\n");

function unpackFile(packName, destFolder) {
    const packPath = path.join(datafilesDir, packName);
    const destPath = path.join(datafilesDir, destFolder);

    if (!fs.existsSync(packPath)) {
        console.log(`[-] Skip: ${packName} not found at ${packPath}`);
        return;
    }

    console.log(`[*] Reading ${packName}...`);
    const packBuffer = fs.readFileSync(packPath);

    // 1. Read header size (first 4 bytes, uint32 little endian)
    const headerSize = packBuffer.readUInt32LE(0);
    console.log(`[+] Found header. Size: ${headerSize} bytes.`);

    // 2. Parse JSON header index
    const headerJsonStr = packBuffer.toString('utf8', 4, 4 + headerSize);
    let header;
    try {
        header = JSON.parse(headerJsonStr);
    } catch (err) {
        console.error(`[!] Error parsing JSON header in ${packName}:`, err.message);
        return;
    }

    const files = Object.keys(header);
    console.log(`[+] Pack contains ${files.length} assets. Extracting to datafiles/${destFolder}...`);

    let extractedCount = 0;
    files.forEach(filename => {
        const fileInfo = header[filename];
        const fileOffset = fileInfo.offset;
        const fileSize = fileInfo.size;

        // Extract slice of buffer
        const fileBuffer = packBuffer.subarray(fileOffset, fileOffset + fileSize);

        // Resolve absolute output path (safely handles subdirectories inside the pack keys, e.g., categories in SFX)
        const fileOutPath = path.join(destPath, filename);
        const fileOutDir = path.dirname(fileOutPath);

        // Ensure directories exist
        if (!fs.existsSync(fileOutDir)) {
            fs.mkdirSync(fileOutDir, { recursive: true });
        }

        // Write file to disk
        fs.writeFileSync(fileOutPath, fileBuffer);
        extractedCount++;
    });

    console.log(`[+] Successfully extracted ${extractedCount}/${files.length} assets from ${packName}!\n`);
}

// Extract background scenes
unpackFile('scenes.pack', 'scenes');

// Extract sound effects
unpackFile('sounds.pack', 'sounds');

console.log("=========================================");
console.log("   Unpacking Operation Completed!        ");
console.log("=========================================");
