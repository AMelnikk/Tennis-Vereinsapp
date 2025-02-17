import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PhotoProvider with ChangeNotifier {
  PhotoProvider(this._token);
  final String? _token;

  // Alle Fotos in einer Map nach Kategorien gespeichert
  var photoDateController = TextEditingController();
  bool isHttpProceeding = false;
  String? lastId;
  bool hasMore = true;
  List<String> currentCategoryPhotos = [];
  String category = '';

  final int categoriesPerPage =
  6; // Hier definierst du die Anzahl der Kategorien pro Seite
  int currentPage = 1; // Die erste Seite
// 📌 Gibt alle Kategorien zurück
  List<String> get categories => _photosByCategory.keys.toList();
  final Map<String, List<String>> _photosByCategory =
  {}; // Caching der geladenen Kategorien
  bool hasMoreCategories = true; // Flag für mehr Kategorien

  // 📌 Gibt alle Bilder einer bestimmten Kategorie zurück
  List<String> getImagesByCategory(String categoryName) {
    return _photosByCategory[categoryName] ?? [];
  }

  // 📌 Holt das erste Bild einer Kategorie als Vorschaubild
  Widget getPreviewImage(String categoryName) {
    if (_photosByCategory[categoryName]?.isNotEmpty ?? false) {
      // Decoding the base64 string and returning an Image widget
      String base64Image = _photosByCategory[categoryName]!.first;
      Uint8List decodedImage = base64Decode(base64Image);

      return Image.memory(
        decodedImage,
        fit: BoxFit.cover, // You can adjust the fit to your needs
      );
    }
    return const SizedBox(); // Return an empty widget if no image exists
  }

// Method to update the category
  void updateCategory(String newCategory) {
    category = newCategory;
    notifyListeners(); // Notify listeners to rebuild the UI
  }

  // Methode, um mehrere Bilder hochzuladen
  Future<int> postImages(String category) async {
    List<int> statusCodes = [];

    for (var photo in currentCategoryPhotos) {
      try {
        final base64Image = photo;

        final url = Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie/$category.json?auth=$_token");

        final response = await http.post(
          url,
          body: json.encode({"imageData": base64Image}),
        );

        statusCodes.add(response.statusCode);
      } catch (error) {
        statusCodes.add(400); // Fehlercode für andere Fehler
        if (kDebugMode) print(error);
      }
    }

    return statusCodes.contains(400) ? 400 : 200;
  }

  // Methode zum Laden der Kategorien mit Paginierung
  Future<void> loadCategoriesForPage() async {
    try {
      if (!hasMoreCategories) return;
      // Berechne, welche Kategorien auf der aktuellen Seite geladen werden sollen
      int startIndex = (currentPage - 1) * categoriesPerPage;
      int endIndex = startIndex + categoriesPerPage;

      // Firebase-URL anpassen, um nur die relevanten Kategorien zu laden
      String queryParams =
          'orderBy="%24key"&startAt="$startIndex"&endAt="$endIndex"';
      final url =
          "https://db-teg-default-rtdb.firebaseio.com/Fotogalerie.json?$queryParams&auth=$_token";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var categoryData = json.decode(response.body) as Map<String, dynamic>;

        // Prüfen, ob die Rückgabe nicht leer ist
        if (categoryData.isEmpty) {
          print("Keine Kategorien in der Fotogalerie.");
          return;
        }

        // Hier durch den Knoten 'Fotogalerie' iterieren
        categoryData.forEach((categoryKey, categoryValue) {
          if (categoryValue is Map<String, dynamic>) {
            categoryValue.forEach((categoryId, categoryDetails) {
              // Überprüfen, ob 'imageData' vorhanden ist
              if (categoryDetails is Map<String, dynamic>) {
                final imageData = categoryDetails['imageData'] as String;

                // Hier wird die Kategorie und die Bilddaten gespeichert
                if (!_photosByCategory.containsKey(categoryKey)) {
                  _photosByCategory[categoryKey] = [];
                }
                _photosByCategory[categoryKey]!.add(imageData);
              }
            });
          }
        });

        // Prüfen, ob die Kategorien korrekt gespeichert wurden
        print(_photosByCategory);

        // Überprüfen, ob es noch mehr Kategorien gibt
        hasMoreCategories = categoryData.length >= categoriesPerPage;

        // Setze die aktuelle Seite für das nächste Laden
        if (hasMoreCategories) {
          currentPage++;
        }

        notifyListeners(); // UI aktualisieren
      } else {
        throw Exception(
            'Fehler beim Laden der Kategorien. Statuscode: ${response.statusCode}');
      }
    } catch (e) {
      print("Fehler beim Laden der Kategorien: $e");
      // Fehlerbehandlung, falls beim Laden etwas schiefgeht
    }
  }
}
