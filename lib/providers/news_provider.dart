import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/news.dart';

class NewsProvider with ChangeNotifier {
  NewsProvider(this._token);

  bool isNewsLoading = false;
  bool isFirstLoading = true;
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
    String customId = "$formattedDate-${DateTime.now().millisecondsSinceEpoch}";

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
        lastUpdate: DateTime.now().millisecondsSinceEpoch,
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
        response = await http.put(
          Uri.parse(
              "https://db-teg-default-rtdb.firebaseio.com/News/$customId.json?auth=$_token"),
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
        return isUpdate ? newsId : customId;
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

  Future<News> loadNews(String id) async {
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
          DateTime parsedDate =
              DateTime.parse(dbData["date"]); // funktioniert mit '2025-04-12'
          newsDateController.text = DateFormat("dd.MM.yyyy").format(parsedDate);
          newsDate = dbData["date"];
          author = dbData["author"];
          categoryController.text = dbData["category"];
          photoBlob = List<String>.from(dbData["photoBlob"] ?? []);
          notifyListeners();

          // Create and return a News object

          return News(
            id: id,
            title: dbData["title"],
            body: dbData["body"],
            date: newsDateController.text,
            author: dbData["author"],
            category: dbData["category"],
            photoBlob: List<String>.from(dbData["photoBlob"] ?? []),
            lastUpdate: DateTime.now().millisecondsSinceEpoch,
          );
        }
      } else {
        throw Exception('Fehler beim Laden der News: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Fehler beim Laden der News: $error');
      rethrow; // Optionally rethrow the error to be handled by the caller
    }

    // Return a default News object or throw an error if no data is available
    throw Exception('No data found for News ID: $id');
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
            DateTime parsedDate =
                DateTime.parse(dbData["date"]); // funktioniert mit '2025-04-12'
            News news = News(
              id: id,
              title: dbData["title"] ?? '',
              body: dbData["body"] ?? '',
              date: DateFormat("dd.MM.yyyy").format(parsedDate),
              author: dbData["author"] ?? '',
              category: dbData["category"] ?? '',
              photoBlob: List<String>.from(dbData["photoBlob"] ?? []),
              lastUpdate: DateTime.now().millisecondsSinceEpoch,
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

      if (kDebugMode) print(response.statusCode);

      List<String> s = <String>[];
      List<News> loadedData = [];
      Map<String, dynamic> dbData = await json.decode(response.body);
      dbData.forEach(
        (id, value) {
          DateTime parsedDate = DateTime.parse(value[
              "date"]); // Accessing value["date"] instead of dbData["date"]
          loadedData.add(
            News(
              id: id,
              title: value["title"] != null ? value["title"] as String : '',
              body: value["body"] != null ? value["body"] as String : '',
              date: DateFormat("dd.MM.yyyy").format(parsedDate),
              author: value["author"] != null ? value["author"] as String : '',
              category:
                  value["category"] != null ? value["category"] as String : '',
              photoBlob:
                  value["photoBlob"] == null || value["photoBlob"] == "null"
                      ? s
                      : List<String>.from(
                          value["photoBlob"].map((item) => item.toString())),
              lastUpdate: value["lastUpdate"] != null
                  ? int.tryParse(value["lastUpdate"].toString()) ?? 0
                  : 0,
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
      isFirstLoading = false;
    } catch (error) {
      loadedNews = cacheNews;
      isFirstLoading = false;
    }
  }
}
