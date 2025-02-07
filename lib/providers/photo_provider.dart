import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import '../models/Photo.dart';

class PhotoProvider with ChangeNotifier {
  PhotoProvider(this._token);

  final String? _token;

  // Hier speichern wir mehrere Bilder
  List<Image> images = [];
  bool isHttpProceeding = false;
  String? lastId;
  bool hasMore = true;

  List<Photo> loadedData = [];

  // Methode zum Auswählen mehrerer Bilder
  Future<void> pickImages() async {
    final picker = ImagePicker();
    final List<XFile> files = await picker
        .pickMultiImage(); // Ermöglicht das Auswählen mehrerer Bilder

    // Hier fügen wir die ausgewählten Bilder zur Liste 'images' hinzu
    images = (files.map((file) => Image.file(File(file.path)))).toList();
    notifyListeners();
  }

  // Methode, um die Bilddaten als Uint8List zu erhalten
  Future<Uint8List?> getImageData(Image image) async {
    final File imageFile = File((image.image as FileImage).file.path);

    // Komprimierung des Bildes (optional)
    final List<int>? imageBytes = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      quality: 80,
      format: CompressFormat.webp,
    );

    // Rückgabe von Uint8List oder null, je nach Ergebnis der Komprimierung
    return imageBytes != null ? Uint8List.fromList(imageBytes) : null;
  }

  // Methode, um mehrere Bilder hochzuladen
  Future<int> postImages() async {
    List<int> statusCodes = [];

    for (var image in images) {
      try {
        final imageData = await getImageData(image);
        if (imageData != null) {
          final base64Image =
              base64Encode(imageData); // Umwandlung von Uint8List in base64

          final url = Uri.parse(
              "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json?auth=$_token");

          final response = await http.post(
            url,
            body: json.encode(
              {"imageData": base64Image},
            ),
          );

          statusCodes.add(response.statusCode);
        } else {
          statusCodes.add(400); // Fehlercode, falls kein Bild vorhanden ist
        }
      } catch (error) {
        statusCodes.add(400); // Fehlercode für andere Fehler
        if (kDebugMode) print(error);
      }
    }

    // Rückgabe 400, wenn einer der Statuscodes 400 ist
    if (statusCodes.contains(400)) {
      return 400;
    }

    // Erfolgreiche Rückgabe
    return 200;
  }

  // Methode zum Laden von Fotos aus Firebase
  Future<void> getData() async {
    if (!hasMore) return;
    final cachePhotos = loadedData;
    try {
      isHttpProceeding = true;
      List<Photo> loadedNews = [];

      String queryParams = lastId == null
          ? 'orderBy="%24key"&limitToLast=5'
          : 'orderBy="%24key"&endAt="$lastId"&limitToLast=6';

      var response = await http.get(
        Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json?$queryParams"),
      );
      var photoData = json.decode(response.body) as Map<String, dynamic>;

      photoData.forEach((photoId, photoData) {
        loadedNews.add(
          Photo(
            photoId: photoId,
            imageData: base64Decode(photoData["imageData"]),
          ),
        );
      });

      if (lastId != null) {
        loadedNews.removeAt(loadedNews.length - 1);
        if (loadedNews.isEmpty) {
          hasMore = false;
        } else {
          hasMore = loadedNews.length == 5;
          lastId = loadedNews.isNotEmpty ? loadedNews.first.photoId : null;
          for (int i = loadedNews.length - 1; i >= 0; i--) {
            loadedData.insert(0, loadedNews[i]);
          }
        }
      } else {
        hasMore = loadedNews.length == 5;
        lastId = loadedNews.isNotEmpty ? loadedNews.first.photoId : null;
        for (int i = loadedNews.length - 1; i >= 0; i--) {
          loadedData.insert(0, loadedNews[i]);
        }
      }

      isHttpProceeding = false;
      notifyListeners();
    } catch (e) {
      loadedData = cachePhotos;
      if (kDebugMode) {
        print(e);
      }
      if (e.toString().contains("RangeError")) hasMore = false;
    }
  }
}
