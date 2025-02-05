import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:verein_app/utils/app_utils.dart';
import 'package:verein_app/utils/image_helper.dart';
import '../models/news.dart';

class NewsProvider with ChangeNotifier {
  NewsProvider(this._token);

  bool isNewsLoading = false;
  List<News> loadedNews = [];
  final String? _token;
  List<String> photoBlob = [];
  final title = TextEditingController();
  final body = TextEditingController();
  var newsDateController = TextEditingController();
  String newsDate = '';
  final categoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? lastId;
  bool hasMore = true;
  final Map<String, Uint8List> imageCache = {};

  final List<String> categories = [
    "Allgemein",
    "Mannschaften Erwachsene",
    "Mannschaften Jugend"
  ];
  String selectedCategory = "Allgemein"; // Standardkategorie

  Future<void> pickAndUploadImages(ScaffoldMessengerState messenger) async {
    try {
      // Mehrere Bilder auswählen
      final List<XFile> images = await _picker.pickMultiImage();

      // Sicherstellen, dass images nicht null ist und mindestens ein Bild vorhanden ist
      if (images.isNotEmpty) {
        // Umwandlung der Bilder in Base64-Strings durch Aufruf der Hilfsmethode
        photoBlob = await convertImagesToBase64(images);
      } else {
        appError(messenger, "Keine Bilder ausgewählt.");
      }
    } catch (e) {
      appError(messenger, "Fehler beim Auswählen der Bilder: $e");
    }
  }
  // Methode zum Hochladen der Bilder als Blob in Firestore
  // Future<void> _storeImagesToFirestore(List<Uint8List> bytesList) async {
  //   try {
  //     // Ein Firestore-Dokument erstellen und die Bilder als Blob speichern
  //     FirebaseFirestore.instance.collection("images").add({
  //       'images': FieldValue.arrayUnion(
  //           bytesList.map((bytes) => Blob.fromBytes(bytes)).toList()),
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }).then((value) {
  //       setState(() {
  //         _uploadStatus = 'Bilder erfolgreich hochgeladen!';
  //       });
  //     }).catchError((error) {
  //       print("Fehler beim Speichern der Bilder in Firestore: $error");
  //     });
  //   } catch (e) {
  //     print("Fehler beim Hochladen der Bilder: $e");
  //  }
  // }

  //Versuch als Datei zu speichern und nur die URL in der DB - hat nicht funktioniert
  // Future<void> pickImage() async {
  //   try {
  //    final ImagePicker picker = ImagePicker();
  //    List<XFile>? files = await picker.pickMultiImage();

  // No need to check for null since files is nullable and we handle that gracefully
  //    if (files.isNotEmpty ?? false) {
  //      // Convert XFile to File
  //      List<File> imageFiles = files.map((xfile) => File(xfile.path)).toList();

  // Save image URLs to Firebase
//        imageUrls = await saveImageUrlsToFirebase(imageFiles);
  //    }
  //    notifyListeners();
  //  } catch (e) {
  //    debugPrint("Fehler beim Laden des Bildes: $e");
  //  }
  //}

  void updateCategory(String newCategory) {
    selectedCategory = newCategory;
    notifyListeners();
  }

  Future<String?> postNews() async {
    if (newsDate == null) {
      newsDate = DateFormat("dd.MM.yyyy").format(DateTime.now());
    } else {
      DateTime? parsedDate =
          DateFormat("dd.MM.yyyy").parse(newsDateController.text);
      newsDate = DateFormat("dd.MM.yyyy").format(parsedDate);
    }
    try {
      // Konvertiere das Bild in Base64

      final news = News(
        id: '', // Firebase generiert eine ID
        date: newsDate,
        photoBlob: photoBlob,
        title: title.text,
        body: body.text,
        category: selectedCategory.isEmpty
            ? categoryController.text
            : selectedCategory,
        author: _token.toString(),
      );

      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/News.json?auth=$_token");

      final response = await http.post(
        url,
        body: json.encode(news.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      loadedNews.add(news);
      notifyListeners();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['name'] as String?; // Rückgabe der Firebase-ID
      } else {
        throw Exception('Fehler beim Speichern: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Fehler beim POST-Request: $error');
      return null;
    }
  }

  Future<void> deleteNews(String id) async {
    try {
      if (kDebugMode) print(id);
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/News/$id.json?auth=$_token");
      final responce = await http.delete(url);
      loadedNews.removeWhere((item) => item.id == id);
      if (kDebugMode) print(responce.statusCode);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print(e);
    }
    notifyListeners();
  }

  Future<void> getData() async {
    final cacheNews = loadedNews;
    if (!hasMore) {
      return;
    }
    try {
      String queryParams = lastId == null
          ? 'orderBy="%24key"&limitToLast=5'
          : 'orderBy="%24key"&endAt="$lastId"&limitToLast=6';
      var response = await http.get(
        Uri.parse(
            'https://db-teg-default-rtdb.firebaseio.com/News.json?$queryParams'),
      );

      List<String> s = <String>[];
      List<News> loadedData = [];
      Map<String, dynamic> dbData = await json.decode(response.body);
      dbData.forEach(
        (id, value) {
          loadedData.add(
            News(
              id: id,
              title: value["title"] != null ? value["title"] as String : '',
              body: value["body"] != null ? value["body"] as String : '',
              date: value["date"] != null ? value["date"] as String : '',
              author: value["author"] != null ? value["author"] as String : '',
              category:
                  value["category"] != null ? value["category"] as String : '',
              photoBlob:
                  value["photoBlob"] == null || value["photoBlob"] == "null"
                      ? s
                      : List<String>.from(
                          value["photoBlob"].map((item) => item.toString())),
            ),
          );
        },
      );
      if (lastId != null) {
        loadedData.removeAt(loadedData.length - 1);
      }
      hasMore = dbData.length == 5;
      lastId = loadedData.isNotEmpty ? loadedData.first.id : null;
      loadedNews.insertAll(0, loadedData);
      notifyListeners();
    } catch (error) {
      loadedNews = cacheNews;
    }
  }
}
