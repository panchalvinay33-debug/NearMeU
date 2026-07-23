const fs = require('fs');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
} = require('firebase/firestore');

const PROJECT_ID = 'demo-nearmeu-anti-abuse-rules';
let env;

function authed(uid) {
  return env.authenticatedContext(uid).firestore();
}

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

function reportPayload(overrides = {}) {
  return {
    reporterId: 'alice',
    reportedUserId: 'bob',
    reporterName: 'Untrusted client value',
    reporterPhoto: '',
    reportedUserName: 'Untrusted client value',
    reportedUserPhoto: '',
    reason: 'Spam',
    description: 'Repeated unwanted messages',
    status: 'pending',
    createdAt: serverTimestamp(),
    reviewedAt: null,
    reviewedBy: null,
    action: null,
    ...overrides,
  };
}

describe('anti-abuse Firestore rules', () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
    });
  });

  beforeEach(async () => {
    await env.clearFirestore();
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
  });

  after(async () => {
    await env.cleanup();
  });

  it('allows a validated report when the trusted backend has not restricted it', async () => {
    await assertSucceeds(
      setDoc(doc(authed('alice'), 'reports/report-1'), reportPayload()),
    );
  });

  it('rejects report creation while the trusted backend restriction is active', async () => {
    await seed('antiAbuseUsers/alice', {
      reportRestrictedUntil: new Date(Date.now() + 60 * 60 * 1000),
    });

    await assertFails(
      setDoc(doc(authed('alice'), 'reports/report-2'), reportPayload()),
    );
  });

  it('does not expose anti-abuse counters, report locks, or audit logs to clients', async () => {
    await seed('antiAbuseUsers/alice', { messageCount: 3 });
    await seed('reportLocks/lock-1', { reporterId: 'alice' });
    await seed('moderationAuditLogs/log-1', { actorId: 'alice' });

    await assertFails(getDoc(doc(authed('alice'), 'antiAbuseUsers/alice')));
    await assertFails(getDoc(doc(authed('alice'), 'reportLocks/lock-1')));
    await assertFails(getDoc(doc(authed('alice'), 'moderationAuditLogs/log-1')));

    await assertFails(
      setDoc(doc(authed('alice'), 'antiAbuseUsers/alice'), { messageCount: 0 }),
    );
    await assertFails(
      setDoc(doc(authed('alice'), 'reportLocks/lock-2'), { reporterId: 'alice' }),
    );
    await assertFails(
      setDoc(doc(authed('alice'), 'moderationAuditLogs/log-2'), { actorId: 'alice' }),
    );
  });
});
