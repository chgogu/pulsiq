import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/api_config.dart';

void main() {
  test('base URL falls back to production, never an empty string', () {
    // A release built without --dart-define=PULSIQ_PROXY_URL used to compile
    // an empty base URL, which silently disabled WHOOP, voice logging, and
    // meal photos with no error surfaced anywhere.
    expect(apiBaseUrl, isNotEmpty);
    expect(apiBaseUrl, startsWith('https://'));
  });

  test('production API is not plaintext HTTP or a private address', () {
    // App Transport Security blocks cleartext, and a LAN address is
    // unreachable for anyone who isn't the developer.
    expect(apiBaseUrl, isNot(startsWith('http://')));
    expect(apiBaseUrl, isNot(contains('192.168.')));
    expect(apiBaseUrl, isNot(contains('localhost')));
    expect(apiBaseUrl, isNot(contains('127.0.0.1')));
  });

  test('headers carry JSON content type by default', () {
    expect(apiHeaders()['content-type'], 'application/json');
  });

  test('GET requests can omit the JSON content type', () {
    expect(apiHeaders(json: false).containsKey('content-type'), isFalse);
  });

  test('the auth header is present exactly when a token is compiled in', () {
    final auth = apiHeaders()['authorization'];
    if (apiAppToken.isEmpty) {
      expect(auth, isNull);
    } else {
      expect(auth, 'Bearer $apiAppToken');
    }
  });
}
