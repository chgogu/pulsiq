import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SttResultHandler = void Function(
    String text, double confidence, bool isFinal);

/// On-device speech recognition first (spec §0). The Whisper-API fallback
/// for low-confidence results rides the backend proxy and activates with
/// it; [confidenceFloor] marks the routing threshold.
abstract interface class SttService {
  static const confidenceFloor = 0.5;

  Future<bool> initialize();
  Future<void> start(SttResultHandler onResult);
  Future<void> stop();
}

class PlatformStt implements SttService {
  final _stt = SpeechToText();
  bool _ready = false;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize();
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  @override
  Future<void> start(SttResultHandler onResult) async {
    if (!await initialize()) return;
    await _stt.listen(
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (result) => onResult(
        result.recognizedWords,
        result.confidence,
        result.finalResult,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (_ready) await _stt.stop();
  }
}

final sttServiceProvider = Provider<SttService>((_) => PlatformStt());
