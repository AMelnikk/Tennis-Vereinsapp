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
  List<TennisMatch> ligaSpiele = [];
  int jahrDerLigaspiele = 0;
  bool isLoading = false;

  bool updateRequired(int jahr) {
    if (ligaSpiele.isNotEmpty && jahrDerLigaspiele == jahr) {
      return false;
    } else {
      return true;
    }
  }

  List<CalendarEvent> getLigaSpieleAsEvents(int jahr) {
    List<CalendarEvent> events = [];

    if (updateRequired(jahr)) {
      loadLigaSpiele(jahr);
    }

    for (var spiel in ligaSpiele) {
      DateTime? spielDatum = spiel.datum;
      if (spielDatum.year != jahr) {
        continue;
      }

      // Beispiel: Heimspiel prüfen
      bool istHeimspiel = spiel.heim == "TeG Altmühlgrund";

      // Erstelle das Event
      CalendarEvent event = CalendarEvent(
        id: int.tryParse(spiel.id) ?? 0,
        title: "${istHeimspiel ? "🏠 " : ""}${spiel.altersklasse}",
        date: spielDatum, // Wir nutzen hier das geparste Datum
        category: "Ligaspiel",
        description:
            "Gruppe: ${spiel.gruppe}\n\n${spiel.heim} vs ${spiel.gast}\n\nSpielort: ${spiel.spielort}\nUhrzeit: ${spiel.uhrzeit}",
        query: "",
      );

      events.add(event);
    }
    return events;
  }

  Future<List<TennisMatch>> getLigaSpieleForMannschaft(
      int jahr, String mannschaftName, String saisonKey) async {
    // Lade Liga-Spiele für das Jahr (asynchron)
    if (updateRequired(jahr)) {
      await loadLigaSpiele(jahr);
    }

    // Filtern der Liga-Spiele nach Mannschaftsname in Altersklasse
    return ligaSpiele
        .where((spiel) =>
            spiel.altersklasse.trim().toUpperCase() ==
                mannschaftName.trim().toUpperCase() &&
            spiel.saison == saisonKey)
        .toList();
  }

  /// Speichert die Liste der Ligaspiele in Firebase
  Future<int> saveLigaSpiele(List<TennisMatch> spiele) async {
    if (_token == null || _token.isEmpty) {
      return 400; // Fehler: Kein Token vorhanden
    }

    try {
      for (var spiel in spiele) {
        final DateTime spielDatum = spiel.datum;

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

  DateTime? parseDate(String dateStr) {
    try {
      // Erstelle ein DateFormat für "dd.MM.yyyy"
      DateFormat format = DateFormat('dd.MM.yyyy');
      DateTime parsedDate = format.parse(dateStr);
      return parsedDate;
    } catch (e) {
      return null;
    }
  }

  /// Lädt die Ligaspiele vom Server (z. B. Firebase)
  /// Lädt die Ligaspiele und gibt sie als CalendarEvent für das Jahr zurück
  // Lädt die Ligaspiele vom Server (z. B. Firebase)
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
            final String datumString = spielData['datum']; // "19.10.2024"
            final DateFormat dateFormat = DateFormat("dd.MM.yyyy");
            final DateTime spielDate = dateFormat.parse(datumString);

            return TennisMatch(
              id: spielData['id'] ?? 'Unknown',
              datum: spielDate,
              uhrzeit: spielData['uhrzeit'] ?? '',
              altersklasse: spielData['altersklasse'] ?? '',
              spielklasse: spielData['spielklasse'] ?? '',
              gruppe: spielData['gruppe'] ?? '',
              heim: spielData['heim'] ?? '',
              gast: spielData['gast'] ?? '',
              spielort: spielData['spielort'] ?? '',
              ergebnis: spielData['ergebnis'] ?? '',
              saison: spielData['saison'] ?? '',
            );
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
      jahrDerLigaspiele = jahr;
    }
  }
}
