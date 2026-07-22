const assert = require('assert');
const fs = require('fs');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { serverTimestamp } = require('firebase/firestore');

const PROJECT_ID = 'nearmeu-privacy-rules-test';
let env;

function authed(uid) {
  return env.authenticatedContext(uid).firestore();
}

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(path).set(data);
  });
}

async function seedUser(uid, extra = {}) {
  await seed(`users/${uid}`, {
    uid,
    email: `${uid}@example.com`,
    nickname: uid,
    gender: 'Male',
    lookingFor: 'Female',
    age: 25,
    latitude: 23.2599,
    longitude: 77.4126,
    blockedUsers: [],
    isOnline: false,
    isSuspended: false,
    isAdmin: false,
    ...extra,
  });
}

async function seedPublicProfile(uid, extra = {}) {
  await seed(`publicProfiles/${uid}`, {
    uid,
    nickname: uid,
    gender: 'Male',
    lookingFor: 'Female',
    age: 25,
    state: 'Madhya Pradesh',
    photoUrl: null,
    approxLatitude: 23.3,
    approxLongitude: 77.4,
    createdAt: new Date(0),
    lastSeen: null,
    isOnline: false,
    isSuspended: false,
    updatedAt: new Date(0),
    ...extra,
  });
}

describe('privacy and block rules', () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
    });
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await seedUser('alice');
    await seedUser('bob');
    await seedUser('mallory');
    await seedUser('suspended', { isSuspended: true });
    await seedUser('admin', { isAdmin: true });
    await seedPublicProfile('alice');
    await seedPublicProfile('bob', {
      gender: 'Female',
      lookingFor: 'Male',
    });
    await seedPublicProfile('underage', { age: 17 });
    await seedPublicProfile('suspended', { isSuspended: true });
  });

  after(async () => {
    await env.cleanup();
  });

  it('keeps private profiles owner-only', async () => {
    await assertSucceeds(authed('alice').doc('users/alice').get());
    await assertFails(authed('alice').doc('users/bob').get());
    await assertSucceeds(authed('admin').doc('users/bob').get());
  });

  it('allows active users to read only the safe public directory', async () => {
    const publicSnapshot = await assertSucceeds(
      authed('alice')
        .collection('publicProfiles')
        .where('isSuspended', '==', false)
        .where('age', '>=', 18)
        .get(),
    );

    const ids = publicSnapshot.docs.map((doc) => doc.id).sort();
    assert.deepStrictEqual(ids, ['alice', 'bob']);

    const bob = publicSnapshot.docs.find((doc) => doc.id === 'bob').data();
    assert.strictEqual(Object.hasOwn(bob, 'email'), false);
    assert.strictEqual(Object.hasOwn(bob, 'latitude'), false);
    assert.strictEqual(Object.hasOwn(bob, 'longitude'), false);
    assert.strictEqual(Object.hasOwn(bob, 'blockedUsers'), false);
  });

  it('denies public profile writes from clients', async () => {
    await assertFails(
      authed('alice').doc('publicProfiles/alice').update({ nickname: 'fake' }),
    );
    await assertFails(
      authed('alice').doc('publicProfiles/new').set({
        uid: 'new',
        nickname: 'new',
        gender: 'Male',
        lookingFor: 'Female',
        age: 25,
        isOnline: false,
        isSuspended: false,
      }),
    );
  });

  it('denies suspended users access to the public directory', async () => {
    await assertFails(
      authed('suspended').doc('publicProfiles/alice').get(),
    );
  });

  it('creates a directional block edge owned by the blocker', async () => {
    const edge = authed('alice').doc('blocks/alice_bob');
    await assertSucceeds(
      edge.set({
        blockerId: 'alice',
        blockedId: 'bob',
        createdAt: serverTimestamp(),
      }),
    );

    await assertSucceeds(edge.get());
    await assertSucceeds(authed('bob').doc('blocks/alice_bob').get());
    await assertFails(authed('mallory').doc('blocks/alice_bob').get());
    await assertFails(authed('bob').doc('blocks/alice_bob').delete());
    await assertSucceeds(edge.delete());
  });

  it('allows an incoming-block query only for the affected user', async () => {
    await seed('blocks/alice_bob', {
      blockerId: 'alice',
      blockedId: 'bob',
      createdAt: new Date(0),
    });

    const incoming = await assertSucceeds(
      authed('bob')
        .collection('blocks')
        .where('blockedId', '==', 'bob')
        .get(),
    );
    assert.deepStrictEqual(incoming.docs.map((doc) => doc.id), ['alice_bob']);

    await assertFails(
      authed('mallory')
        .collection('blocks')
        .where('blockedId', '==', 'bob')
        .get(),
    );
  });
});
