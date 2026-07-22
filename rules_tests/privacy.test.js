const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');
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

function publicUser(uid, overrides = {}) {
  return {
    uid,
    nickname: uid,
    gender: uid === 'alice' ? 'Male' : 'Female',
    lookingFor: uid === 'alice' ? 'Female' : 'Male',
    createdAt: new Date(0),
    approxLatitude: 23.26,
    approxLongitude: 77.41,
    locationCell: '56:128',
    discoveryCells: [
      '55:127',
      '55:128',
      '55:129',
      '56:127',
      '56:128',
      '56:129',
      '57:127',
      '57:128',
      '57:129',
    ],
    state: 'Madhya Pradesh',
    country: 'India',
    photoUrl: null,
    age: 25,
    lastSeen: null,
    isOnline: false,
    isAdmin: false,
    isSuspended: false,
    privacyVersion: 1,
    ...overrides,
  };
}

describe('profile and location privacy rules', () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
    });
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await seed('users/alice', publicUser('alice'));
    await seed('users/bob', publicUser('bob'));
    await seed(
      'users/mallory',
      publicUser('mallory', {
        approxLatitude: 28.61,
        approxLongitude: 77.21,
        locationCell: '59:128',
        discoveryCells: [
          '58:127',
          '58:128',
          '58:129',
          '59:127',
          '59:128',
          '59:129',
          '60:127',
          '60:128',
          '60:129',
        ],
      }),
    );
  });

  after(async () => {
    await env.cleanup();
  });

  it('rejects sensitive account and exact location fields on public users', async () => {
    await assertFails(
      updateDoc(doc(authed('alice'), 'users/alice'), {
        email: 'alice@example.com',
        latitude: 23.259912,
        longitude: 77.412612,
        city: 'Bhopal',
        blockedUsers: ['bob'],
      }),
    );
  });

  it('allows only the owner to read and write a private profile', async () => {
    const path = 'privateProfiles/alice';
    await assertSucceeds(
      setDoc(doc(authed('alice'), path), {
        email: 'alice@example.com',
        exactLatitude: 23.259912,
        exactLongitude: 77.412612,
        city: 'Bhopal',
        messageNotificationsEnabled: true,
        nearbyAlertsEnabled: false,
        privacyVersion: 1,
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(getDoc(doc(authed('alice'), path)));
    await assertFails(getDoc(doc(authed('bob'), path)));
  });

  it('allows bounded discovery-cell queries and rejects a global directory query', async () => {
    const cells = publicUser('alice').discoveryCells;
    const boundedQuery = query(
      collection(authed('alice'), 'users'),
      where('locationCell', 'in', cells),
      limit(50),
    );
    const bounded = await assertSucceeds(getDocs(boundedQuery));
    const ids = bounded.docs.map((item) => item.id).sort();
    if (ids.join(',') !== 'alice,bob') {
      throw new Error(`Unexpected bounded result: ${ids.join(',')}`);
    }

    await assertFails(
      getDocs(query(collection(authed('alice'), 'users'), limit(50))),
    );
  });

  it('denies direct far-profile reads unless users share a chat', async () => {
    await assertFails(getDoc(doc(authed('alice'), 'users/mallory')));
    await seed('chats/alice_mallory', {
      participants: ['alice', 'mallory'],
    });
    await assertSucceeds(getDoc(doc(authed('alice'), 'users/mallory')));
  });

  it('hides legacy data and permits only a controlled owner migration', async () => {
    await seed('users/legacy', {
      uid: 'legacy',
      email: 'legacy@example.com',
      nickname: 'legacy',
      gender: 'Female',
      lookingFor: 'Male',
      createdAt: new Date(0),
      latitude: 23.259912,
      longitude: 77.412612,
      city: 'Bhopal',
      blockedUsers: [],
      age: 25,
      isOnline: false,
      isSuspended: false,
    });
    await seed('chats/alice_legacy', {
      participants: ['alice', 'legacy'],
    });

    await assertSucceeds(getDoc(doc(authed('legacy'), 'users/legacy')));
    await assertFails(getDoc(doc(authed('alice'), 'users/legacy')));

    await assertSucceeds(
      setDoc(
        doc(authed('legacy'), 'privateProfiles/legacy'),
        {
          email: 'legacy@example.com',
          exactLatitude: 23.259912,
          exactLongitude: 77.412612,
          city: 'Bhopal',
          messageNotificationsEnabled: true,
          nearbyAlertsEnabled: false,
          privacyVersion: 1,
          updatedAt: serverTimestamp(),
        },
      ),
    );
    await assertSucceeds(
      setDoc(doc(authed('legacy'), 'users/legacy'), publicUser('legacy')),
    );

    await assertSucceeds(getDoc(doc(authed('alice'), 'users/legacy')));
    await assertFails(
      getDoc(doc(authed('alice'), 'privateProfiles/legacy')),
    );
  });

  it('exposes a block record only to the blocker and blocked user', async () => {
    const path = 'users/alice/blocks/bob';
    await assertSucceeds(
      setDoc(doc(authed('alice'), path), {
        blockerId: 'alice',
        blockedUserId: 'bob',
        createdAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(getDoc(doc(authed('alice'), path)));
    await assertSucceeds(getDoc(doc(authed('bob'), path)));
    await assertFails(getDoc(doc(authed('mallory'), path)));
    await assertFails(deleteDoc(doc(authed('bob'), path)));
    await assertSucceeds(deleteDoc(doc(authed('alice'), path)));
  });
});
