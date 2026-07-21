const fs = require('node:fs');
const assert = require('node:assert');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { deleteField, doc, getDoc, serverTimestamp, setDoc, updateDoc } = require('firebase/firestore');

const projectId = 'nearmeu-rules-test';
let testEnv;

const user = (uid, extra = {}) => ({
  uid,
  email: `${uid}@example.com`,
  nickname: uid,
  age: 25,
  gender: 'Other',
  lookingFor: 'Both',
  createdAt: new Date('2026-01-01T00:00:00Z'),
  isAdmin: false,
  isSuspended: false,
  ...extra,
});

const chat = (overrides = {}) => ({
  participants: ['alice', 'bob'],
  lastMessage: 'hello',
  lastMessageTime: new Date('2026-01-01T00:00:00Z'),
  lastMessageSenderId: 'alice',
  createdAt: new Date('2026-01-01T00:00:00Z'),
  unreadCounts: { alice: 0, bob: 1 },
  readStates: {
    alice: { unreadCount: 0, lastReadAt: new Date('2026-01-01T00:00:00Z') },
    bob: { unreadCount: 1, lastReadAt: null },
  },
  ...overrides,
});

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
});

after(async () => testEnv.cleanup());

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/alice'), user('alice'));
    await setDoc(doc(db, 'users/bob'), user('bob'));
    await setDoc(doc(db, 'users/eve'), user('eve'));
    await setDoc(doc(db, 'users/admin1'), user('admin1', { isAdmin: true }));
    await setDoc(doc(db, 'users/admin2'), user('admin2', { isAdmin: true }));
    await setDoc(doc(db, 'chats/alice_bob'), chat());
  });
});

const authedDb = (uid) => testEnv.authenticatedContext(uid).firestore();

describe('chat unread/read states', () => {
  it('allows sender to increment recipient unread by exactly 1', async () => {
    const db = authedDb('alice');
    await assertSucceeds(updateDoc(doc(db, 'chats/alice_bob'), {
      lastMessage: 'next',
      lastMessageTime: serverTimestamp(),
      lastMessageSenderId: 'alice',
      'unreadCounts.bob': 2,
      'readStates.bob.unreadCount': 2,
    }));
  });

  it('rejects sender changing own unread improperly', async () => {
    const db = authedDb('alice');
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), {
      lastMessage: 'next',
      lastMessageTime: serverTimestamp(),
      lastMessageSenderId: 'alice',
      'unreadCounts.alice': 1,
      'readStates.alice.unreadCount': 1,
      'unreadCounts.bob': 2,
      'readStates.bob.unreadCount': 2,
    }));
  });

  it('rejects sender clearing recipient unread', async () => {
    const db = authedDb('alice');
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), {
      lastMessage: 'next',
      lastMessageTime: serverTimestamp(),
      lastMessageSenderId: 'alice',
      'unreadCounts.bob': 0,
      'readStates.bob.unreadCount': 0,
    }));
  });

  it('allows recipient to clear only their own unread', async () => {
    const db = authedDb('bob');
    await assertSucceeds(updateDoc(doc(db, 'chats/alice_bob'), {
      'unreadCounts.bob': 0,
      'readStates.bob.unreadCount': 0,
      'readStates.bob.lastReadAt': serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), {
      'unreadCounts.alice': 0,
      'readStates.alice.unreadCount': 0,
      'readStates.alice.lastReadAt': serverTimestamp(),
    }));
  });

  it('rejects third-party chat read/update', async () => {
    const db = authedDb('eve');
    await assertFails(getDoc(doc(db, 'chats/alice_bob')));
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { lastMessage: 'hacked' }));
  });

  it('rejects arbitrary replacement and literal dotted unread fields', async () => {
    const db = authedDb('alice');
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), {
      unreadCounts: { alice: 0, bob: 2, eve: 99 },
      readStates: {
        alice: { unreadCount: 0, lastReadAt: new Date('2026-01-01T00:00:00Z') },
        bob: { unreadCount: 2, lastReadAt: null },
      },
      lastMessage: 'next',
      lastMessageTime: serverTimestamp(),
      lastMessageSenderId: 'alice',
    }));
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), {
      'unreadCounts.bob': deleteField(),
      lastMessage: 'next',
      lastMessageTime: serverTimestamp(),
      lastMessageSenderId: 'alice',
    }));
  });
});

describe('announcements and user notification state', () => {
  it('rejects normal user announcement creation', async () => {
    const db = authedDb('alice');
    await assertFails(setDoc(doc(db, 'announcements/a1'), {
      title: 'Notice',
      body: 'Body',
      createdAt: serverTimestamp(),
      createdByAdminId: 'alice',
      expiresAt: null,
      expiredAt: null,
      isExpired: false,
    }));
  });

  it('allows any admin to expire without spoofing creator', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'announcements/a1'), {
        title: 'Notice',
        body: 'Body',
        createdAt: new Date('2026-01-01T00:00:00Z'),
        createdByAdminId: 'admin1',
        expiresAt: null,
        expiredAt: null,
        isExpired: false,
      });
    });
    const db = authedDb('admin2');
    await assertSucceeds(updateDoc(doc(db, 'announcements/a1'), {
      isExpired: true,
      expiredAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db, 'announcements/a1'), {
      isExpired: true,
      expiredAt: serverTimestamp(),
      createdByAdminId: 'admin2',
    }));
  });

  it('rejects editing another user notification/read state', async () => {
    const db = authedDb('alice');
    await assertFails(updateDoc(doc(db, 'users/bob'), {
      messageNotificationsEnabled: false,
      nearbyAlertsEnabled: false,
    }));
  });
});
