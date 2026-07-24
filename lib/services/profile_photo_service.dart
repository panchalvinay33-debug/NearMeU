import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'user_service.dart';

class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfilePhotoService {
  ProfilePhotoService({
    FirebaseStorage? storage,
    ImagePicker? picker,
    UserService? userService,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _picker = picker ?? ImagePicker(),
       _userService = userService ?? UserService();

  static const int maximumProfilePhotoBytes = 5 * 1024 * 1024;

  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final UserService _userService;

  Reference _profilePhotoRef(String uid) {
    return _storage.ref().child('profile_photos/$uid/avatar');
  }

  Future<String?> pickAndUpload(String uid) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 82,
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw const ProfilePhotoException('The selected photo is empty.');
    }
    if (bytes.length > maximumProfilePhotoBytes) {
      throw const ProfilePhotoException(
        'Please choose a profile photo smaller than 5 MB.',
      );
    }

    final mimeType = picked.mimeType?.startsWith('image/') == true
        ? picked.mimeType!
        : 'image/jpeg';
    final reference = _profilePhotoRef(uid);
    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: mimeType,
        cacheControl: 'public,max-age=3600',
        customMetadata: <String, String>{
          'ownerId': uid,
          'purpose': 'profile-photo',
        },
      ),
    );

    final downloadUrl = await reference.getDownloadURL();
    await _userService.updateProfilePhoto(uid: uid, photoUrl: downloadUrl);
    return downloadUrl;
  }

  Future<void> remove(String uid) async {
    try {
      await _profilePhotoRef(uid).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    await _userService.updateProfilePhoto(uid: uid, photoUrl: null);
  }
}
