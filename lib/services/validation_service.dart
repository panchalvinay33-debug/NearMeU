import '../constants/app_constants.dart';

class ValidationException implements Exception {
  const ValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ValidationService {
  static const int maxNicknameLength = 30;
  static const int maxReportDescriptionLength = 500;
  static const int minAge = AppConstants.minimumUserAge;
  static const int maxAge = AppConstants.maximumUserAge;

  static String nickname(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const ValidationException('Nickname is required.');
    }
    if (normalized.length > maxNicknameLength) {
      throw const ValidationException('Nickname is too long.');
    }
    return normalized;
  }

  static const String adultAgeMessage =
      'NearMeU is for adults 18+ only. Enter an age from 18 to 99.';

  static int age(int value) {
    if (value < minAge || value > maxAge) {
      throw const ValidationException(adultAgeMessage);
    }
    return value;
  }

  static int ageText(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^[0-9]+$').hasMatch(normalized)) {
      throw const ValidationException(adultAgeMessage);
    }
    return age(int.parse(normalized));
  }

  static String profileChoice(String value, String fieldName) {
    final normalized = value.trim();
    final allowed = fieldName == 'gender'
        ? <String>{'Male', 'Female', 'Other'}
        : <String>{'Male', 'Female', 'Both'};
    if (!allowed.contains(normalized)) {
      throw ValidationException('Select a valid $fieldName.');
    }
    return normalized;
  }

  static double latitude(double value) {
    if (value < -90 || value > 90 || value.isNaN || value.isInfinite) {
      throw const ValidationException('Invalid latitude.');
    }
    return value;
  }

  static double longitude(double value) {
    if (value < -180 || value > 180 || value.isNaN || value.isInfinite) {
      throw const ValidationException('Invalid longitude.');
    }
    return value;
  }

  static String reportReason(String value) {
    final normalized = value.trim();
    const allowed = <String>{
      'Spam',
      'Fake Profile',
      'Harassment',
      'Hate Speech',
      'Scam/Fraud',
      'Inappropriate Content',
      'Other',
    };
    if (!allowed.contains(normalized)) {
      throw const ValidationException('Select a valid report reason.');
    }
    return normalized;
  }

  static String reportDescription(String value) {
    final normalized = value.trim();
    if (normalized.length > maxReportDescriptionLength) {
      throw const ValidationException('Report description is too long.');
    }
    return normalized;
  }
}
