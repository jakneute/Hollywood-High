const fs = require('fs');
const path = require('path');

const packPath = path.join(__dirname, '..', '..', 'datafiles', 'sounds.pack');

if (!fs.existsSync(packPath)) {
    console.error("sounds.pack not found!");
    process.exit(1);
}

const buffer = fs.readFileSync(packPath);
const headerSize = buffer.readUInt32LE(0);
console.log("Read Header Size:", headerSize, "bytes");

const headerJson = buffer.slice(4, 4 + headerSize).toString('utf8');
const header = JSON.parse(headerJson);

console.log("Successfully parsed JSON header!");
const keys = Object.keys(header);
console.log(`Contains ${keys.length} packed files.`);
console.log("First 5 files in index:");
keys.slice(0, 5).forEach(k => {
    console.log(` - ${k}: offset=${header[k].offset}, size=${header[k].size}`);
});

// Test reading a slice and verifying it's a valid WAV file (starts with 'RIFF')
if (keys.length > 0) {
    const firstKey = keys[0];
    const info = header[firstKey];
    const fileSlice = buffer.slice(info.offset, info.offset + info.size);
    const hasRiff = fileSlice.slice(0, 4).toString('ascii') === 'RIFF';
    console.log(`Successfully sliced first file (${firstKey})! Starts with 'RIFF' header signature: ${hasRiff}`);
}
