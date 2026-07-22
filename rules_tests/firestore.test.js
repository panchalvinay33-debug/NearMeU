const assert = require('assert');
const fs = require('fs');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { serverTimestamp } = require('firebase/firestore');

const PROJECT_ID = 'nearmeu-rules-test';
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
  const chatRef = db.doc(`chats/${id}`);
  const messageRef = chatRef.collection('messages').doc();

  await db.runTransaction(async (transaction) => {
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

  return messageRef.id;
}

function messageRef(uid, senderId, receiverId, messageId) {
  return authed(uid).doc(
    `chats/${chatId(senderId, receiverId)}/messages/${messageId}`,
  );
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
    const snap = await authed('alice').doc('chats/alice_bob').get();
    assert.strictEqual(snap.data().unreadCounts.bob, 2);
    assert.strictEqual(snap.data().readStates.bob.unreadCount, 2);
  });

  it('safely initializes unread maps for a legacy chat', async () => {
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
    const snap = await authed('alice').doc('chats/alice_bob').get();
    assert.deepStrictEqual(
      Object.keys(snap.data().unreadCounts).sort(),
      ['alice', 'bob'],
    );
    assert.strictEqual(snap.data().unreadCounts.bob, 1);
  });

  it('rejects arbitrary unread map replacement', async () => {
    await seed('chats/alice_bob', {
      participants: ['alice', 'bob'],
      unreadCounts: { alice: 0, bob: 0 },
      readStates: {
        alice: { unreadCount: 0 },
        bob: { unreadCount: 0 },
      },
    });

    await assertFails(
      authed('alice').doc('chats/alice_bob').update({
        unreadCounts: { alice: 0, bob: 0, mallory: 99 },
      }),
    );
  });

  it('allows only the original sender to unsend', async () => {
    const id = await sendMessage('alice', 'bob', 'hello');
    const unsend = {
      text: '',
      isUnsent: true,
      unsentAt: serverTimestamp(),
      replyToMessageId: null,
      replyToText: null,
      replyToSenderId: null,
      type: 'text',
      mediaUrl: null,
    };

    await assertFails(messageRef('bob', 'alice', 'bob', id).update(unsend));
    await assertSucceeds(
      messageRef('alice', 'alice', 'bob', id).update(unsend),
    );
  });

  it('allows the sender to update the latest unsent preview', async () => {
    const id = await sendMessage('alice', 'bob', 'hello');
    await assertSucceeds(
      messageRef('alice', 'alice', 'bob', id).update({
        text: '',
        isUnsent: true,
        unsentAt: serverTimestamp(),
        replyToMessageId: null,
        replyToText: null,
        replyToSenderId: null,
        type: 'text',
        mediaUrl: null,
      }),
    );

    await assertSucceeds(
      authed('alice').doc('chats/alice_bob').update({
        lastMessage: 'This message was unsent',
        lastMessageTime: serverTimestamp(),
        latestMessageAt: serverTimestamp(),
        lastMessageSenderId: 'alice',
        latestSenderId: 'alice',
        lastMessageType: 'text',
        lastMessageIsUnsent: true,
      }),
    );
  });

  it('allows only the receiver to mark a message seen', async () => {
    const id = await sendMessage('alice', 'bob', 'hello');
    const seen = {
      isSeen: true,
      seenAt: serverTimestamp(),
    };

    await assertFails(messageRef('alice', 'alice', 'bob', id).update(seen));
    await assertSucceeds(messageRef('bob', 'alice', 'bob', id).update(seen));
  });

  it('allows delete-for-me only for the authenticated participant', async () => {
    const id = await sendMessage('alice', 'bob', 'hello');
    const ref = messageRef('alice', 'alice', 'bob', id);

    await assertSucceeds(ref.update({ deletedFor: ['alice'] }));
    await assertFails(ref.update({ deletedFor: ['alice', 'bob'] }));
  });

  it('rejects arbitrary participant message edits', async () => {
    const id = await sendMessage('alice', 'bob', 'hello');
    await assertFails(
      messageRef('bob', 'alice', 'bob', id).update({ text: 'tampered' }),
    );
  });

  it('keeps device tokens private to their owner', async () => {
    const device = authed('alice').doc('users/alice/devices/device-a');
    await assertSucceeds(
      device.set({
        token: 'a-valid-fcm-registration-token-value',
        platform: 'android',
        enabled: true,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    await assertSucceeds(device.get());
    await assertFails(
      authed('bob').doc('users/alice/devices/device-a').get(),
    );
    await assertFails(
      authed('bob').doc('users/alice/devices/device-b').set({
        token: 'another-valid-fcm-registration-token',
        platform: 'android',
        enabled: true,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('allows active user to list active announcements', async () => {
    await seed(
      'supportAnnouncements/active',
      announcement('adminA', {
        createdAt: new Date(2),
        expiresAt: new Date(0),
      }),
    );
    await seed(
      'supportAnnouncements/inactive',
      announcement('adminA', { isActive: false, createdAt: new Date(1) }),
    );

    const snap = await assertSucceeds(
      authed('alice')
        .collection('supportAnnouncements')
        .where('isActive', '==', true)
        .where('targetAudience', '==', 'allActiveUsers')
        .get(),
    );
    assert.deepStrictEqual(snap.docs.map((doc) => doc.id), ['active']);
  });

  it('rejects suspended user announcement reads', async () => {
    await seedUser('suspended', { isSuspended: true });
    await seed(
      'supportAnnouncements/active',
      announcement('adminA', { createdAt: new Date(0) }),
    );

    await assertFails(
      authed('suspended').doc('supportAnnouncements/active').get(),
    );
  });

  it('allows admin to create and expire announcements', async () => {
    const ref = authed('adminA')
      .collection('supportAnnouncements')
      .doc('ann1');
    await assertSucceeds(ref.set(announcement('adminA')));
    await assertSucceeds(
      authed('adminB').doc('supportAnnouncements/ann1').update({
        isActive: false,
        expiresAt: serverTimestamp(),
      }),
    );
    const snap = await authed('adminA')
      .doc('supportAnnouncements/ann1')
      .get();
    assert.strictEqual(snap.data().createdByAdminId, 'adminA');
    await assertFails(
      authed('adminA').doc('supportAnnouncements/ann1').delete(),
    );
  });

  it('rejects admin creator spoofing', async () => {
    await assertFails(
      authed('adminA')
        .collection('supportAnnouncements')
        .doc('spoof')
        .set(announcement('adminB')),
    );
  });

  it('rejects normal user announcement writes', async () => {
    await assertFails(
      authed('alice')
        .collection('supportAnnouncements')
        .doc('ann')
        .set(announcement('alice')),
    );
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
      authed('alice').doc('supportAnnouncements/ann').update({
        isActive: false,
        expiresAt: serverTimestamp(),
      }),
    );
  });
});
