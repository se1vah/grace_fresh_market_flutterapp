// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_picker_helper.dart';

Future<ImagePickerResult?> pickImagePlatform() async {
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/jpeg,image/png,image/webp,image/gif';
  uploadInput.click();

  await uploadInput.onChange.first;
  if (uploadInput.files == null || uploadInput.files!.isEmpty) {
    return null;
  }

  final file = uploadInput.files!.first;
  final fileName = file.name;
  final fileType = file.type.toLowerCase();
  final ext =
      fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

  final validExts = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
  if (!validExts.contains(ext) && !fileType.startsWith('image/')) {
    throw Exception(
      'Invalid image format. Supported formats: JPG, PNG, WEBP, GIF.',
    );
  }

  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoadEnd.first;

  final bytes = Uint8List.fromList(reader.result as List<int>);

  final readerData = html.FileReader();
  readerData.readAsDataUrl(file);
  await readerData.onLoadEnd.first;
  final dataUrl = readerData.result as String;

  return ImagePickerResult(
    bytes: bytes,
    fileName: fileName,
    dataUrl: dataUrl,
  );
}
