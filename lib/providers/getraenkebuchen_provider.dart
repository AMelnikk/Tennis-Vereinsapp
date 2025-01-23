import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GetraenkeBuchenProvider with ChangeNotifier {
  GetraenkeBuchenProvider(this._token);

  final String? _token;

  int _anzWasser = 0;
  int _anzSoft = 0;
  int _anzBier = 0;
  double _summe = 0;

  // Getter für die Getränkeanzahl und Summe
  int get anzWasser => _anzWasser;
  int get anzSoft => _anzSoft;
  int get anzBier => _anzBier;
  double get summe => _summe;

  // Methode zum Aktualisieren der Wasseranzahl
  void updateWasser(int value) {
    _anzWasser = value;
    _updateSumme();
  }

  // Methode zum Aktualisieren der Softdrinkanzahl
  void updateSoft(int value) {
    _anzSoft = value;
    _updateSumme();
  }

  // Methode zum Aktualisieren der Bieranzahl
  void updateBier(int value) {
    _anzBier = value;
    _updateSumme();
  }

  // Methode zum Zurücksetzen der Daten
  void resetData() {
    _anzWasser = 0;
    _anzSoft = 0;
    _anzBier = 0;
    _summe = 0;
    notifyListeners();
  }

  // Methode zur Aktualisierung der Summe
  void _updateSumme() {
    _summe = _anzWasser * 1.00 + _anzSoft * 1.50 + _anzBier * 2.00;
    notifyListeners();
  }

  // Methode zum Absenden der Getränkedaten
  Future<int> postGetraenke() async {
    if (_token == null || _token.isEmpty) {
      if (kDebugMode) print("Token fehlt");
      return 400;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final date = DateTime.now().toIso8601String();
    final username = 'Oli'; // Benutzername kann dynamisch gesetzt werden

    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/GetrankeListe/Getraenke_$timestamp.json?auth=$_token");

    try {
      final response = await http.put(
        url,
        body: json.encode({
          'anzWasser': _anzWasser,
          'anzSoft': _anzSoft,
          'anzBier': _anzBier,
          'summe': _summe,
          'timestamp': timestamp,
          'date': date,
          'username': username,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (kDebugMode) print("Response status: ${response.statusCode}");
      if (kDebugMode) print("Response body: ${response.body}");

      return response.statusCode;
    } on SocketException {
      if (kDebugMode) print("Netzwerkfehler aufgetreten");
      return 500; // Fehler für Netzwerkprobleme
    } catch (error) {
      if (kDebugMode) print("Ein unerwarteter Fehler ist aufgetreten: $error");
      return 400;
    }
  }

  // Methode zum Abrufen aller Buchungen
  Future<List<Map<String, dynamic>>> getAllBuchungen() async {
    if (_token == null || _token.isEmpty) {
      throw Exception("Token fehlt");
    }

    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/GetrankeListe.json?auth=$_token");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;
        if (data == null) return [];

        return data.entries.map((entry) {
          final buchung = entry.value as Map<String, dynamic>;
          return {
            'id': entry.key,
            ...buchung,
          };
        }).toList();
      } else {
        throw Exception("Fehler beim Abrufen der Buchungen");
      }
    } catch (error) {
      throw Exception("Fehler beim Abrufen der Buchungen: $error");
    }
  }
}
