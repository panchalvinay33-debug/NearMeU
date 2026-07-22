const assert = require('assert');
const fs = require('fs');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

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

async function readWithoutRules(path) {
  let snapshot;
  await env.withSecurityRulesDisabled(async (ctx) => {
    snapshot = await getDoc(doc(ctx.firestore(), path));
  });
  return snapshot;
}

async function seedUser(uid, extra = {}) {
  await seed(`users/${uid}`, {
    uid,
    age: 25,
    isSuspended: false,
    ...extra,
  });
}

function chatId(a, b) {
  return [a, b].sort().join('_');
}

async function sendMessage(senderId, receiverId, text) {
  const db = authed(senderId);
  const id = chatId(senderId, receiverId);
  const chatRef = doc(db, `chats/${id}`);
  const messageRef = doc(collection(chatRef, 'messages'));

  await runTransaction(db, async (transaction) => {
    const snap = await transaction.get(chatRef);
    const unreadCounts = snap.exists() ? (snap.data().unreadCounts || {}) : {};
    const receiverUnread = Number.isInteger(unreadCounts[receiverId])
      ? unreadCounts[receiverId]
      : 0;
    const nextUnread = receiverUnread + 1;
    const message = {
      senderId,
      receiverId,
      text,
      timestamp: serverTimestamp(),
      isUnsent: false,
      unsentAt: null,
      replyToMessageId: null,
      replyToText: null,
      replyToSenderId: null,
      type: 'text',
      mediaUrl: null,
      isSeen: false,
      seenAt: null,
      deletedFor: [],
    };

    if (snap.exists()) {
      transaction.update(chatRef, {
        lastMessage: text,
        lastMessageTime: serverTimestamp(),
        latestMessageAt: serverTimestamp(),
        lastMessageSenderId: senderId,
        latestSenderId: senderId,
        lastMessageType: 'text',
        lastMessageIsUnsent: false,
        [`unreadCounts.${senderId}`]: 0,
        [`unreadCounts.${receiverId}`]: nextUnread,
        [`readStates.${senderId}.lastReadAt`]: serverTimestamp(),
        [`readStates.${senderId}.lastReadMessageId`]: messageRef.id,
        [`readStates.${senderId}.unreadCount`]: 0,
        [`readStates.${receiverId}.unreadCount`]: nextUnread,
      });
    } else {
      transaction.set(chatRef, {
        participants: [senderId, receiverId].sort(),
        lastMessage: text,
        lastMessageTime: serverTimestamp(),
        latestMessageAt: serverTimestamp(),
        lastMessageSenderId: senderId,
        latestSenderId: senderId,
        lastMessageType: 'text',
        lastMessageIsUnsent: false,
        createdAt: serverTimestamp(),
        unreadCounts: { [senderId]: 0, [receiverId]: nextUnread },
        readStates: {
          [senderId]: {
            lastReadAt: serverTimestamp(),
            lastReadMessageId: messageRef.id,
            unreadCount: 0,
          },
          [receiverId]: { unreadCount: nextUnread },
        },
      });
    }

    transaction.set(messageRef, message);
  });
}

function announcement(adminId, overrides = {}) {
  return {
    title: 'Safety update',
    message: 'Please keep conversations respectful.',
    priority: 'normal',
    type: 'official_announcement',
    targetAudience: 'allActiveUsers',
    isActive: true,
    createdByAdminId: adminId,
    createdAt: serverTimestamp(),
    expiresAt: null,
    ...overrides,
  };
}

describe('firestore rules', () => {
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
    await seedUser('adminA', { isAdmin: true });
    await seedUser('adminB', { isAdmin: true });
  });

  after(async () => {
    await env.cleanup();
  });

  it('allows two consecutive messages before receiver ever reads', async () => {
    await assertSucceeds(sendMessage('alice', 'bob', 'first'));
    await assertSucceeds(sendMessage('alice', 'bob', 'second'));

    const internalSnap = await readWithoutRules('chats/alice_bob');
    assert.strictEqual(internalSnap.exists(), true, 'chat document must exist');
    assert.deepStrictEqual(
      internalSnap.data().participants,
      ['alice', 'bob'],
      'chat participants must be preserved',
    );

    const snap = await assertSucceeds(
      getDoc(doc(authed('alice'), 'chats/alice_bob')),
    );
    assert.strictEqual(snap.data().unreadCounts.bob, 2);
    assert.strictEqual(snap.data().readStates.bob.unreadCount, 2);
  });

  it('safely initializes unread maps for a legacy chat during valid delivery', async () => {
    await seed('chats/alice_bob', {
      participants: ['alice', 'bob'],
      lastMessage: 'legacy',
      lastMessageTime: new Date(0),
      latestMessageAt: new Date(0),
      lastMessageSenderId: 'bob',
      latestSenderId: 'bob',
      lastMessageType: 'text',
      lastMessageIsUnsent: false,
      createdAt: new Date(0),
    });

    await assertSucceeds(sendMessage('alice', 'bob', 'after upgrade'));
    const snap = await getDoc(doc(authed('alice'), 'chats/alice_bob'));
    assert.deepStrictEqual(
      Object.keys(snap.data().unreadCounts).sort(),
      ['alice', 'bob'],
    );
    assert.strictEqual(snap.data().unreadCounts.bob, 1);
    assert.strictEqual(snap.data().readStates.bob.unreadCount, 1);
  });

  it('rejects arbitrary unread map replacement with extra participants', async () => {
    await seed('chats/alice_bob', {
      participants: ['alice', 'bob'],
      unreadCounts: { alice: 0, bob: 0 },
      readStates: {
        alice: { unreadCount: 0 },
        bob: { unreadCount: 0 },
      },
    });

    await assertFails(
      updateDoc(doc(authed('alice'), 'chats/alice_bob'), {
        unreadCounts: { alice: 0, bob: 0, mallory: 99 },
      }),
    );
  });

  it('allows active user to list active all-user announcements', async () => {
    await seed(
      'supportAnnouncements/active',
      announcement('adminA', {
        createdAt: new Date(2),
        expiresAt: new Date(0),
      }),
    );
    await seed(
      'supportAnnouncements/inactive',
      announcement('adminA', {
        isActive: false,
        createdAt: new Date(1),
      }),
    );

    const announcementsQuery = query(
      collection(authed('alice'), 'supportAnnouncements'),
      where('isActive', '==', true),
      where('targetAudience', '==', 'allActiveUsers'),
    );
    const snap = await assertSucceeds(getDocs(announcementsQuery));
    assert.deepStrictEqual(snap.docs.map((item) => item.id), ['active']);
  });

  it('rejects suspended user support announcement reads', async () => {
    await seedUser('suspended', { isSuspended: true });
    await seed(
      'supportAnnouncements/active',
      announcement('adminA', { createdAt: new Date(0) }),
    );

    await assertFails(
      getDoc(doc(authed('suspended'), 'supportAnnouncements/active')),
    );

    const announcementsQuery = query(
      collection(authed('suspended'), 'supportAnnouncements'),
      where('isActive', '==', true),
      where('targetAudience', '==', 'allActiveUsers'),
    );
    await assertFails(getDocs(announcementsQuery));
  });

  it('allows admin to create and expire announcements', async () => {
    const ref = doc(collection(authed('adminA'), 'supportAnnouncements'), 'ann1');
    await assertSucceeds(setDoc(ref, announcement('adminA')));
    await assertSucceeds(
      updateDoc(doc(authed('adminB'), 'supportAnnouncements/ann1'), {
        isActive: false,
        expiresAt: serverTimestamp(),
      }),
    );

    const snap = await getDoc(
      doc(authed('adminA'), 'supportAnnouncements/ann1'),
    );
    assert.strictEqual(snap.data().createdByAdminId, 'adminA');
    await assertFails(deleteDoc(ref));
  });

  it('rejects admin creator spoofing', async () => {
    const ref = doc(collection(authed('adminA'), 'supportAnnouncements'), 'spoof');
    await assertFails(setDoc(ref, announcement('adminB')));
  });

  it('rejects normal user announcement writes', async () => {
    const ref = doc(collection(authed('alice'), 'supportAnnouncements'), 'ann');
    await assertFails(setDoc(ref, announcement('alice')));

    await seed('supportAnnouncements/ann', {
      title: 't',
      message: 'm',
      priority: 'normal',
      type: 'official_announcement',
      targetAudience: 'allActiveUsers',
      isActive: true,
      createdByAdminId: 'adminA',
      createdAt: new Date(0),
      expiresAt: null,
    });

    await assertFails(
      updateDoc(doc(authed('alice'), 'supportAnnouncements/ann'), {
        isActive: false,
        expiresAt: serverTimestamp(),
      }),
    );
    await assertFails(
      deleteDoc(doc(authed('alice'), 'supportAnnouncements/ann')),
    );
  });
});
