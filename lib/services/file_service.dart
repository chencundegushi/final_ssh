import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FileService {
  static Future<String?> importPrivateKey() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'key', 'ppk'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
