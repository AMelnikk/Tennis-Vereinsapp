import 'package:verein_app/models/season.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SaisonProvider with ChangeNotifier {
  SaisonProvider(this._token) {
    // Stelle sicher, dass die Saisons beim Start des Providers geladen werden
    loadSaisons();
  }

  bool dataLoaded = false;
  final String? _token;
  bool isLoading = false;
  List<SaisonData> saisons = [];

  Future<void> loadSaisons() async {
    if (isLoading || dataLoaded) return; // Verhindere mehrfaches Laden
    isLoading = true;
    if (_token == null || _token.isEmpty) {
      if (kDebugMode) print("Token fehlt");
    }
    notifyListeners();
    try {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/Saison.json?auth=$_token");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          saisons = data.entries
              .map((entry) => SaisonData.fromJson(entry.value))
              .toList();
        } else {
          saisons = [];
        }
      } else {
        throw Exception("Fehler beim Laden der Saisons");
      }
    } catch (error) {
      debugPrint("Fehler beim Laden der Saisons: $error");
      saisons = [];
    } finally {
      isLoading = false;
      dataLoaded = true;
      notifyListeners();
    }
  }

  Future<List<SaisonData>> getAllSeasons() async {
    // Sicherstellen, dass die Daten geladen sind
    if (!dataLoaded) {
      await loadSaisons();
    }
    return saisons;
  }

  SaisonData getKeyFromSaisonText(String saisonText) {
    final saison = saisons.firstWhere(
      (s) => s.saison == saisonText,
      orElse: () => SaisonData(
          key: '',
          saison: '',
          jahr: -1,
          jahr2: -1), // Fallback auf eine leere SaisonData
    );
    return saison; // Gibt die gefundenen oder leeren SaisonData zurück
  }

  SaisonData getFirstSaison() {
    // Prüfen, ob `saisons` nicht leer ist
    if (saisons.isNotEmpty) {
      // Hole das erste Element
      return saisons[0];
    }
    // Falls die Liste leer ist, gebe eine leere Saison zurück
    return SaisonData(key: '', saison: '', jahr: -1, jahr2: -1);
  }

  /// Speichert eine neue Saison in der Datenbank
  Future<int> saveSaison(SaisonData saisonData) async {
    if (_token == null || _token.isEmpty) {
      return 400; // Fehler: Kein Token vorhanden
    }
    try {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/Saison/${saisonData.key}.json?auth=$_token");
      final response = await http.put(
        url,
        body: json.encode(saisonData.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        await loadSaisons(); // Aktualisiere die Liste nach dem Speichern
      }
      return response.statusCode;
    } on SocketException {
      debugPrint("Netzwerkfehler beim Speichern der Saison");
      return 500;
    } catch (error) {
      debugPrint("Fehler beim Speichern der Saison: $error");
      return 400;
    }
  }
}
