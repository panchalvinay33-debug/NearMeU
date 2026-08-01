import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/services/chat_clear_policy.dart';

void main() {
  test('reads per-user clear cutoff from chat state', () {
    final clearedAt = DateTime(2026, 8, 1, 12, 30);
    final result = ChatClearPolicy.clearedAtForUser(<String, dynamic>{
      'clearStates': <String, dynamic>{
        'owner': <String, dynamic>{'clearedAt': Timestamp.fromDate(clearedAt)},
      },
    }, 'owner');

    expect(result, clearedAt);
  });

  test('message at exact clear boundary stays hidden', () {
    final cutoff = DateTime(2026, 8, 1, 12);
    expect(
      ChatClearPolicy.isVisibleAfterClear(
        messageTimestamp: cutoff,
        clearedAt: cutoff,
      ),
      isFalse,
    );
    expect(
      ChatClearPolicy.isVisibleAfterClear(
        messageTimestamp: cutoff.add(const Duration(milliseconds: 1)),
        clearedAt: cutoff,
      ),
      isTrue,
    );
  });

  test('chat preview only returns after a newer message', () {
    final cutoff = DateTime(2026, 8, 1, 12);
    expect(
      ChatClearPolicy.shouldShowChatPreview(
        lastMessageTime: cutoff,
        clearedAt: cutoff,
      ),
      isFalse,
    );
    expect(
      ChatClearPolicy.shouldShowChatPreview(
        lastMessageTime: cutoff.add(const Duration(seconds: 1)),
        clearedAt: cutoff,
      ),
      isTrue,
    );
  });
}
