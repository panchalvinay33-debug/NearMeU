const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  deleteDoc,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require('firebase/firestore');
const fs = require('fs');

const PROJECT_ID = 'demo-nearmeu-rules-test';
const CHAT_ID = 'alice_bob';
const MESSAGE_PATH = `chats/${CHAT_ID}/messages/message-1`;
let env;

function authed(uid) {
  return env.authenticatedContext(uid).firestore();
}

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

async function seedFixture() {
  await seed('users/alice', {
    uid: 'alice',
    age: 25,
    isSuspended: false,
  });
  await seed('users/bob', {
    uid: 'bob',
    age: 25,
    isSuspended: false,
  });
  await seed('users/mallory', {
    uid: 'mallory',
    age: 25,
    isSuspended: false,
  });
  await seed(`chats/${CHAT_ID}`, {
    participants: ['alice', 'bob'],
    lastMessage: 'hello',
    lastMessageTime: new Date(0),
    latestMessageAt: new Date(0),
    lastMessageSenderId: 'alice',
    latestSenderId: 'alice',
    lastMessageType: 'text',
    lastMessageIsUnsent: false,
    createdAt: new Date(0),
    unreadCounts: { alice: 0, bob: 1 },
    readStates: {
      alice: {
        lastReadAt: new Date(0),
        lastReadMessageId: 'message-1',
        unreadCount: 0,
      },
      bob: { unreadCount: 1 },
    },
  });
  await seed(MESSAGE_PATH, {
    senderId: 'alice',
    receiverId: 'bob',
    text: 'hello',
    timestamp: new Date(0),
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
  });
}

describe('message security rules', () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
    });
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await seedFixture();
  });

  after(async () => {
    await env.cleanup();
  });

  it('allows only the original sender to unsend', async () => {
    await assertSucceeds(
      updateDoc(doc(authed('alice'), MESSAGE_PATH), {
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

    await assertFails(
      updateDoc(doc(authed('bob'), MESSAGE_PATH), {
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
  });

  it('allows only the receiver to mark a message seen', async () => {
    await assertSucceeds(
      updateDoc(doc(authed('bob'), MESSAGE_PATH), {
        isSeen: true,
        seenAt: serverTimestamp(),
      }),
    );

    await assertFails(
      updateDoc(doc(authed('alice'), MESSAGE_PATH), {
        isSeen: true,
        seenAt: serverTimestamp(),
      }),
    );
  });

  it('allows a participant to add only their own delete-for-me marker', async () => {
    await assertSucceeds(
      updateDoc(doc(authed('alice'), MESSAGE_PATH), {
        deletedFor: ['alice'],
      }),
    );

    await assertFails(
      updateDoc(doc(authed('alice'), MESSAGE_PATH), {
        deletedFor: ['bob'],
      }),
    );

    await assertFails(
      updateDoc(doc(authed('mallory'), MESSAGE_PATH), {
        deletedFor: ['mallory'],
      }),
    );
  });

  it('rejects identity, timestamp, and text tampering', async () => {
    await assertFails(
      updateDoc(doc(authed('alice'), MESSAGE_PATH), {
        senderId: 'bob',
      }),
    );
    await assertFails(
      updateDoc(doc(authed('bob'), MESSAGE_PATH), {
        receiverId: 'alice',
      }),
    );
    await assertFails(
      updateDoc(doc(authed('alice'), MESSAGE_PATH), {
        timestamp: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(authed('alice'), MESSAGE_PATH), {
        text: 'edited after sending',
      }),
    );
  });

  it('rejects permanent client-side message deletion', async () => {
    await assertFails(deleteDoc(doc(authed('alice'), MESSAGE_PATH)));
    await assertFails(deleteDoc(doc(authed('bob'), MESSAGE_PATH)));
  });
});
