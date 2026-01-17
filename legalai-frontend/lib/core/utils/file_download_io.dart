import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<String?> saveFile(Uint8List bytes, String filename, String mimeType) async {
  final path = await FilePicker.platform.saveFile(fileName: filename);
  if (path == null) return null;
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return path;
}
