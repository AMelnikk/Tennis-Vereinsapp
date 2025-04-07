import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/news.dart';

class NewsProvider with ChangeNotifier {
  NewsProvider(this._token);

  bool isNewsLoading = false;
  List<News> loadedNews = [];
  final String? _token;
  String newsId = '';
  List<String> photoBlob = [];
  var title = TextEditingController();
  final body = TextEditingController();
  var newsDateController = TextEditingController();
  String newsDate = '';
  final categoryController = TextEditingController();
  String author = '';

  String? lastId;
  bool hasMore = true;
  final Map<String, Uint8List> imageCache = {};

  final List<String> categories = [
    "Allgemein",
    "Spielbericht",
  ];
  String selectedCategory = "Allgemein"; // Standardkategorie

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

  Future<String> postNews(String newsId, String author) async {
    bool isUpdate = newsId.isNotEmpty;

    // Datum parsen und formatieren
    DateTime? parsedDate =
        DateFormat("dd.MM.yyyy").parse(newsDateController.text);
    String formattedDate = DateFormat("yyyy-MM-dd").format(parsedDate);

    try {
      // News-Objekt erstellen
      final news = News(
        id: newsId,
        date: formattedDate,
        photoBlob: photoBlob,
        title: title.text,
        body: body.text,
        category: selectedCategory.isEmpty
            ? categoryController.text
            : selectedCategory,
        author: author,
      );

      final http.Response response;
      if (isUpdate && newsId.length > 5) {
        // Update: PUT-Anfrage
        response = await http.put(
          Uri.parse(
              "https://db-teg-default-rtdb.firebaseio.com/News/$newsId.json?auth=$_token"),
          body: json.encode(news.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        // Neu: POST-Anfrage
        response = await http.post(
          Uri.parse(
              "https://db-teg-default-rtdb.firebaseio.com/News.json?auth=$_token"),
          body: json.encode(news.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final String? firebaseId = responseData['name'];

        if (firebaseId != null && !isUpdate) {
          // Wenn es sich um einen neuen Beitrag handelt, die ID setzen und zur Liste hinzufügen
          news.id = firebaseId;
          loadedNews.add(news);
        } else if (firebaseId != null && isUpdate) {
          // Wenn es ein Update ist, die News im Array an der richtigen Stelle aktualisieren
          int index = loadedNews.indexWhere((n) => n.id == news.id);
          if (index != -1) {
            loadedNews[index] = news;
          }
        }

        clearNews(); // Optional: Löscht die News-Daten nach dem Absenden
        notifyListeners(); // Informiert alle Listener über die Änderungen
        return firebaseId ?? newsId; // Rückgabe der ID
      } else {
        throw Exception('Fehler beim Speichern: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Fehler beim POST-Request: $error');
      return ''; // Rückgabe bei Fehler
    }
  }

  void clearNews() {
    newsId = '';
    newsDate = DateFormat("dd.MM.yyyy").format(DateTime.now());
    newsDateController.text = DateFormat("dd.MM.yyyy").format(DateTime.now());
    photoBlob = [];
    title.text = "";
    body.text = "";
    categoryController.text = "Allgemein";
    author = "";
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

  Future<void> loadNews(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://db-teg-default-rtdb.firebaseio.com/News/$id.json'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic>? dbData = json.decode(response.body);

        if (dbData != null) {
          newsId = id;
          title.text = dbData["title"];
          body.text = dbData["body"];
          newsDate = dbData["date"];
          author = dbData["author"];
          categoryController.text = dbData["category"];
          photoBlob = List<String>.from(dbData["photoBlob"] ?? []);
          notifyListeners();
        }
      } else {
        throw Exception('Fehler beim Laden der News: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Fehler beim Laden der News: $error');
    }
  }

  Future<List<News>> loadMannschaftsNews(List<String> ids) async {
    List<News> fetchedNews = [];

    try {
      for (String id in ids) {
        final response = await http.get(
          Uri.parse('https://db-teg-default-rtdb.firebaseio.com/News/$id.json'),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic>? dbData = json.decode(response.body);

          if (dbData != null) {
            News news = News(
              id: id,
              title: dbData["title"] ?? '',
              body: dbData["body"] ?? '',
              date: dbData["date"] ?? '',
              author: dbData["author"] ?? '',
              category: dbData["category"] ?? '',
              photoBlob: List<String>.from(dbData["photoBlob"] ?? []),
            );

            fetchedNews.add(news);
          }
        } else {
          throw Exception(
              'Fehler beim Laden der News mit ID $id: ${response.statusCode}');
        }
      }
    } catch (error) {
      debugPrint('Fehler beim Laden der Mannschafts-News: $error');
    }

    return fetchedNews;
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
