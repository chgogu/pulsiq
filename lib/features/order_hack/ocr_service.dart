import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ocr_impl/ocr_stub.dart'
    if (dart.library.ffi) 'ocr_impl/ocr_native.dart';

/// On-device OCR (spec §3, google_mlkit_text_recognition). Native only;
/// web has no ML Kit, so the Order Hack screen offers manual text there.
abstract interface class OcrService {
  Future<String> extractText(String imagePath);
}

final ocrServiceProvider = Provider<OcrService>((_) => createOcrService());
