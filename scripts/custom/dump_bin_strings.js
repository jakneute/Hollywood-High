const fs = require('fs');
const path = require('path');

const targetDir = path.join(__dirname, 'extracted_assets');
const reportPath = path.join(__dirname, 'bin_strings_report.txt');

if (!fs.existsSync(targetDir)) {
    console.error(`Directory not found: ${targetDir}`);
    process.exit(1);
}

// Recursively find all .bin files in the extracted_assets directory
function getBinFiles(dir, fileList = []) {
    const items = fs.readdirSync(dir);
    for (const item of items) {
        const fullPath = path.join(dir, item);
        if (fs.statSync(fullPath).isDirectory()) {
            getBinFiles(fullPath, fileList);
        } else if (fullPath.endsWith('.bin')) {
            fileList.push(fullPath);
        }
    }
    return fileList;
}

const files = getBinFiles(targetDir);

if (files.length === 0) {
    console.log(`No .bin files found in ${targetDir}`);
    process.exit(0);
}

console.log(`Scanning ${files.length} .bin files for embedded readable strings...\n`);
let reportContent = `Binary Strings Report\n======================\nScanned ${files.length} files.\n\n`;

let totalStrings = 0;
const MIN_LENGTH = 5; // Minimum string length to filter out random byte noise

for (const filePath of files) {
    const buffer = fs.readFileSync(filePath);
    let currentString = '';
    let fileHasStrings = false;

    // Iterate byte by byte. If it's a printable ASCII character, build a string.
    for (let i = 0; i < buffer.length; i++) {
        const byte = buffer[i];
        if (byte >= 32 && byte <= 126 || byte === 9) {
            currentString += String.fromCharCode(byte);
        } else {
            if (currentString.length >= MIN_LENGTH) {
                if (!fileHasStrings) {
                    const header = `\n--- Readable text in: ${path.relative(targetDir, filePath)} ---`;
                    console.log(header); reportContent += header + '\n';
                    fileHasStrings = true;
                }
                console.log(`  ${currentString}`); reportContent += `  ${currentString}\n`;
                totalStrings++;
            }
            currentString = '';
        }
    }
}

console.log(`\nScan complete. Found ${totalStrings} readable string blocks.`);
fs.writeFileSync(reportPath, reportContent);
console.log(`Full results saved to: ${reportPath}`);