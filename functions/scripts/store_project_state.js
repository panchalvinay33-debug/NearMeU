'use strict';

const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');

const manifestPath = path.resolve(
  __dirname,
  '..',
  '..',
  'config',
  'project_state_manifest.json',
);

function readManifest() {
  const raw = fs.readFileSync(manifestPath, 'utf8');
  const manifest = JSON.parse(raw);

  if (!manifest.project || !manifest.baselineName || !manifest.schemaVersion) {
    throw new Error('Project-state manifest is missing required fields.');
  }

  return manifest;
}

async function main() {
  const manifest = readManifest();
  const shouldWrite = process.argv.includes('--write');

  if (!shouldWrite) {
    console.log(JSON.stringify({ mode: 'dry-run', manifest }, null, 2));
    console.log('\nNo database write performed. Re-run with --write after confirming the Firebase project.');
    return;
  }

  if (admin.apps.length === 0) {
    admin.initializeApp();
  }

  const projectId = admin.app().options.projectId || process.env.GCLOUD_PROJECT;
  if (!projectId) {
    throw new Error('Could not determine Firebase project ID. Use authenticated Firebase/GCloud credentials.');
  }

  const expectedProjectId = process.env.NEARMEU_EXPECTED_FIREBASE_PROJECT_ID;
  if (expectedProjectId && expectedProjectId !== projectId) {
    throw new Error(
      `Refusing to write: authenticated project "${projectId}" does not match expected project "${expectedProjectId}".`,
    );
  }

  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const baselineId = manifest.baselineName;

  const currentRef = db.collection('systemProjectState').doc('current');
  const historyRef = db.collection('systemProjectStateHistory').doc(baselineId);

  const payload = {
    ...manifest,
    source: 'repository-manifest',
    sourcePath: 'config/project_state_manifest.json',
    storedBy: 'functions/scripts/store_project_state.js',
    firebaseProjectId: projectId,
    storedAt: now,
  };

  const batch = db.batch();
  batch.set(currentRef, payload, { merge: false });
  batch.set(historyRef, payload, { merge: false });
  await batch.commit();

  console.log(
    JSON.stringify(
      {
        status: 'stored',
        firebaseProjectId: projectId,
        currentDocument: currentRef.path,
        historyDocument: historyRef.path,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error instanceof Error ? error.stack : error);
  process.exitCode = 1;
});
