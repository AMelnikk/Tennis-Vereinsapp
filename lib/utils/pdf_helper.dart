import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> readPdfFile() async {
  // Use the FilePicker to select a PDF file
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result != null && result.files.isNotEmpty) {
    // Get the file from the result
    final filePath = result.files.single.path;

    if (filePath != null) {
      // Read the file as bytes
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return bytes;
    }
  }
  return null; // Return null if no file is selected or file is invalid
}
