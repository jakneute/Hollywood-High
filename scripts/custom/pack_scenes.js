const fs = require('fs');
const path = require('path');

const projectDir = path.join(__dirname, '..', '..');
const scenesDir = path.join(projectDir, 'datafiles', 'scenes');
const backupDir = path.join(projectDir, 'datafiles', 'scenes_backup');
const packPath = path.join(projectDir, 'datafiles', 'scenes.pack');
const yypPath = path.join(projectDir, 'Hollywood High.yyp');
const yypBackupPath = yypPath + '.bak_scenes';

console.log("Starting Background Scenes Packing...");

if (!fs.existsSync(scenesDir)) {
    console.log("Creating empty scenes directory:", scenesDir);
    fs.mkdirSync(scenesDir);
}

// 1. Gather all files in datafiles/scenes or datafiles/scenes_backup
let sourceDir = scenesDir;
let files = fs.readdirSync(scenesDir).filter(f => {
    const ext = path.extname(f).toLowerCase();
    return ext === '.png' || ext === '.jpg' || ext === '.jpeg';
});

if (files.length === 0 && fs.existsSync(backupDir)) {
    console.log("datafiles/scenes is empty. Loading from datafiles/scenes_backup...");
    sourceDir = backupDir;
    files = fs.readdirSync(backupDir).filter(f => {
        const ext = path.extname(f).toLowerCase();
        return ext === '.png' || ext === '.jpg' || ext === '.jpeg';
    });
}

console.log(`Found ${files.length} backgrounds/masks to pack.`);

if (files.length === 0) {
    console.log("No files to pack. Exiting.");
    process.exit(0);
}

// Deterministic sorting
files.sort();

// 2. Prepare file data and calculate relative offsets
const header = {};
let currentOffset = 0;
const fileBuffers = [];

files.forEach(f => {
    const filePath = path.join(sourceDir, f);
    const buffer = fs.readFileSync(filePath);
    
    header[f] = {
        offset: currentOffset,
        size: buffer.length
    };
    
    currentOffset += buffer.length;
    fileBuffers.push(buffer);
});

// Convergent shift size loop to avoid offset drift
let shiftOffset = 0;
let finalHeaderBuffer;
let finalHeaderSize = 0;

for (let iter = 0; iter < 5; iter++) {
    const shiftedHeader = {};
    Object.keys(header).forEach(f => {
        shiftedHeader[f] = {
            offset: 4 + shiftOffset + header[f].offset,
            size: header[f].size
        };
    });
    const json = JSON.stringify(shiftedHeader);
    finalHeaderBuffer = Buffer.from(json, 'utf8');
    finalHeaderSize = finalHeaderBuffer.length;
    if (finalHeaderSize === shiftOffset) {
        break; // Size has stabilized!
    }
    shiftOffset = finalHeaderSize;
}

console.log(`JSON Header Size: ${finalHeaderSize} bytes.`);

// 3. Assemble the pack file
// Format: [4 bytes: uint32 header size] + [finalHeaderBuffer] + [fileBuffers...]
const packSize = 4 + finalHeaderSize + currentOffset;
const packBuffer = Buffer.alloc(packSize);

// Write header size (Little Endian uint32)
packBuffer.writeUInt32LE(finalHeaderSize, 0);

// Copy header
finalHeaderBuffer.copy(packBuffer, 4);

// Copy all files
let writePos = 4 + finalHeaderSize;
fileBuffers.forEach(buf => {
    buf.copy(packBuffer, writePos);
    writePos += buf.length;
});

// Write scenes.pack
console.log("Writing scenes.pack to:", packPath);
fs.writeFileSync(packPath, packBuffer);
console.log("scenes.pack created successfully! Size:", (packBuffer.length / (1024 * 1024)).toFixed(2), "MB");

// 4. Update Hollywood High.yyp
console.log("Updating YYP IncludedFiles...");
const yypContent = fs.readFileSync(yypPath, 'utf8');

// Write YYP backup
fs.writeFileSync(yypBackupPath, yypContent, 'utf8');
console.log("YYP backup written to:", yypBackupPath);

try {
    const yyp = JSON.parse(yypContent);
    if (yyp.IncludedFiles) {
        // Filter out individual scenes
        const filteredIncluded = yyp.IncludedFiles.filter(f => {
            return f.filePath !== 'datafiles/scenes';
        });
        
        // Add single scenes.pack entry
        const packEntry = {
            "$GMIncludedFile": "",
            "%Name": "scenes.pack",
            "CopyToMask": -1,
            "filePath": "datafiles",
            "name": "scenes.pack",
            "resourceType": "GMIncludedFile",
            "resourceVersion": "2.0"
        };
        
        filteredIncluded.push(packEntry);
        yyp.IncludedFiles = filteredIncluded;
        
        fs.writeFileSync(yypPath, JSON.stringify(yyp, null, 2), 'utf8');
        console.log("YYP file updated successfully via JSON parse!");
    } else {
        throw new Error("IncludedFiles array not found in YYP!");
    }
} catch (e) {
    console.warn("JSON parse failed, doing regex update on YYP:", e.message);
    
    // Regex based parsing
    // Remove all lines containing filePath datafiles/scenes
    const lines = yypContent.split(/\r?\n/);
    const filteredLines = lines.filter(line => {
        return !line.includes('"filePath":"datafiles/scenes"') && !line.includes('"filePath": "datafiles/scenes"');
    });
    
    // Find the IncludedFiles insertion spot
    const yypWithPack = filteredLines.join('\n').replace(
        /"IncludedFiles"\s*:\s*\[/,
        '"IncludedFiles": [\n    {"$GMIncludedFile":"","%Name":"scenes.pack","CopyToMask":-1,"filePath":"datafiles","name":"scenes.pack","resourceType":"GMIncludedFile","resourceVersion":"2.0"},'
    );
    
    fs.writeFileSync(yypPath, yypWithPack, 'utf8');
    console.log("YYP file updated successfully via Regex!");
}

// 5. Move packed backgrounds to datafiles/scenes_backup
if (!fs.existsSync(backupDir)) {
    console.log("Creating backup directory:", backupDir);
    fs.mkdirSync(backupDir);
}

if (sourceDir !== backupDir) {
    console.log("Moving source files to backup directory...");
    files.forEach(f => {
        const oldPath = path.join(scenesDir, f);
        const newPath = path.join(backupDir, f);
        fs.renameSync(oldPath, newPath);
    });
} else {
    console.log("Files are already in backup directory. Skipping move.");
}

console.log(`Successfully packed and backed up ${files.length} backgrounds!`);
console.log("Background Scenes Packing Complete.");
