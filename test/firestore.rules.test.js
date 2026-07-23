const fs = require('fs');
const assert = require('assert');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, FieldPath, serverTimestamp } = require('firebase/firestore');

describe('chat unread/read state rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'nearmeu-rules-test',
      firestore: {
        rules: fs.readFileSync('firestore.rules', 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/alice'), {
        uid: 'alice',
        age: 21,
        isSuspended: false,
      });
      await setDoc(doc(db, 'users/bob'), {
        uid: 'bob',
        age: 22,
        isSuspended: false,
      });
      await setDoc(doc(db, 'chats/alice_bob'), baseChat());
    });
  });

  function authedDb(uid) {
    return testEnv.authenticatedContext(uid).firestore();
  }

  function baseChat(overrides = {}) {
    return {
      participants: ['alice', 'bob'],
      lastMessage: 'hello',
      lastMessageTime: new Date('2026-01-01T00:00:00Z'),
      latestMessageAt: new Date('2026-01-01T00:00:00Z'),
      lastMessageSenderId: 'alice',
      latestSenderId: 'alice',
      lastMessageType: 'text',
      lastMessageIsUnsent: false,
      createdAt: new Date('2026-01-01T00:00:00Z'),
      unreadCounts: { alice: 0, bob: 1 },
      readStates: {
        alice: {
          unreadCount: 0,
          lastReadAt: new Date('2026-01-01T00:00:00Z'),
          lastReadMessageId: 'm0',
        },
        bob: {
          unreadCount: 1,
          lastReadAt: new Date('2026-01-01T00:00:00Z'),
          lastReadMessageId: 'm-old',
        },
      },
      ...overrides,
    };
  }

  function deliveryUpdate(overrides = {}) {
    return {
      lastMessage: 'next',
      lastMessageTime: serverTimestamp(),
      latestMessageAt: serverTimestamp(),
      lastMessageSenderId: 'alice',
      latestSenderId: 'alice',
      lastMessageType: 'text',
      lastMessageIsUnsent: false,
      unreadCounts: {
        alice: 0,
        bob: 2,
      },
      readStates: {
        alice: {
          unreadCount: 0,
          lastReadAt: serverTimestamp(),
          lastReadMessageId: 'm1',
        },
        bob: {
          unreadCount: 2,
          lastReadAt: new Date('2026-01-01T00:00:00Z'),
          lastReadMessageId: 'm-old',
        },
      },
      ...overrides,
    };
  }

  it('rejects an extra unreadCounts user ID', async () => {
    const db = authedDb('alice');
    await assertFails(
      updateDoc(
        doc(db, 'chats/alice_bob'),
        deliveryUpdate({ unreadCounts: { alice: 0, bob: 2, mallory: 1 } }),
      ),
    );
  });

  it('rejects an extra readStates user ID', async () => {
    const db = authedDb('alice');
    await assertFails(
      updateDoc(
        doc(db, 'chats/alice_bob'),
        deliveryUpdate({
          readStates: {
            alice: {
              unreadCount: 0,
              lastReadAt: serverTimestamp(),
              lastReadMessageId: 'm1',
            },
            bob: {
              unreadCount: 2,
              lastReadAt: new Date('2026-01-01T00:00:00Z'),
              lastReadMessageId: 'm-old',
            },
            mallory: { unreadCount: 1 },
          },
        }),
      ),
    );
  });

  it('rejects changing the other user lastReadAt during delivery', async () => {
    const db = authedDb('alice');
    await assertFails(
      updateDoc(
        doc(db, 'chats/alice_bob'),
        deliveryUpdate({
          readStates: {
            alice: {
              unreadCount: 0,
              lastReadAt: serverTimestamp(),
              lastReadMessageId: 'm1',
            },
            bob: {
              unreadCount: 2,
              lastReadAt: serverTimestamp(),
              lastReadMessageId: 'm-old',
            },
          },
        }),
      ),
    );
  });

  it('rejects changing the other user lastReadMessageId during delivery', async () => {
    const db = authedDb('alice');
    await assertFails(
      updateDoc(
        doc(db, 'chats/alice_bob'),
        deliveryUpdate({
          readStates: {
            alice: {
              unreadCount: 0,
              lastReadAt: serverTimestamp(),
              lastReadMessageId: 'm1',
            },
            bob: {
              unreadCount: 2,
              lastReadAt: new Date('2026-01-01T00:00:00Z'),
              lastReadMessageId: 'tampered',
            },
          },
        }),
      ),
    );
  });

  it('rejects a correctly shaped direct client delivery update', async () => {
    const db = authedDb('alice');
    await assertFails(
      updateDoc(doc(db, 'chats/alice_bob'), deliveryUpdate()),
    );
  });

  it('accepts own mark-as-read updates only', async () => {
    const db = authedDb('bob');
    await assertSucceeds(
      updateDoc(doc(db, 'chats/alice_bob'), {
        unreadCounts: { alice: 0, bob: 0 },
        readStates: {
          alice: {
            unreadCount: 0,
            lastReadAt: new Date('2026-01-01T00:00:00Z'),
            lastReadMessageId: 'm0',
          },
          bob: {
            unreadCount: 0,
            lastReadAt: serverTimestamp(),
            lastReadMessageId: 'm1',
          },
        },
      }),
    );
  });

  it('allows client FieldPath mark-as-read update', async () => {
    const db = authedDb('bob');
    await assertSucceeds(
      updateDoc(
        doc(db, 'chats/alice_bob'),
        new FieldPath('unreadCounts', 'bob'),
        0,
        new FieldPath('readStates', 'bob', 'unreadCount'),
        0,
        new FieldPath('readStates', 'bob', 'lastReadAt'),
        serverTimestamp(),
        new FieldPath('readStates', 'bob', 'lastReadMessageId'),
        'm1',
      ),
    );
    const snap = await getDoc(doc(db, 'chats/alice_bob'));
    assert.strictEqual(snap.data().unreadCounts.bob, 0);
  });
});


describe('support announcement read rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'nearmeu-announcement-rules-test',
      firestore: {
        rules: fs.readFileSync('firestore.rules', 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/alice'), {
        uid: 'alice',
        age: 21,
        isSuspended: false,
      });
      await setDoc(doc(db, 'supportAnnouncements/expiredActive'), {
        title: 'Expired but still active',
        message: 'The client filters this out after reading.',
        priority: 'normal',
        type: 'support',
        targetAudience: 'allActiveUsers',
        isActive: true,
        createdByAdminId: 'admin',
        createdAt: new Date('2026-01-01T00:00:00Z'),
        expiresAt: new Date('2026-01-02T00:00:00Z'),
      });
      await setDoc(doc(db, 'supportAnnouncements/inactive'), {
        title: 'Inactive',
        message: 'Hidden from active users.',
        priority: 'normal',
        type: 'support',
        targetAudience: 'allActiveUsers',
        isActive: false,
        createdByAdminId: 'admin',
        createdAt: new Date('2026-01-01T00:00:00Z'),
        expiresAt: new Date('2026-01-02T00:00:00Z'),
      });
    });
  });

  function authedDb(uid) {
    return testEnv.authenticatedContext(uid).firestore();
  }

  it('allows active users to read active all-user announcements regardless of expiresAt', async () => {
    const db = authedDb('alice');
    await assertSucceeds(getDoc(doc(db, 'supportAnnouncements/expiredActive')));
  });

  it('still rejects inactive announcements for active users', async () => {
    const db = authedDb('alice');
    await assertFails(getDoc(doc(db, 'supportAnnouncements/inactive')));
  });
});
