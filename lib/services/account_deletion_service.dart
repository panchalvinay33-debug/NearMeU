import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'local_chat_store.dart';
import 'local_preview_cache.dart';
import 'presence_service.dart';

class AccountDeletionService {
  AccountDeletionService({
    AuthService? authService,
    FirebaseFunctions? functions,
    LocalChatStore? localChatStore,
    LocalPreviewCache? previewCache,
  }) : _authService = authService ?? AuthService(),
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _localChatStore = localChatStore ?? LocalChatStore(),
       _previewCache = previewCache ?? LocalPreviewCache();

  final AuthService _authService;
  final FirebaseFunctions _functions;
  final LocalChatStore _localChatStore;
  final LocalPreviewCache _previewCache;
  bool _deletionInProgress = false;

  Future<void> deleteCurrentAccount() async {
    if (_deletionInProgress) {
      throw StateError('Account deletion is already in progress.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    _deletionInProgress = true;
    var serverDeletionCompleted = false;
    try {
      // Reauthentication refreshes auth_time; the backend independently
      // verifies that timestamp before any destructive cleanup starts.
      await _authService.reauthenticateCurrentUser();
      await PresenceService.instance.goOfflineBeforeSignOut();
      await _functions.httpsCallable('deleteCurrentAccount').call<void>();
      serverDeletionCompleted = true;

      try {
        await Future.wait<void>([
          _localChatStore.clearAccount(uid),
          _previewCache.clearChatPreviews(uid),
          _previewCache.clearNearbyCandidates(uid),
        ]);
      } catch (error, stackTrace) {
        // The cloud account is already gone. Never keep the user signed in just
        // because best-effort deletion of a local cache failed.
        developer.log(
          'Local account cache cleanup was incomplete',
          error: error,
          stackTrace: stackTrace,
        );
      }

      await _authService.clearLocalSessionAfterServerDeletion();
    } catch (_) {
      if (!serverDeletionCompleted) {
        await PresenceService.instance.restoreCurrentState();
      } else {
        await _authService.clearLocalSessionAfterServerDeletion();
      }
      rethrow;
    } finally {
      _deletionInProgress = false;
    }
  }
}
