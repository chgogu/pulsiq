import 'dart:convert';
import 'dart:math';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../../domain/health_models.dart';
import '../../domain/whoop.dart';
import '../../security/secret_store.dart';
import '../health_source.dart';

/// Deployment config (spec §0): the proxy holds the WHOOP client secret and
/// does the token exchange. Empty until built with --dart-define.
const _defaultProxyUrl = String.fromEnvironment('PULSIQ_PROXY_URL');
const _whoopApiBase = 'https://api.prod.whoop.com/developer';
const _callbackScheme = 'pulsiq';

/// Key for the refresh token in the device keychain. The refresh token is
/// user data and never leaves the device except to the proxy's refresh route.
const whoopRefreshTokenKey = 'pulsiq.whoop.refresh_token.v1';

/// Owns the WHOOP OAuth lifecycle: browser login, code exchange (via proxy),
/// refresh, and secure storage of the refresh token. Access tokens live only
/// in memory.
class WhoopAuth {
  WhoopAuth({
    required SecretStore store,
    http.Client? client,
    String proxyUrl = _defaultProxyUrl,
    Future<String> Function({required String url, required String callbackUrlScheme})?
        authenticate,
  })  :
        // Private named fields can't be initializing formals (named args
        // can't start with `_`), so these stay explicit assignments.
        // ignore: prefer_initializing_formals
        _store = store,
        _http = client ?? http.Client(),
        // ignore: prefer_initializing_formals
        _proxyUrl = proxyUrl,
        _authenticate = authenticate ?? _defaultAuthenticate;

  final SecretStore _store;
  final http.Client _http;
  final String _proxyUrl;

  /// Injectable so tests don't need the platform browser.
  final Future<String> Function({
    required String url,
    required String callbackUrlScheme,
  }) _authenticate;

  WhoopTokens? _tokens; // in-memory access-token cache

  static Future<String> _defaultAuthenticate({
    required String url,
    required String callbackUrlScheme,
  }) =>
      FlutterWebAuth2.authenticate(
          url: url, callbackUrlScheme: callbackUrlScheme);

  bool get _configured => _proxyUrl.isNotEmpty;

  Future<bool> isConnected() async =>
      (await _store.read(whoopRefreshTokenKey)) != null;

  /// Full OAuth flow. Returns true only if we end up with a persisted refresh
  /// token (i.e. the `offline` scope was granted).
  Future<bool> connect() async {
    if (!_configured) return false;
    try {
      final cfgRes =
          await _http.get(Uri.parse('$_proxyUrl/v1/whoop/config'));
      if (cfgRes.statusCode != 200) return false;
      final cfg = jsonDecode(cfgRes.body) as Map<String, dynamic>;

      final state = _randomState();
      final authUrl =
          Uri.parse(cfg['authorize_url'] as String).replace(queryParameters: {
        'client_id': cfg['client_id'],
        'redirect_uri': cfg['redirect_uri'],
        'response_type': 'code',
        'scope': cfg['scopes'],
        'state': state,
      }).toString();

      final result = await _authenticate(
          url: authUrl, callbackUrlScheme: _callbackScheme);
      final cb = Uri.parse(result);
      if (cb.queryParameters['state'] != state) return false; // CSRF guard
      final code = cb.queryParameters['code'];
      if (code == null || code.isEmpty) return false;

      final exRes = await _http.post(
        Uri.parse('$_proxyUrl/v1/whoop/exchange'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'code': code, 'redirect_uri': cfg['redirect_uri']}),
      );
      if (exRes.statusCode != 200) return false;
      final tokens =
          WhoopTokens.parse(jsonDecode(exRes.body) as Map<String, dynamic>);
      if (tokens.refreshToken == null) return false;
      await _store.write(whoopRefreshTokenKey, tokens.refreshToken!);
      _tokens = tokens;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _store.delete(whoopRefreshTokenKey);
    _tokens = null;
  }

  /// A valid access token, refreshing via the proxy when the cached one is
  /// stale. Null if disconnected or the refresh fails.
  Future<String?> accessToken() async {
    final cached = _tokens;
    if (cached != null && !cached.isExpired(DateTime.now())) {
      return cached.accessToken;
    }
    if (!_configured) return null;
    final refresh = await _store.read(whoopRefreshTokenKey);
    if (refresh == null) return null;
    try {
      final res = await _http.post(
        Uri.parse('$_proxyUrl/v1/whoop/refresh'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'refresh_token': refresh}),
      );
      if (res.statusCode != 200) return null;
      final tokens =
          WhoopTokens.parse(jsonDecode(res.body) as Map<String, dynamic>);
      _tokens = tokens;
      // WHOOP rotates refresh tokens — persist the new one so the old,
      // now-invalid one isn't reused on the next launch.
      if (tokens.refreshToken != null) {
        await _store.write(whoopRefreshTokenKey, tokens.refreshToken!);
      }
      return tokens.accessToken;
    } catch (_) {
      return null;
    }
  }

  static String _randomState() {
    final rng = Random.secure();
    return List.generate(16, (_) => rng.nextInt(16).toRadixString(16)).join();
  }
}

/// Reads WHOOP recovery + sleep as daily biometrics. Implements the same
/// [HealthSource] seam as Apple Health, so the score consumes it unchanged.
class WhoopHealthSource implements HealthSource {
  WhoopHealthSource(this._auth, {http.Client? client})
      : _http = client ?? http.Client();

  final WhoopAuth _auth;
  final http.Client _http;

  @override
  Future<bool> requestPermissions() => _auth.connect();

  @override
  Future<List<DailyBiometrics>> fetchDaily({
    required DateTime from,
    required DateTime to,
  }) async {
    final token = await _auth.accessToken();
    if (token == null) return const [];
    try {
      final recovery = await _collection('/v1/recovery', from, to, token);
      final sleep = await _collection('/v1/activity/sleep', from, to, token);
      return mapWhoopDaily(recovery: recovery, sleep: sleep);
    } catch (_) {
      return const [];
    }
  }

  /// Paginated GET of a WHOOP record collection over [from, to].
  Future<List<Map<String, dynamic>>> _collection(
    String path,
    DateTime from,
    DateTime to,
    String token,
  ) async {
    final out = <Map<String, dynamic>>[];
    String? nextToken;
    for (var page = 0; page < 20; page++) {
      final uri = Uri.parse('$_whoopApiBase$path').replace(queryParameters: {
        'start': from.toUtc().toIso8601String(),
        'end': to.toUtc().toIso8601String(),
        'limit': '25',
        'nextToken': ?nextToken,
      });
      final res =
          await _http.get(uri, headers: {'authorization': 'Bearer $token'});
      if (res.statusCode != 200) break;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final records = body['records'];
      if (records is List) {
        for (final r in records) {
          if (r is Map<String, dynamic>) out.add(r);
        }
      }
      final nt = body['next_token'];
      if (nt is String && nt.isNotEmpty) {
        nextToken = nt;
      } else {
        break;
      }
    }
    return out;
  }
}
