import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;

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

Future<ImagePickerResult?> pickProfileImage({ImageSource source = ImageSource.gallery}) async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final fileName = image.name.isNotEmpty ? image.name : 'profile.jpg';

    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    String mimeType = 'image/jpeg';
    if (ext == 'png') {
      mimeType = 'image/png';
    } else if (ext == 'webp') {
      mimeType = 'image/webp';
    } else if (ext == 'gif') {
      mimeType = 'image/gif';
    }

    final base64String = base64Encode(bytes);
    final dataUrl = 'data:$mimeType;base64,$base64String';

    return ImagePickerResult(
      bytes: bytes,
      fileName: fileName,
      dataUrl: dataUrl,
    );
  } catch (e) {
    debugPrint('Error picking profile image: $e');
    return null;
  }
}
