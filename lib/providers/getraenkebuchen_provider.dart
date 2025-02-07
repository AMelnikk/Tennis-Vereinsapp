import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:verein_app/utils/app_utils.dart';

class GetraenkeBuchenProvider with ChangeNotifier {
  GetraenkeBuchenProvider(this._token);

  final String? _token;
  String username = '';
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
    _summe = 0.0;
    notifyListeners();
  }

  // Methode zur Aktualisierung der Summe
  void _updateSumme() {
    _summe = _anzWasser * 1.00 + _anzSoft * 1.50 + _anzBier * 2.00;
    notifyListeners();
  }

  // Methode zum Absenden der Getränkedaten
  Future<int> postGetraenke(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context); // Vorher speichern

    if (_token == null) {
      if (kDebugMode) print("Token fehlt");
      return 400;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final date = DateTime.now().toIso8601String();

    try {
      if (username.isEmpty) {
        if (kDebugMode) {
          appError(
              messenger, "Fehler: Benutzername konnte nicht geladen werden.");
        }
        return 400;
      }

      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/GetränkeListe/Getraenke_$timestamp.json?auth=$_token");

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
          'bezahlt': false, // Neu hinzugefügtes Feld
        }),
        headers: {'Content-Type': 'application/json'},
      );

      resetData();

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
        "https://db-teg-default-rtdb.firebaseio.com/GetränkeListe.json?");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;

        if (data == null) return [];

        // Alle Buchungen werden zurückgegeben
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

  // Methode zum Abrufen der Buchungen für einen spezifischen Benutzer
  Future<List<Map<String, dynamic>>> fetchUserBuchungen() async {
    final allBuchungen = await getAllBuchungen();
    return allBuchungen
        .where((buchung) => buchung['username'] == username)
        .toList();
  }

  // Methode zum Aktualisieren des Bezahlt-Status einer Buchung
  Future<int> updateBezahlt(String buchungId, bool bezahlt) async {
    if (_token == null || _token.isEmpty) {
      if (kDebugMode) print("Token fehlt");
      return 400;
    }

    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/GetränkeListe/$buchungId.json?auth=$_token");

    try {
      final response = await http.patch(
        url,
        body: json.encode({
          'bezahlt': bezahlt,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return 200; // Erfolgreiche Aktualisierung
      } else {
        return response.statusCode;
      }
    } catch (error) {
      if (kDebugMode) print("Fehler beim Aktualisieren des Status: $error");
      return 400;
    }
  }

  // Methode zum Löschen einer Buchung
  Future<int> deleteBuchung(String buchungId) async {
    if (_token == null || _token.isEmpty) {
      if (kDebugMode) print("Token fehlt");
      return 400;
    }

    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/GetränkeListe/$buchungId.json?auth=$_token");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return 200; // Erfolgreiches Löschen
      } else {
        return response.statusCode;
      }
    } catch (error) {
      if (kDebugMode) print("Fehler beim Löschen der Buchung: $error");
      return 400;
    }
  }
}
