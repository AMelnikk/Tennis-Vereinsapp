import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class LigaSpieleProvider with ChangeNotifier {
  LigaSpieleProvider(this._token);

  final String? _token;
  List<Map<String, dynamic>> ligaSpiele = [];
  bool isLoading = false;

  /// Speichert die Liste der Ligaspiele in Firebase
  Future<int> saveLigaSpiele(List<Map<String, dynamic>> spiele) async {
    if (_token == null || _token.isEmpty) {
      return 400; // Fehler: Kein Token vorhanden
    }

    try {
      for (var spielData in spiele) {
        final String datumString = spielData['datum']; // "19.10.2024"
        final DateFormat dateFormat = DateFormat("dd.MM.yyyy");
        final DateTime spielDatum = dateFormat.parse(datumString);

        final jahr = spielDatum.year;

        final url = Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/LigaSpiele/$jahr/${spielData['id']}.json?auth=$_token");

        final response = await http.put(
          url,
          body: json.encode({
            'id': spielData['id'],
            'datum': DateFormat('yyyy-MM-dd').format(spielDatum), // Nur Datum
            'uhrzeit': spielData['uhrzeit'], // Nur Uhrzeit
            'altersklasse': spielData['altersklasse'],
            'spielklasse': spielData['spielklasse'],
            'gruppe': spielData['gruppe'],
            'heim': spielData['heim'],
            'gast': spielData['gast'],
            'spielort': spielData['spielort'],
            'ergebnis': spielData['ergebnis'],
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode != 200) {
          debugPrint("Fehler beim Speichern von Spiel ID: ${spielData['id']}");
          return response.statusCode;
        }
      }
      return 200;
    } on SocketException {
      debugPrint("Netzwerkfehler beim Speichern der Ligaspiele");
      return 500;
    } catch (error) {
      debugPrint("Fehler beim Speichern der Ligaspiele: $error");
      return 400;
    }
  }

  /// Lädt die Ligaspiele vom Server (z. B. Firebase)
  Future<void> loadLigaSpiele() async {
    isLoading = true;
    notifyListeners();
    try {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/LigaSpiele.json");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          ligaSpiele = data.entries.map((entry) {
            final spielData = entry.value;
            return {
              'id': spielData['id'] ?? 'Unknown',
              'datum':
                  DateTime.tryParse(spielData['datum'] ?? '') ?? DateTime.now(),
              'uhrzeit': spielData['uhrzeit'] ?? '',
              'altersklasse': spielData['altersklasse'] ?? '',
              'spielklasse': spielData['spielklasse'] ?? '',
              'gruppe': spielData['gruppe'] ?? '',
              'heim': spielData['heim'] ?? '',
              'gast': spielData['gast'] ?? '',
              'spielort': spielData['spielort'] ?? '',
              'ergebnis': spielData['ergebnis'] ?? '',
            };
          }).toList();
        } else {
          ligaSpiele = [];
        }
      } else {
        throw Exception("Fehler beim Laden der Ligaspiele");
      }
    } catch (error) {
      debugPrint("Fehler beim Laden der Ligaspiele: $error");
      ligaSpiele = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
