import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../ocr_service.dart';

OcrService createOcrService() => _MlKitOcrService();

class _MlKitOcrService implements OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> extractText(String imagePath) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await _recognizer.processImage(input);
      return result.text;
    } catch (_) {
      return '';
    }
  }
}
