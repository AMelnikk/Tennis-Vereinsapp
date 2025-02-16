import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_utils.dart';

Future<List<String>> pickImages(ScaffoldMessengerState messenger) async {
  final ImagePicker picker = ImagePicker();
  List<String> blob = []; // <-- Initialisiert mit einer leeren Liste

  try {
    // Mehrere Bilder auswählen
    final List<XFile> images = await picker.pickMultiImage();

    // Sicherstellen, dass images nicht leer ist
    if (images.isNotEmpty) {
      // Umwandlung der Bilder in Base64-Strings durch Aufruf der Hilfsmethode
      blob = await convertImagesToBase64(images);
    } else {
      appError(messenger, "Keine Bilder ausgewählt.");
    }
  } catch (e) {
    appError(messenger, "Fehler beim Auswählen der Bilder: $e");
  }

  return blob; // Immer eine gültige Liste zurückgeben
}

// Assuming the imageData is base64-encoded, you can create a preview method
Image getpreviewImage(String imageData) {
  return Image.memory(base64Decode(imageData), fit: BoxFit.cover);
}

// Hilfsmethode zum Konvertieren von Bildern in Base64 und Komprimieren mit flutter_image_compress
Future<List<String>> convertImagesToBase64(List<XFile> images) async {
  List<String> base64ImageUrls = [];

  for (var image in images) {
    final bytes = await image.readAsBytes();

    // Kompression mit flutter_image_compress
    var result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1080, // Optionale Größenanpassung
      minHeight: 1080,
      quality: 80, // Qualitätsstufe
    );

    // Bild in Base64 umwandeln
    String base64String = base64Encode(Uint8List.fromList(result));
    base64ImageUrls.add(base64String); // Base64-String in Liste speichern
  }

  return base64ImageUrls;
}

/// Prüft, ob das Bild bereits im Cache ist, sonst decodiert es Base64 und speichert es.
Uint8List getImage(Map<String, Uint8List> imageCache, String base64String) {
  if (imageCache.containsKey(base64String)) {
    return imageCache[base64String]!;
  }

  Uint8List bytes = base64Decode(base64String);
  imageCache[base64String] = bytes;
  return bytes;
}
