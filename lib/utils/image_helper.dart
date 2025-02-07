import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verein_app/utils/app_utils.dart';

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
      minWidth: 800, // Optionale Größenanpassung
      minHeight: 800,
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

/// Komprimiert ein Bild (`Uint8List`) und konvertiert es in Base64
Future<String> convertToBase64AndCompress(File imageFile) async {
  try {
    // Lese das Bild als Byte-Daten
    final imageData = await imageFile.readAsBytes();

    // Berechne die Dateigröße des Bildes in Bytes
    final imageSizeInBytes = imageData.lengthInBytes;

    // Wenn das Bild größer als 1 MB (1 MB = 1.048.576 Bytes) ist, komprimiere es
    if (imageSizeInBytes > 1048576) {
      // Komprimiere das Bild
      final compressedImage = await FlutterImageCompress.compressWithList(
        imageData,
        minHeight: 1080,
        minWidth: 1080,
        quality: 80,
        format: CompressFormat.webp,
      );

      // Wandelt die komprimierten Daten in Base64 um und gibt sie zurück
      return base64Encode(compressedImage);
    } else {
      // Wenn das Bild kleiner als 1 MB ist, gib das Originalbild als Base64 zurück
      return base64Encode(imageData);
    }
  } catch (e) {
    print(e);
    return '';
  }
}

Future<List<String>> saveImageUrlsToFirebase(List<File> imageFiles) async {
  List<String> imageUrls = [];

  try {
    for (var image in imageFiles) {
      String url = await uploadImageToFirebaseStorage(image);
      if (url.isNotEmpty) {
        imageUrls.add(url);
      }
    }
  } catch (e) {
    print("Fehler beim Speichern der Bild-URLs: $e");
  }

  return imageUrls; // Returning the list of URLs
}

Future<String> uploadImageToFirebaseStorage(File imageFile) async {
  try {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef =
        FirebaseStorage.instance.ref().child("news_images/$fileName.jpg");

    UploadTask uploadTask = storageRef.putFile(imageFile);

    // Wait for the upload to complete and then get the URL
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    print("Image uploaded successfully, URL: $downloadUrl"); // Debugging log
    return downloadUrl;
  } catch (e) {
    // Handle FirebaseException more gracefully for Flutter Web
    if (e is FirebaseException) {
      print("FirebaseException: ${e.message}");
    } else {
      print("Fehler beim Hochladen des Bildes: $e");
    }
    return ""; // Return empty string on failure
  }
}
