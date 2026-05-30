const fs = require('fs');
const path = require('path');

const projectDir = path.join(__dirname, '..', '..');
const soundsDir = path.join(projectDir, 'datafiles', 'sounds');
const backupDir = path.join(projectDir, 'datafiles', 'sounds_backup');
const packPath = path.join(projectDir, 'datafiles', 'sounds.pack');
const yypPath = path.join(projectDir, 'Hollywood High.yyp');
const yypBackupPath = yypPath + '.bak_sounds';

console.log("Starting Sound Effects Packing...");

if (!fs.existsSync(soundsDir)) {
    console.log("Creating empty sounds directory:", soundsDir);
    fs.mkdirSync(soundsDir);
}

// 1. Gather directories and files
// Check if soundsDir is empty and load from backupDir instead
let sourceDir = soundsDir;
let categories = fs.readdirSync(soundsDir).filter(f => {
    return fs.statSync(path.join(soundsDir, f)).isDirectory();
});

if (categories.length === 0 && fs.existsSync(backupDir)) {
    console.log("datafiles/sounds is empty. Loading from datafiles/sounds_backup...");
    sourceDir = backupDir;
    categories = fs.readdirSync(backupDir).filter(f => {
        return fs.statSync(path.join(backupDir, f)).isDirectory();
    });
}

console.log(`Found ${categories.length} categories to scan.`);

const filesToPack = [];
categories.sort();

categories.forEach(cat => {
    const catPath = path.join(sourceDir, cat);
    const catFiles = fs.readdirSync(catPath).filter(f => {
        return path.extname(f).toLowerCase() === '.wav';
    });
    
    catFiles.sort();
    catFiles.forEach(f => {
        // Relative path key in GML e.g. "Animals/dog.wav"
        filesToPack.push({
            relPath: `${cat}/${f}`,
            fullPath: path.join(catPath, f)
        });
    });
});

console.log(`Found ${filesToPack.length} sound files to pack.`);

if (filesToPack.length === 0) {
    console.log("No sound files found. Exiting.");
    process.exit(0);
}

// 2. Prepare file data and calculate relative offsets
const header = {};
let currentOffset = 0;
const fileBuffers = [];

filesToPack.forEach(item => {
    const buffer = fs.readFileSync(item.fullPath);
    
    header[item.relPath] = {
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
    Object.keys(header).forEach(k => {
        shiftedHeader[k] = {
            offset: 4 + shiftOffset + header[k].offset,
            size: header[k].size
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

// Write sounds.pack
console.log("Writing sounds.pack to:", packPath);
fs.writeFileSync(packPath, packBuffer);
console.log("sounds.pack created successfully! Size:", (packBuffer.length / (1024 * 1024)).toFixed(2), "MB");

// 4. Update Hollywood High.yyp IncludedFiles
console.log("Updating YYP IncludedFiles...");
const yypContent = fs.readFileSync(yypPath, 'utf8');

// Write YYP backup
fs.writeFileSync(yypBackupPath, yypContent, 'utf8');
console.log("YYP backup written to:", yypBackupPath);

try {
    const yyp = JSON.parse(yypContent);
    if (yyp.IncludedFiles) {
        // Filter out individual sound effects (filePath starts with datafiles/sounds/)
        const filteredIncluded = yyp.IncludedFiles.filter(f => {
            return !f.filePath.startsWith('datafiles/sounds/') && !f.filePath.startsWith('datafiles/sounds');
        });
        
        // Add single sounds.pack entry
        const packEntry = {
            "$GMIncludedFile": "",
            "%Name": "sounds.pack",
            "CopyToMask": -1,
            "filePath": "datafiles",
            "name": "sounds.pack",
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
    
    // Regex based parsing: Remove any IncludedFiles lines that contain datafiles/sounds
    const lines = yypContent.split(/\r?\n/);
    const filteredLines = lines.filter(line => {
        return !line.includes('"filePath":"datafiles/sounds') && !line.includes('"filePath": "datafiles/sounds');
    });
    
    // Find the IncludedFiles insertion spot
    const yypWithPack = filteredLines.join('\n').replace(
        /"IncludedFiles"\s*:\s*\[/,
        '"IncludedFiles": [\n    {"$GMIncludedFile":"","%Name":"sounds.pack","CopyToMask":-1,"filePath":"datafiles","name":"sounds.pack","resourceType":"GMIncludedFile","resourceVersion":"2.0"},'
    );
    
    fs.writeFileSync(yypPath, yypWithPack, 'utf8');
    console.log("YYP file updated successfully via Regex!");
}

// 5. Move packed backgrounds to datafiles/sounds_backup
if (!fs.existsSync(backupDir)) {
    console.log("Creating backup directory:", backupDir);
    fs.mkdirSync(backupDir);
}

if (sourceDir !== backupDir) {
    console.log("Moving source files to backup directory...");
    categories.forEach(cat => {
        const oldCatPath = path.join(soundsDir, cat);
        const newCatPath = path.join(backupDir, cat);
        
        if (!fs.existsSync(newCatPath)) {
            fs.mkdirSync(newCatPath);
        }
        
        const files = fs.readdirSync(oldCatPath);
        files.forEach(f => {
            fs.renameSync(path.join(oldCatPath, f), path.join(newCatPath, f));
        });
        
        // Remove empty old category directory
        fs.rmdirSync(oldCatPath);
    });
} else {
    console.log("Files are already in backup directory. Skipping move.");
}

console.log(`Successfully packed and backed up ${filesToPack.length} sound files!`);
console.log("Sound Effects Packing Complete.");
