import 'dart:typed_data';

Future<void> saveAndDownloadPdf({
  required Uint8List bytes,
  required String filename,
}) async {
  throw UnsupportedError('Cannot download PDF without platform implementation.');
}
