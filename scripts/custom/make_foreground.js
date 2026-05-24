const fs = require('fs');
const path = require('path');
const { Jimp } = require('jimp');

async function makeForeground(refPath, fgPath, shear = 0) {
    console.log(`Loading reference: ${refPath}`);
    console.log(`Loading extracted foreground: ${fgPath}`);

    const ref = await Jimp.read(refPath);
    const fg = await Jimp.read(fgPath);

    const refW = ref.bitmap.width;
    const refH = ref.bitmap.height;
    const fgW = fg.bitmap.width;
    const fgH = fg.bitmap.height;

    console.log(`Reference: ${refW}x${refH}`);
    console.log(`Foreground: ${fgW}x${fgH}`);

    const out = new Jimp({ width: refW, height: refH });

	for (let y = 0; y < refH; y++) {
		for (let x = 0; x < refW; x++) {
		const fgX = Math.floor(x * (fgW / refW) + ((x / refW) - 0.5) * shear);
		const fgY = Math.floor(y * (fgH / refH));

			if (fgX < 0 || fgY < 0 || fgX >= fgW || fgY >= fgH) continue;

			const fgIdx = (fgY * fgW + fgX) * 4;
			const fgA = fg.bitmap.data[fgIdx + 3];

			if (fgA > 10) {
				const refIdx = (y * refW + x) * 4;
				out.bitmap.data[refIdx]     = ref.bitmap.data[refIdx];
				out.bitmap.data[refIdx + 1] = ref.bitmap.data[refIdx + 1];
				out.bitmap.data[refIdx + 2] = ref.bitmap.data[refIdx + 2];
				out.bitmap.data[refIdx + 3] = 255;
			}
		}
	}

    const refName = path.basename(refPath, path.extname(refPath));
    const outPath = path.join(path.dirname(refPath), `${refName}_mask.png`);

    const pngBuf = await out.getBuffer('image/png');
    fs.writeFileSync(outPath, pngBuf);
    console.log(`Done! Output written to: ${outPath}`);
}
const args = process.argv.slice(2);
if (args.length < 2) {
	console.log('Usage: node make_foreground.js <reference.png> <foreground.png> [shear]');
	console.log('Example: node make_foreground.js Airplane.png airplane_foreground.png -20');
    process.exit(1);
}

const refPath = path.join(__dirname, args[0]);
const fgPath = path.join(__dirname, args[1]);
const shear = args[2] ? parseFloat(args[2]) : 0;

makeForeground(refPath, fgPath, shear).catch(console.error);