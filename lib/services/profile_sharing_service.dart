import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';

class ProfileShareLink {
  const ProfileShareLink({
    required this.publicId,
    required this.url,
    required this.enabled,
  });

  final String publicId;
  final String url;
  final bool enabled;
}

class ProfileSharingService {
  ProfileSharingService._();

  static final ProfileSharingService instance = ProfileSharingService._();

  static const MethodChannel _channel = MethodChannel(
    'com.nearmeu.nearmeu/profile_sharing',
  );

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );

  Future<T> _callWithAuthRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'unauthenticated') rethrow;
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      return action();
    }
  }

  ProfileShareLink _parseLink(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    return ProfileShareLink(
      publicId: map['publicId'] as String? ?? '',
      url: map['url'] as String? ?? '',
      enabled: map['enabled'] == true,
    );
  }

  Future<ProfileShareLink> getMyShareLink() {
    return _callWithAuthRetry(() async {
      final result = await _functions.httpsCallable('getMyProfileShareLink').call();
      return _parseLink(result.data);
    });
  }

  Future<ProfileShareLink> setSharingEnabled(bool enabled) {
    return _callWithAuthRetry(() async {
      final result = await _functions
          .httpsCallable('setMyProfileSharingEnabled')
          .call(<String, dynamic>{'enabled': enabled});
      final map = Map<String, dynamic>.from(result.data as Map);
      if (map['url'] == null) {
        return const ProfileShareLink(publicId: '', url: '', enabled: false);
      }
      return _parseLink(map);
    });
  }

  Future<ProfileShareLink> rotateShareLink() {
    return _callWithAuthRetry(() async {
      final result = await _functions.httpsCallable('rotateMyProfileShareLink').call();
      return _parseLink(result.data);
    });
  }

  Future<AppUser> resolveSharedProfile(String publicId) {
    return _callWithAuthRetry(() async {
      final result = await _functions
          .httpsCallable('resolveSharedProfile')
          .call(<String, dynamic>{'publicId': publicId});
      final root = Map<String, dynamic>.from(result.data as Map);
      final profile = Map<String, dynamic>.from(root['profile'] as Map);
      final uid = profile['uid'] as String? ?? '';
      if (uid.isEmpty) throw StateError('Shared profile did not resolve.');
      return AppUser.fromMap(profile, uid);
    });
  }

  Future<void> shareProfileLink(ProfileShareLink link) async {
    if (!link.enabled || link.url.trim().isEmpty) {
      throw StateError('Profile sharing is disabled.');
    }
    await _channel.invokeMethod<bool>('shareText', <String, dynamic>{
      'text': 'View my NearMeU profile: ${link.url}',
    });
  }

  Future<String?> getInitialNativeLink() async {
    return _channel.invokeMethod<String>('getInitialLink');
  }

  void setNativeDeepLinkHandler(Future<void> Function(String link) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink' && call.arguments is String) {
        await handler(call.arguments as String);
      }
    });
  }

  String? publicIdFromUri(String rawLink) {
    final uri = Uri.tryParse(rawLink);
    if (uri == null) return null;
    if (uri.scheme == 'nearmeu' && uri.host == 'profile') {
      if (uri.pathSegments.length == 1) return uri.pathSegments.first;
      return null;
    }
    if (
        uri.scheme == 'https' &&
        uri.host == 'nearmeu-e82c7.web.app' &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'p') {
      return uri.pathSegments[1];
    }
    return null;
  }
}
