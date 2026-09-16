import 'dart:typed_data';

import 'image_picker_stub.dart'
    if (dart.library.html) 'image_picker_web.dart';

class ImagePickerResult {
  final Uint8List bytes;
  final String fileName;
  final String dataUrl;

  ImagePickerResult({
    required this.bytes,
    required this.fileName,
    required this.dataUrl,
  });
}

Future<ImagePickerResult?> pickProfileImage() {
  return pickImagePlatform();
}
