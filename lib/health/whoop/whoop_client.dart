import 'dart:convert';
import 'dart:math';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../../domain/health_models.dart';
import '../../domain/whoop.dart';
import '../../security/secret_store.dart';
import '../../data/api_config.dart';
import '../health_source.dart';

/// Deployment config (spec §0): the API holds the WHOOP client secret and
/// does the token exchange. Defaults to production — see [apiBaseUrl].
const _defaultProxyUrl = apiBaseUrl;
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
  Future<String?>? _refreshing; // single-flight guard

  static Future<String> _defaultAuthenticate({
    required String url,
    required String callbackUrlScheme,
  }) =>
      FlutterWebAuth2.authenticate(
          url: url, callbackUrlScheme: callbackUrlScheme);

  bool get _configured => _proxyUrl.isNotEmpty;

  Future<bool> isConnected() async {
    // A keychain read that throws (e.g. no plugin in a test, or a locked
    // device) means "not linked" rather than a crashed dashboard.
    try {
      return (await _store.read(whoopRefreshTokenKey)) != null;
    } catch (_) {
      return false;
    }
  }

  /// Full OAuth flow. Returns true only if we end up with a persisted refresh
  /// token (i.e. the `offline` scope was granted).
  Future<bool> connect() async {
    if (!_configured) return false;
    try {
      final cfgRes =
          await _http.get(Uri.parse('$_proxyUrl/v1/whoop/config'),
              headers: apiHeaders(json: false));
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
        headers: apiHeaders(),
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
  ///
  /// WHOOP rotates the refresh token and invalidates the old one on every use,
  /// so a second concurrent refresh with the same token 500s. The single-flight
  /// guard makes overlapping callers await one refresh instead of racing.
  Future<String?> accessToken() async {
    final cached = _tokens;
    if (cached != null && !cached.isExpired(DateTime.now())) {
      return cached.accessToken;
    }
    if (!_configured) return null;
    return _refreshing ??= _refresh()
      ..whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final refresh = await _store.read(whoopRefreshTokenKey);
    if (refresh == null) return null;
    try {
      final res = await _http.post(
        Uri.parse('$_proxyUrl/v1/whoop/refresh'),
        headers: apiHeaders(),
        body: jsonEncode({'refresh_token': refresh}),
      );
      if (res.statusCode != 200) return null;
      final tokens =
          WhoopTokens.parse(jsonDecode(res.body) as Map<String, dynamic>);
      // Persist the rotated token BEFORE returning, so the old (now-dead) one
      // is never read again on the next launch.
      if (tokens.refreshToken != null) {
        await _store.write(whoopRefreshTokenKey, tokens.refreshToken!);
      }
      _tokens = tokens;
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

/// Why a body-signals fetch produced what it did — lets the card show a
/// precise state instead of a silent blank.
enum WhoopFetchStatus { ok, noAccess, empty, error }

class WhoopFetchResult {
  const WhoopFetchResult(this.status, {this.body});
  final WhoopFetchStatus status;
  final WhoopBody? body;
}

/// Reads WHOOP data (recovery, sleep, cycle) through the proxy, which pins the
/// API version (v2) and logs what came back. Implements the [HealthSource]
/// seam so the score consumes it unchanged, and also exposes the richer
/// [fetchBody] for the dashboard's body-signals card.
class WhoopHealthSource implements HealthSource {
  WhoopHealthSource(
    this._auth, {
    http.Client? client,
    String proxyUrl = _defaultProxyUrl,
  })  : _http = client ?? http.Client(),
        // Private named field can't be an initializing formal.
        // ignore: prefer_initializing_formals
        _proxyUrl = proxyUrl;

  final WhoopAuth _auth;
  final http.Client _http;
  final String _proxyUrl;

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
      final recovery = await _collection('recovery', from, to, token);
      final sleep = await _collection('activity/sleep', from, to, token);
      return mapWhoopDaily(recovery: recovery, sleep: sleep);
    } catch (_) {
      return const [];
    }
  }

  /// 60 days of recovery + sleep + cycle, merged into per-day body signals with
  /// averages. Status distinguishes "no token", "no scored data yet", and
  /// "fetch failed" so the card never blanks silently.
  Future<WhoopFetchResult> fetchBody() async {
    final token = await _auth.accessToken();
    if (token == null) return const WhoopFetchResult(WhoopFetchStatus.noAccess);
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 60));
      final recovery = await _collection('recovery', from, now, token);
      final sleep = await _collection('activity/sleep', from, now, token);
      final cycle = await _collection('cycle', from, now, token);
      final body = WhoopBody(
          mapWhoopDays(recovery: recovery, sleep: sleep, cycle: cycle));
      if (body.isEmpty) return const WhoopFetchResult(WhoopFetchStatus.empty);
      return WhoopFetchResult(WhoopFetchStatus.ok, body: body);
    } catch (_) {
      return const WhoopFetchResult(WhoopFetchStatus.error);
    }
  }

  /// Paginated fetch of a WHOOP v2 collection via the proxy (which prefixes
  /// /v2/ and logs counts). [resource] is 'recovery' | 'cycle' |
  /// 'activity/sleep'.
  Future<List<Map<String, dynamic>>> _collection(
    String resource,
    DateTime from,
    DateTime to,
    String token,
  ) async {
    final out = <Map<String, dynamic>>[];
    String? nextToken;
    for (var page = 0; page < 40; page++) {
      final res = await _http.post(
        Uri.parse('$_proxyUrl/v1/whoop/fetch'),
        headers: apiHeaders(),
        body: jsonEncode({
          'access_token': token,
          'resource': resource,
          'start': from.toUtc().toIso8601String(),
          'end': to.toUtc().toIso8601String(),
          'next_token': nextToken,
        }),
      );
      if (res.statusCode != 200) break;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final records = body['records'];
      if (records is List) {
        for (final r in records) {
          if (r is Map<String, dynamic>) out.add(r);
        }
      }
      final nt = body['next_token'] ?? body['nextToken'];
      if (nt is String && nt.isNotEmpty) {
        nextToken = nt;
      } else {
        break;
      }
    }
    return out;
  }
}
