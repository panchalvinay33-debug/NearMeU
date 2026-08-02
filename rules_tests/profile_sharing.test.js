const {
  initializeTestEnvironment,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');
const fs = require('fs');

const PROJECT_ID = 'demo-nearmeu-profile-sharing-rules-test';
let env;

function authed(uid) {
  return env.authenticatedContext(uid).firestore();
}

describe('profile sharing internal mapping rules', () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
    });
  });

  beforeEach(async () => {
    await env.clearFirestore();
  });

  after(async () => {
    await env.cleanup();
  });

  it('denies direct client reads and writes to owner/share mappings', async () => {
    const db = authed('alice');
    await assertFails(getDoc(doc(db, 'profileShareOwners/alice')));
    await assertFails(getDoc(doc(db, 'profileShareLinks/opaquePublicId1234567890')));
    await assertFails(
      setDoc(doc(db, 'profileShareOwners/alice'), {
        publicId: 'opaquePublicId1234567890',
        enabled: true,
      }),
    );
    await assertFails(
      setDoc(doc(db, 'profileShareLinks/opaquePublicId1234567890'), {
        ownerUid: 'alice',
        enabled: true,
      }),
    );
  });
});
