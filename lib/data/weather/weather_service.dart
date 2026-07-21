import 'dart:convert';

import 'package:http/http.dart' as http;

import '../db/app_database.dart';

class WeatherSnapshot {
  const WeatherSnapshot({required this.tempC, required this.humidityPct});

  final double tempC;
  final double humidityPct;
}

/// Open-Meteo current conditions (free, keyless), located via ipapi.co
/// (approximate, IP-based — no GPS permission needed in v1). Cached 3h in
/// the local DB; every failure degrades to the cache, then to null
/// (no weather adjustment).
class WeatherService {
  WeatherService(this._db, {http.Client? client})
      : _client = client ?? http.Client();

  final AppDatabase _db;
  final http.Client _client;

  static const ttl = Duration(hours: 3);

  Future<WeatherSnapshot?> current({DateTime? now}) async {
    now ??= DateTime.now();
    final cached = await _db.getWeatherCache();
    if (cached != null && now.difference(cached.fetchedAt) < ttl) {
      return WeatherSnapshot(
          tempC: cached.tempC, humidityPct: cached.humidityPct);
    }
    try {
      final (lat, lon) = await _locate();
      final fresh = await _fetch(lat, lon);
      await _db.upsertWeatherCache(
        fetchedAt: now,
        tempC: fresh.tempC,
        humidityPct: fresh.humidityPct,
        latitude: lat,
        longitude: lon,
      );
      return fresh;
    } catch (_) {
      if (cached == null) return null;
      return WeatherSnapshot(
          tempC: cached.tempC, humidityPct: cached.humidityPct);
    }
  }

  Future<(double, double)> _locate() async {
    final res = await _client
        .get(Uri.parse('https://ipapi.co/json/'))
        .timeout(const Duration(seconds: 6));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      (body['latitude'] as num).toDouble(),
      (body['longitude'] as num).toDouble(),
    );
  }

  Future<WeatherSnapshot> _fetch(double lat, double lon) async {
    final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m');
    final res = await _client.get(uri).timeout(const Duration(seconds: 6));
    final current =
        (jsonDecode(res.body) as Map<String, dynamic>)['current'] as Map;
    return WeatherSnapshot(
      tempC: (current['temperature_2m'] as num).toDouble(),
      humidityPct: (current['relative_humidity_2m'] as num).toDouble(),
    );
  }
}
