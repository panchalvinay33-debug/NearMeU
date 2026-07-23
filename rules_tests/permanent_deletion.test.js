const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { deleteDoc, doc, setDoc } = require('firebase/firestore');
const fs = require('fs');

const PROJECT_ID = 'demo-nearmeu-rules-test';
let env;

function authed(uid) {
  return env.authenticatedContext(uid).firestore();
}

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

function activeUser(uid, { admin = false } = {}) {
  return {
    uid,
    nickname: uid,
    age: 25,
    isAdmin: admin,
    isSuspended: false,
  };
}

describe('trusted-only permanent deletion rules', () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
    });
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await seed('users/alice', activeUser('alice'));
    await seed('users/bob', activeUser('bob'));
    await seed('users/admin', activeUser('admin', { admin: true }));
    await seed('privateProfiles/alice', {
      email: 'alice@example.com',
      privacyVersion: 1,
    });
    await seed('chats/alice_bob', {
      participants: ['alice', 'bob'],
    });
    await seed('users/alice/blocks/bob', {
      blockerId: 'alice',
      blockedUserId: 'bob',
      createdAt: new Date(0),
    });
  });

  after(async () => {
    await env.cleanup();
  });

  it('denies owner deletion of the public profile', async () => {
    await assertFails(deleteDoc(doc(authed('alice'), 'users/alice')));
  });

  it('denies owner deletion of the private profile', async () => {
    await assertFails(
      deleteDoc(doc(authed('alice'), 'privateProfiles/alice')),
    );
  });

  it('denies participant deletion of shared chat metadata', async () => {
    await assertFails(deleteDoc(doc(authed('alice'), 'chats/alice_bob')));
  });

  it('denies client-side admin deletion of profiles and chats', async () => {
    await assertFails(deleteDoc(doc(authed('admin'), 'users/bob')));
    await assertFails(deleteDoc(doc(authed('admin'), 'chats/alice_bob')));
  });

  it('still allows an active user to remove their own block record', async () => {
    await assertSucceeds(
      deleteDoc(doc(authed('alice'), 'users/alice/blocks/bob')),
    );
  });
});
