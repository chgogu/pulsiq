import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulsiq/domain/whoop.dart';
import 'package:pulsiq/health/whoop/whoop_client.dart';
import 'package:pulsiq/security/secret_store.dart';

Map<String, dynamic> recovery(String createdAt, {double? hrv, double? rhr}) => {
      'score_state': 'SCORED',
      'created_at': createdAt,
      'score': {
        if (hrv != null) 'hrv_rmssd_milli': hrv,
        if (rhr != null) 'resting_heart_rate': rhr,
        'recovery_score': 66,
      },
    };

Map<String, dynamic> sleep(
  String end, {
  double inBedMs = 8 * 3600000,
  double awakeMs = 30 * 60000,
  double? efficiency,
  double? respiratory,
  bool nap = false,
}) =>
    {
      'score_state': 'SCORED',
      'end': end,
      'nap': nap,
      'score': {
        'stage_summary': {
          'total_in_bed_time_milli': inBedMs,
          'total_awake_time_milli': awakeMs,
        },
        if (efficiency != null) 'sleep_efficiency_percentage': efficiency,
        if (respiratory != null) 'respiratory_rate': respiratory,
      },
    };

void main() {
  group('token parsing', () {
    test('reads access + refresh + expiry', () {
      final now = DateTime(2026, 7, 21, 12);
      final t = WhoopTokens.parse({
        'access_token': 'acc',
        'refresh_token': 'ref',
        'expires_in': 3600,
      }, now: now);
      expect(t.accessToken, 'acc');
      expect(t.refreshToken, 'ref');
      expect(t.expiresAt, now.add(const Duration(hours: 1)));
    });

    test('treats a token near expiry as expired (60s skew)', () {
      final now = DateTime(2026, 7, 21, 12);
      final t = WhoopTokens.parse(
          {'access_token': 'a', 'expires_in': 30}, now: now);
      expect(t.isExpired(now.add(const Duration(seconds: 31))), isTrue);
    });

    test('rejects a response with no access token', () {
      expect(() => WhoopTokens.parse({'expires_in': 3600}),
          throwsFormatException);
    });

    test('a refresh without a rotated token yields null refreshToken', () {
      final t = WhoopTokens.parse({'access_token': 'a', 'expires_in': 3600});
      expect(t.refreshToken, isNull);
    });
  });

  group('daily mapping', () {
    test('merges recovery + sleep into one day', () {
      final days = mapWhoopDaily(
        recovery: [recovery('2026-07-20T07:00:00.000Z', hrv: 65, rhr: 54)],
        sleep: [
          sleep('2026-07-20T06:30:00.000Z',
              efficiency: 91, respiratory: 14.2),
        ],
      );
      expect(days, hasLength(1));
      final d = days.single;
      expect(d.hrvMs, 65);
      expect(d.restingHr, 54);
      expect(d.respiratoryRate, 14.2);
      expect(d.sleepEfficiencyPct, 91);
      // 8h in bed − 30m awake = 7.5h asleep.
      expect(d.sleepHours, closeTo(7.5, 0.001));
    });

    test('skips records still scoring', () {
      final days = mapWhoopDaily(
        recovery: [
          {
            'score_state': 'PENDING_SCORE',
            'created_at': '2026-07-20T07:00:00.000Z',
            'score': {'hrv_rmssd_milli': 60, 'resting_heart_rate': 55},
          }
        ],
        sleep: const [],
      );
      expect(days, isEmpty);
    });

    test('ignores naps for the daily baseline', () {
      final days = mapWhoopDaily(
        recovery: const [],
        sleep: [sleep('2026-07-20T13:00:00.000Z', nap: true)],
      );
      expect(days, isEmpty);
    });

    test('converts an HRV reported in seconds to milliseconds', () {
      final days = mapWhoopDaily(
        recovery: [recovery('2026-07-20T07:00:00.000Z', hrv: 0.065)],
        sleep: const [],
      );
      expect(days.single.hrvMs, closeTo(65, 0.001));
    });

    test('sorts days ascending and keeps them distinct', () {
      final days = mapWhoopDaily(
        recovery: [
          recovery('2026-07-21T07:00:00.000Z', rhr: 52),
          recovery('2026-07-19T07:00:00.000Z', rhr: 58),
        ],
        sleep: const [],
      );
      expect(days.map((d) => d.day.day), [19, 21]);
    });
  });

  group('OAuth flow (fake browser + mock proxy)', () {
    late InMemorySecretStore store;

    setUp(() => store = InMemorySecretStore());

    WhoopAuth buildAuth({
      required MockClient client,
      required String Function(String authUrl) browser,
    }) =>
        WhoopAuth(
          store: store,
          client: client,
          proxyUrl: 'http://proxy.test',
          authenticate: ({required url, required callbackUrlScheme}) async =>
              browser(url),
        );

    MockClient proxy({
      Map<String, dynamic>? exchange,
      int exchangeStatus = 200,
    }) =>
        MockClient((req) async {
          if (req.url.path == '/v1/whoop/config') {
            return http.Response(
              jsonEncode({
                'client_id': 'cid',
                'redirect_uri': 'pulsiq://whoop-callback',
                'authorize_url': 'https://api.prod.whoop.com/oauth/oauth2/auth',
                'scopes': 'offline read:recovery',
              }),
              200,
            );
          }
          if (req.url.path == '/v1/whoop/exchange') {
            return http.Response(jsonEncode(exchange ?? {}), exchangeStatus);
          }
          return http.Response('not found', 404);
        });

    test('stores the refresh token on a successful link', () async {
      final auth = buildAuth(
        client: proxy(exchange: {
          'access_token': 'acc',
          'refresh_token': 'ref',
          'expires_in': 3600,
        }),
        // The fake browser echoes back the state it was given.
        browser: (authUrl) {
          final state = Uri.parse(authUrl).queryParameters['state'];
          return 'pulsiq://whoop-callback?code=good&state=$state';
        },
      );
      expect(await auth.connect(), isTrue);
      expect(await store.read(whoopRefreshTokenKey), 'ref');
      expect(await auth.isConnected(), isTrue);
    });

    test('rejects a mismatched state (CSRF guard) and stores nothing',
        () async {
      final auth = buildAuth(
        client: proxy(exchange: {'access_token': 'a', 'refresh_token': 'r'}),
        browser: (_) => 'pulsiq://whoop-callback?code=good&state=WRONG',
      );
      expect(await auth.connect(), isFalse);
      expect(await store.read(whoopRefreshTokenKey), isNull);
    });

    test('a link without a refresh token does not count as connected',
        () async {
      // No `offline` scope → no refresh token → can't persist the session.
      final auth = buildAuth(
        client: proxy(exchange: {'access_token': 'a', 'expires_in': 3600}),
        browser: (authUrl) {
          final state = Uri.parse(authUrl).queryParameters['state'];
          return 'pulsiq://whoop-callback?code=good&state=$state';
        },
      );
      expect(await auth.connect(), isFalse);
      expect(await auth.isConnected(), isFalse);
    });

    test('disconnect clears the stored token', () async {
      await store.write(whoopRefreshTokenKey, 'ref');
      final auth = WhoopAuth(store: store, proxyUrl: 'http://proxy.test');
      await auth.disconnect();
      expect(await auth.isConnected(), isFalse);
    });
  });
}
