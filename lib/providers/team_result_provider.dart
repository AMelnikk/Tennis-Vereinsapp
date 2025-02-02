import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:verein_app/models/calendar_event.dart';
import 'package:verein_app/models/tennismatch.dart';

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
    List<CalendarEvent> events = [];

    for (var spiel in ligaSpiele) {
      String? datumString = spiel["datum"];
      if (datumString == null || datumString.trim().isEmpty) {
        print("Kein Datum gefunden für Spiel: $spiel");
        continue;
      }

      DateTime? spielDatum = parseDate(datumString.trim());
      if (spielDatum == null) {
        print(
            "Datum konnte nicht geparst werden: '$datumString' für Spiel: $spiel");
        continue;
      }

      if (spielDatum.year != jahr) {
        continue;
      }

      // Beispiel: Heimspiel prüfen
      bool istHeimspiel = spiel["heim"] == "TeG Altmühlgrund";

      // Erstelle das Event
      CalendarEvent event = CalendarEvent(
        id: int.tryParse(spiel["id"] ?? "0") ?? 0,
        title: "${istHeimspiel ? "🏠 " : ""}${spiel["altersklasse"]}",
        date: spielDatum, // Wir nutzen hier das geparste Datum
        category: "Ligaspiel",
        description:
            "Gruppe: ${spiel["gruppe"]}\n\n${spiel["heim"]} vs ${spiel["gast"]}\n\nSpielort: ${spiel["spielort"]}\nUhrzeit: ${spiel["uhrzeit"]}",
        query: "",
      );

      events.add(event);
    }
    return events;
  }

  DateTime? parseDate(String dateStr) {
    try {
      // Erstelle ein DateFormat für "dd.MM.yyyy"
      DateFormat format = DateFormat('dd.MM.yyyy');
      DateTime parsedDate = format.parse(dateStr);
      print("Parsed date: $parsedDate"); // Debug-Ausgabe
      return parsedDate;
    } catch (e) {
      print("Fehler beim Parsen des Datums: $dateStr, Fehler: $e");
      return null;
    }
  }

  /// Lädt die Ligaspiele vom Server (z. B. Firebase)
  /// Lädt die Ligaspiele und gibt sie als CalendarEvent für das Jahr zurück
  Future<void> loadLigaSpiele(int jahr) async {
    isLoading = true;
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
    }
  }
}
