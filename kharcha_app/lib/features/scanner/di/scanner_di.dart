import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kharcha_app/features/scanner/data/opencv_document_scanner.dart';
import 'package:kharcha_app/features/scanner/domain/services/document_scanner.dart';

/// Wiring for the scanner feature: the only place that picks the OpenCV
/// implementation. A test can override this provider with a fake.
final documentScannerProvider = Provider<DocumentScanner>(
  (ref) => OpenCvDocumentScanner(),
);
