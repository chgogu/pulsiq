import '../ocr_service.dart';

OcrService createOcrService() => const _StubOcrService();

class _StubOcrService implements OcrService {
  const _StubOcrService();

  @override
  Future<String> extractText(String imagePath) async => '';
}
