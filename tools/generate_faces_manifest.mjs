/**
 * Builds assets/faces/manifest.json from bundled boy/girl JPEG folders.
 * Run: node tools/generate_faces_manifest.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const assetsRoot = path.join(path.resolve(__dirname, '..'), 'assets', 'faces');

function listJpegs(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((f) => /\.jpe?g$/i.test(f))
    .sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }));
}

const faces = [];
for (const { folder, gender } of [
  { folder: 'boy', gender: 'male' },
  { folder: 'girl', gender: 'female' },
]) {
  const localDir = path.join(assetsRoot, folder);
  const files = listJpegs(localDir);
  for (let i = 0; i < files.length; i++) {
    const fileName = files[i];
    faces.push({
      id: `${folder}_${String(i + 1).padStart(3, '0')}`,
      gender,
      assetPath: `assets/faces/${folder}/${fileName}`,
    });
  }
}

const manifest = {
  version: 1,
  updatedAt: new Date().toISOString(),
  faces,
};

const manifestPath = path.join(assetsRoot, 'manifest.json');
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
console.log(`Wrote ${manifestPath} (${faces.length} faces)`);
