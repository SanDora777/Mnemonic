/**
 * Uploads face photos from a local boy/girl folder to Firebase Storage and
 * writes assets/faces/manifest.json for the Flutter app.
 *
 * Usage (from repo root):
 *   node tools/upload_faces.mjs "C:\Users\nbs27\Downloads\facegender"
 *
 * Requires: firebase login + Application Default Credentials, or
 * GOOGLE_APPLICATION_CREDENTIALS pointing at a service account key.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const storageBucket = 'neural-hack-5ab7d.firebasestorage.app';
const sourceRoot = process.argv[2] ?? path.join(process.env.USERPROFILE ?? '', 'Downloads', 'facegender');

const genderFolders = [
  { folder: 'boy', gender: 'male' },
  { folder: 'girl', gender: 'female' },
];

function listJpegs(dir) {
  return fs
    .readdirSync(dir)
    .filter((f) => /\.jpe?g$/i.test(f))
    .sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }));
}

function encodeStoragePath(storagePath) {
  return encodeURIComponent(storagePath).replace(/%2F/g, '%2F');
}

function publicMediaUrl(storagePath, token) {
  const encoded = encodeStoragePath(storagePath);
  return `https://firebasestorage.googleapis.com/v0/b/${storageBucket}/o/${encoded}?alt=media&token=${token}`;
}

async function main() {
  if (!fs.existsSync(sourceRoot)) {
    console.error(`Source folder not found: ${sourceRoot}`);
    process.exit(1);
  }

  admin.initializeApp({
    storageBucket,
  });

  const bucket = admin.storage().bucket();
  const faces = [];

  for (const { folder, gender } of genderFolders) {
    const localDir = path.join(sourceRoot, folder);
    if (!fs.existsSync(localDir)) {
      console.warn(`Skipping missing folder: ${localDir}`);
      continue;
    }
    const files = listJpegs(localDir);
    console.log(`Uploading ${files.length} ${gender} faces from ${localDir}...`);

    for (let i = 0; i < files.length; i++) {
      const id = `${gender === 'male' ? 'boy' : 'girl'}_${String(i + 1).padStart(3, '0')}`;
      const storagePath = `trainer/faces/${gender === 'male' ? 'boy' : 'girl'}/${String(i + 1).padStart(3, '0')}.jpg`;
      const localPath = path.join(localDir, files[i]);

      await bucket.upload(localPath, {
        destination: storagePath,
        metadata: {
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        },
      });

      const [meta] = await bucket.file(storagePath).getMetadata();
      const token = meta.metadata?.firebaseStorageDownloadTokens;
      if (!token) {
        throw new Error(`No download token on ${storagePath}`);
      }

      faces.push({
        id,
        gender,
        storagePath,
        url: publicMediaUrl(storagePath, token),
      });
      process.stdout.write(`  ${id}\r`);
    }
    console.log(`  done ${gender}: ${files.length} files`);
  }

  const manifest = {
    version: 1,
    bucket: storageBucket,
    updatedAt: new Date().toISOString(),
    faces,
  };

  const manifestJson = JSON.stringify(manifest, null, 2);
  const assetsDir = path.join(repoRoot, 'assets', 'faces');
  fs.mkdirSync(assetsDir, { recursive: true });
  const manifestPath = path.join(assetsDir, 'manifest.json');
  fs.writeFileSync(manifestPath, manifestJson, 'utf8');
  console.log(`Wrote ${manifestPath} (${faces.length} faces)`);

  const manifestStoragePath = 'trainer/faces/manifest.json';
  await bucket.file(manifestStoragePath).save(manifestJson, {
    contentType: 'application/json',
    metadata: {
      cacheControl: 'public, max-age=3600',
    },
  });
  console.log(`Uploaded ${manifestStoragePath}`);
  console.log('Deploy storage rules: firebase deploy --only storage');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
