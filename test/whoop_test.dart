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
        'hrv_rmssd_milli': ?hrv,
        'resting_heart_rate': ?rhr,
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
        'sleep_efficiency_percentage': ?efficiency,
        'respiratory_rate': ?respiratory,
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

  Map<String, dynamic> cycle(String start, {double? strain, double? avgHr}) => {
        'score_state': 'SCORED',
        'start': start,
        'score': {
          'strain': ?strain,
          'average_heart_rate': ?avgHr,
        },
      };

  group('body history + averages', () {
    test('merges per day and the latest carries the newest reading', () {
      final body = WhoopBody(mapWhoopDays(
        recovery: [
          recovery('2026-07-19T07:00:00.000Z', hrv: 40, rhr: 60),
          recovery('2026-07-21T07:00:00.000Z', hrv: 68, rhr: 52),
        ],
        sleep: [sleep('2026-07-21T06:30:00.000Z')],
        cycle: [cycle('2026-07-21T05:00:00.000Z', strain: 14.2, avgHr: 88)],
      ));
      expect(body.days, hasLength(2));
      final latest = body.latest!;
      expect(latest.hrvMs, 68);
      expect(latest.restingHr, 52);
      expect(latest.strain, 14.2);
      expect(latest.sleepHours, closeTo(7.5, 0.001));
      expect(latest.band, RecoveryBand.yellow);
    });

    test('computes 60-day averages, skipping null days', () {
      final body = WhoopBody(mapWhoopDays(
        recovery: [
          recovery('2026-07-19T07:00:00.000Z', hrv: 40, rhr: 60),
          recovery('2026-07-21T07:00:00.000Z', hrv: 60, rhr: 50),
        ],
        sleep: const [],
      ));
      expect(body.average((d) => d.hrvMs), 50); // (40+60)/2
      expect(body.average((d) => d.restingHr), 55);
      expect(body.average((d) => d.sleepHours), isNull); // no sleep days
      expect(body.scoredRecoveryDays, 2);
    });

    test('is empty when nothing scored', () {
      expect(WhoopBody(mapWhoopDays(recovery: const [], sleep: const [])).isEmpty,
          isTrue);
    });

    test('surfaces sleep even before recovery has computed', () {
      final body = WhoopBody(mapWhoopDays(
        recovery: const [],
        sleep: [sleep('2026-07-21T06:30:00.000Z', efficiency: 90)],
      ));
      expect(body.latest!.recoveryPct, isNull);
      expect(body.latest!.sleepHours, closeTo(7.5, 0.001));
      expect(body.isEmpty, isFalse);
    });
  });

  group('recovery bands', () {
    test('map to WHOOP thresholds', () {
      expect(RecoveryBand.of(67), RecoveryBand.green);
      expect(RecoveryBand.of(66), RecoveryBand.yellow);
      expect(RecoveryBand.of(34), RecoveryBand.yellow);
      expect(RecoveryBand.of(33), RecoveryBand.red);
    });
  });

  group('smart insight', () {
    WhoopDay snap({int? rec, double? strain, double? sleep}) => WhoopDay(
          day: DateTime(2026, 7, 21),
          recoveryPct: rec,
          strain: strain,
          sleepHours: sleep,
        );

    test('warns when strain was high on low recovery', () {
      final msg = whoopInsight(snap(rec: 25, strain: 15));
      expect(msg.toLowerCase(), contains('recovery day'));
    });

    test('greenlights pushing when primed and yesterday was light', () {
      final msg = whoopInsight(snap(rec: 80, strain: 5));
      expect(msg.toLowerCase(), contains('push'));
    });

    test('degrades gracefully with no recovery yet', () {
      final msg = whoopInsight(snap(sleep: 7.2));
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('recovery'));
    });

    test('every band yields a non-empty read', () {
      for (final r in [10, 50, 90]) {
        expect(whoopInsight(snap(rec: r)).trim(), isNotEmpty);
      }
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

    test('concurrent token requests trigger only one refresh (WHOOP rotates '
        'and 500s on a reused token)', () async {
      await store.write(whoopRefreshTokenKey, 'r1');
      var refreshes = 0;
      final client = MockClient((req) async {
        if (req.url.path == '/v1/whoop/refresh') {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response(
            jsonEncode({
              'access_token': 'a$refreshes',
              'refresh_token': 'r${refreshes + 1}',
              'expires_in': 3600,
            }),
            200,
          );
        }
        return http.Response('nf', 404);
      });
      final auth =
          WhoopAuth(store: store, client: client, proxyUrl: 'http://proxy.test');
      final results = await Future.wait([auth.accessToken(), auth.accessToken()]);
      expect(refreshes, 1);
      expect(results, ['a1', 'a1']);
      // The rotated token was persisted, so the next launch won't reuse r1.
      expect(await store.read(whoopRefreshTokenKey), 'r2');
    });
  });
}
