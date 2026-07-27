import 'package:cloud_functions/cloud_functions.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionPolicy {
  const AppVersionPolicy({
    required this.installedVersionCode,
    required this.installedVersionName,
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.minimumSupportedVersionCode,
    required this.updateUrl,
    required this.message,
    required this.maintenanceMode,
  });

  final int installedVersionCode;
  final String installedVersionName;
  final int latestVersionCode;
  final String latestVersionName;
  final int minimumSupportedVersionCode;
  final String updateUrl;
  final String message;
  final bool maintenanceMode;

  bool get updateRequired =>
      installedVersionCode < minimumSupportedVersionCode;

  bool get newerVersionAvailable => installedVersionCode < latestVersionCode;
}

class AppVersionService {
  AppVersionService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<AppVersionPolicy> fetchPolicy() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final installedCode = int.tryParse(packageInfo.buildNumber) ?? 0;

    final result = await _functions
        .httpsCallable('getAndroidAppVersionPolicy')
        .call<Map<String, dynamic>>(<String, dynamic>{
      'versionCode': installedCode,
      'versionName': packageInfo.version,
    });
    final data = Map<String, dynamic>.from(result.data);

    return AppVersionPolicy(
      installedVersionCode: installedCode,
      installedVersionName: packageInfo.version,
      latestVersionCode: (data['latestVersionCode'] as num?)?.toInt() ??
          installedCode,
      latestVersionName:
          (data['latestVersionName'] as String?)?.trim().isNotEmpty == true
              ? (data['latestVersionName'] as String).trim()
              : packageInfo.version,
      minimumSupportedVersionCode:
          (data['minimumSupportedVersionCode'] as num?)?.toInt() ??
              installedCode,
      updateUrl: (data['updateUrl'] as String?)?.trim() ?? '',
      message: (data['message'] as String?)?.trim().isNotEmpty == true
          ? (data['message'] as String).trim()
          : 'A newer version of NearMeU is required to continue.',
      maintenanceMode: data['maintenanceMode'] == true,
    );
  }
}
