import '../models/season.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SaisonProvider with ChangeNotifier {
  SaisonProvider(this._token) {
    // Stelle sicher, dass die Saisons beim Start des Providers geladen werden
  }

  bool dataLoaded = false;
  final String? _token;
  bool isLoading = false;
  List<SaisonData> saisons = [];
  bool isDebug = false;

  // Diese Methode gibt das SaisonData zurück, das mit dem Namen der Saison übereinstimmt
  SaisonData getSaisonDataForSaisonKey(String saisonKey) {
    return saisons.firstWhere(
      (saisonData) => saisonData.key == saisonKey,
      orElse: () => SaisonData(
        key: '',
        saison: '',
        jahr: -1,
        jahr2: -1, // Default values if not found
      ),
    );
  }

  Future<void> loadSaisons({bool forceReload = false}) async {
    if (isLoading || (dataLoaded && !forceReload)) return;
    isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/Saison.json?auth=$_token");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (isDebug) {
          debugPrint(
              "SaisonProvider Data Received: $data"); // Fügen Sie dies HINZU
        }
        if (data == null || data is! Map<String, dynamic>) {
          // <--- WICHTIGE PRÜFUNG auf NULL
          saisons = [];
        } else {
          saisons = data.entries
              .map((entry) => SaisonData.fromJson(entry.value))
              .toList();

          if (isDebug) {
            // NEU: Debuggen, um zu sehen, wie viele Saisons geladen wurden
            debugPrint("SaisonProvider Saisons Loaded: ${saisons.length}");
          }
        }
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

  // Sortiere die Saisons, wenn sie abgerufen werden
  void _sortSaisons() {
    saisons.sort((a, b) {
      final aJahr = a.jahr2 != -1 ? a.jahr2 : a.jahr;
      final bJahr = b.jahr2 != -1 ? b.jahr2 : b.jahr;

      if (aJahr != bJahr) {
        return bJahr.compareTo(aJahr); // Neueste Saison zuerst
      } else {
        return b.jahr.compareTo(
            a.jahr); // Zweites Jahr wird verglichen, falls Jahr1 gleich
      }
    });
  }

  Future<List<SaisonData>> getAllSeasons() async {
    // Sicherstellen, dass die Daten geladen sind
    if (!dataLoaded) {
      await loadSaisons();
    }
    _sortSaisons();
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

  String getSaisonTextFromKey(String saisonKey) {
    // Die Suche erfolgt über das 'key'-Feld des SaisonData-Objekts.
    final saisonData = saisons.firstWhere(
      (s) => s.key == saisonKey,

      // Fallback: Wenn der Key nicht gefunden wird, gib ein leeres Objekt zurück.
      orElse: () => SaisonData(
          key: '',
          saison: '', // Der Name der Saison (z.B. "Saison 2025/2026")
          jahr: -1,
          jahr2: -1),
    );

    // Gibt das gefundene (oder das leere) SaisonData-Objekt zurück.
    return saisonData.saison;
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
