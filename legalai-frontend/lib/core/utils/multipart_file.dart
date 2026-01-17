import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

Future<MultipartFile> multipartFileFromPlatformFile(PlatformFile file) async {
  if (file.bytes != null) {
    return MultipartFile.fromBytes(file.bytes!, filename: file.name);
  }
  final path = file.path;
  if (path == null || path.isEmpty) {
    throw ArgumentError('File data is missing');
  }
  return MultipartFile.fromFile(path, filename: file.name);
}
