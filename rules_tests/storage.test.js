const fs = require('fs');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');
const {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} = require('firebase/storage');

const PROJECT_ID = 'demo-nearmeu-rules-test';
const BUCKET = `gs://${PROJECT_ID}.appspot.com`;
let env;

function chatId(firstUid, secondUid) {
  return [firstUid, secondUid].sort().join('_');
}

function storageFor(uid) {
  return env.authenticatedContext(uid).storage(BUCKET);
}

function mediaPath({ senderId, receiverId, messageId = 'message_1234567890' }) {
  return `privateChatMedia/${senderId}/${chatId(senderId, receiverId)}/${messageId}/upload.jpg`;
}

function validImageMetadata({ senderId, receiverId, messageId = 'message_1234567890' }) {
  return {
    contentType: 'image/jpeg',
    customMetadata: {
      senderId,
      receiverId,
      chatId: chatId(senderId, receiverId),
      messageId,
      mediaType: 'image',
    },
  };
}

async function seedChat(firstUid, secondUid) {
  const id = chatId(firstUid, secondUid);
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `chats/${id}`), {
      participants: [firstUid, secondUid].sort(),
      createdAt: new Date(),
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync('firestore.rules', 'utf8'),
    },
    storage: {
      rules: fs.readFileSync('storage.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await Promise.all([env.clearFirestore(), env.clearStorage()]);
});

after(async () => {
  await env.cleanup();
});

describe('private media Storage rules', () => {
  const senderId = 'sender-user';
  const receiverId = 'receiver-user';
  const unrelatedId = 'unrelated-user';
  const messageId = 'message_1234567890';

  it('allows the sender to upload, read, and delete valid private media', async () => {
    const storage = storageFor(senderId);
    const fileRef = ref(
      storage,
      mediaPath({ senderId, receiverId, messageId }),
    );
    const bytes = new Uint8Array([1, 2, 3, 4]);

    await assertSucceeds(
      uploadBytes(
        fileRef,
        bytes,
        validImageMetadata({ senderId, receiverId, messageId }),
      ),
    );
    await assertSucceeds(getBytes(fileRef));
    await assertSucceeds(deleteObject(fileRef));
  });

  it('rejects uploads made under another sender identity', async () => {
    const attackerStorage = storageFor(unrelatedId);
    const fileRef = ref(
      attackerStorage,
      mediaPath({ senderId, receiverId, messageId }),
    );

    await assertFails(
      uploadBytes(
        fileRef,
        new Uint8Array([1]),
        validImageMetadata({ senderId, receiverId, messageId }),
      ),
    );
  });

  it('allows only verified chat participants to read receiver media', async () => {
    const senderStorage = storageFor(senderId);
    const path = mediaPath({ senderId, receiverId, messageId });
    const senderRef = ref(senderStorage, path);
    await assertSucceeds(
      uploadBytes(
        senderRef,
        new Uint8Array([1, 2, 3]),
        validImageMetadata({ senderId, receiverId, messageId }),
      ),
    );

    const receiverRefBeforeChat = ref(storageFor(receiverId), path);
    await assertFails(getBytes(receiverRefBeforeChat));

    await seedChat(senderId, receiverId);
    await assertSucceeds(getBytes(receiverRefBeforeChat));
    await assertFails(getBytes(ref(storageFor(unrelatedId), path)));
    await assertFails(
      getBytes(ref(env.unauthenticatedContext().storage(BUCKET), path)),
    );
  });

  it('rejects invalid metadata, content types, and oversized photos', async () => {
    const storage = storageFor(senderId);
    const path = mediaPath({ senderId, receiverId, messageId });

    await assertFails(
      uploadBytes(ref(storage, path), new Uint8Array([1]), {
        contentType: 'image/jpeg',
        customMetadata: {
          senderId,
          receiverId,
          chatId: 'wrong-chat',
          messageId,
          mediaType: 'image',
        },
      }),
    );

    await assertFails(
      uploadBytes(
        ref(storage, path),
        new Uint8Array([1]),
        {
          ...validImageMetadata({ senderId, receiverId, messageId }),
          contentType: 'image/gif',
        },
      ),
    );

    await assertFails(
      uploadBytes(
        ref(storage, path),
        new Uint8Array(5 * 1024 * 1024 + 1),
        validImageMetadata({ senderId, receiverId, messageId }),
      ),
    );
  });

  it('prevents receivers from replacing or deleting sender-owned media', async () => {
    const path = mediaPath({ senderId, receiverId, messageId });
    const senderRef = ref(storageFor(senderId), path);
    await assertSucceeds(
      uploadBytes(
        senderRef,
        new Uint8Array([1, 2, 3]),
        validImageMetadata({ senderId, receiverId, messageId }),
      ),
    );
    await seedChat(senderId, receiverId);

    const receiverRef = ref(storageFor(receiverId), path);
    await assertFails(
      uploadBytes(
        receiverRef,
        new Uint8Array([4, 5, 6]),
        validImageMetadata({ senderId, receiverId, messageId }),
      ),
    );
    await assertFails(deleteObject(receiverRef));
  });
});
