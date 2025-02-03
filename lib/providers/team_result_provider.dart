import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../models/tennismatch.dart';

class LigaSpieleProvider with ChangeNotifier {
  LigaSpieleProvider(this._token);

  final String? _token;
  List<Map<String, dynamic>> ligaSpiele = [];
  bool isLoading = false;

  /// Speichert die Liste der Ligaspiele in Firebase
  Future<int> saveLigaSpiele(List<TennisMatch> spiele) async {
    if (_token == null || _token.isEmpty) {
      return 400; // Fehler: Kein Token vorhanden
    }

    try {
      for (var spiel in spiele) {
        final String datumString = spiel.datum; // "19.10.2024"
        final DateFormat dateFormat = DateFormat("dd.MM.yyyy");
        final DateTime spielDatum = dateFormat.parse(datumString);

        final jahr = spielDatum.year;

        final url = Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/LigaSpiele/$jahr/${spiel.id}.json?auth=$_token");

        final response = await http.put(
          url,
          body: json.encode(spiel
              .toJson()), // Direkt die JSON-Daten des TennisMatch übergeben
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode != 200) {
          debugPrint("Fehler beim Speichern von Spiel ID: ${spiel.id}");
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

  List<CalendarEvent> getLigaSpieleAsEvents(int jahr) {
    return ligaSpiele.where((spiel) {
      final spielDatum = DateTime.tryParse(spiel["datum"] ?? "");
      return spielDatum != null && spielDatum.year == jahr;
    }).map((spiel) {
      bool istHeimspiel = spiel["heim"] == "TeG Altmühlgrund";

      return CalendarEvent(
        id: int.tryParse(spiel["id"] ?? "0") ?? 0,
        title:
            "${istHeimspiel ? "🏠 " : ""}${spiel["altersklasse"]}", // Icon voranstellen, wenn Heimspiel
        date: DateTime.tryParse("${spiel["datum"]} ${spiel["uhrzeit"]}") ??
            DateTime.now(),
        category: "Ligaspiel",
        description:
            "Gruppe: ${spiel["gruppe"]}\n${spiel["heim"]} vs ${spiel["gast"]}\n",
        query: spiel["spielort"] ?? "",
      );
    }).toList();
  }

  /// Lädt die Ligaspiele vom Server (z. B. Firebase)
  /// Lädt die Ligaspiele und gibt sie als CalendarEvent für das Jahr zurück
  Future<void> loadLigaSpiele(int jahr) async {
    isLoading = true;
    notifyListeners();
    try {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/LigaSpiele/$jahr.json");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          ligaSpiele = data.entries.map((entry) {
            final spielData = entry.value;
            return {
              'id': spielData['id'] ?? 'Unknown',
              'datum': spielData['datum'] ?? '',
              'uhrzeit': spielData['uhrzeit'] ?? '',
              'altersklasse': spielData['altersklasse'] ?? '',
              'spielklasse': spielData['spielklasse'] ?? '',
              'gruppe': spielData['gruppe'] ?? '',
              'heim': spielData['heim'] ?? '',
              'gast': spielData['gast'] ?? '',
              'spielort': spielData['spielort'] ?? '',
              'ergebnis': spielData['ergebnis'] ?? '',
              'mf_name': spielData['mf_name'] ?? '',
              'mf_tel': spielData['mf_tel'] ?? '',
              'photo': spielData['photo'] ?? '',
              'saison': spielData['saison'] ?? '',
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
