import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app's own name and version, read from the bundle at runtime.
///
/// Settings used to hardcode this string, which drifted: it read "PulsIQ
/// 0.1.0" while the binary shipped as 1.0.0. Reading the bundle means the
/// number a user quotes in a support email is always the one they're running.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final name = info.appName.isEmpty ? 'PulsIQ' : info.appName;
    return '$name ${info.version} (${info.buildNumber})';
  } catch (_) {
    // No platform channel (tests, some desktop hosts) — the About card just
    // shows the name.
    return 'PulsIQ';
  }
});
