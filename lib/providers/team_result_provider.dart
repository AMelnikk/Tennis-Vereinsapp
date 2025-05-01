import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/season.dart';
import '../models/calendar_event.dart';
import '../models/tennismatch.dart';

class LigaSpieleProvider with ChangeNotifier {
  LigaSpieleProvider(this._token);

  final String? _token;
  final Map<int, List<TennisMatch>> _cachedLigaSpiele = {}; // Cache
  final Map<int, Future<void>> _loadingFutures =
      {}; // Läuft bereits eine Anfrage?

  bool isLoading = false;

  List<TennisMatch> getLigaSpiele(int jahr) {
    return _cachedLigaSpiele[jahr] ?? [];
  }

  /// **Sicherstellen, dass die Ligaspiele für ein bestimmtes Jahr geladen sind.**
  Future<void> ensureLigaSpieleGeladen(int jahr) async {
    // Wenn die Daten bereits geladen werden, dann warte darauf.
    if (_loadingFutures.containsKey(jahr)) {
      await _loadingFutures[jahr];
      return; // Falls die Daten schon geladen werden, einfach zurückkehren
    }

    // Wenn noch nicht geladen, initialisiere den Ladeprozess und speichere die Future.
    _loadingFutures[jahr] = loadLigaSpieleForYear(jahr);
    await _loadingFutures[
        jahr]; // Warten bis die Daten vollständig geladen sind.
  }

  /// **Lädt die Ligaspiele für ein bestimmtes Jahr nur einmal und cached sie.**
  Future<List<TennisMatch>> loadLigaSpieleForYear(int jahr) async {
    // Prüfen, ob die Daten bereits im Cache vorhanden sind
    if (_cachedLigaSpiele.containsKey(jahr)) {
      return _cachedLigaSpiele[
          jahr]!; // Wenn die Daten schon im Cache sind, zurückgeben.
    }

    // URL für die API-Anfrage
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/LigaSpiele/$jahr.json?auth=$_token");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          // Ligaspiele aus der API-Antwort extrahieren und in eine Liste umwandeln
          final spiele = data.entries.map((entry) {
            final spielData = entry.value;

            // Sicherheitsvorkehrungen beim Parsen des Datums
            DateTime spielDate;
            try {
              spielDate = DateFormat("dd.MM.yyyy").parse(spielData['datum']);
            } catch (e) {
              debugPrint(
                  "Fehler beim Parsen des Datums: ${spielData['datum']}");
              spielDate = DateTime.now(); // Default-Wert im Fehlerfall
            }

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
              spielbericht: spielData['spielbericht'] ?? '',
              photoBlobSB: null,
            );
          }).toList();

          // Ligaspiele nach Datum aufsteigend sortieren
          spiele.sort((a, b) => a.datum.compareTo(b.datum));

          // Speichern der geladenen Spiele im Cache
          _cachedLigaSpiele[jahr] = spiele;
          return spiele;
        } else {
          return []; // Falls das Datenformat nicht passt
        }
      } else {
        throw Exception(
            "Fehler beim Laden der Ligaspiele für Jahr $jahr, StatusCode: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Fehler beim Laden der Ligaspiele: $error");
      return []; // Rückgabe einer leeren Liste im Fehlerfall
    }
  }

  Future<void> loadLigaSpieleForSeason(SaisonData saisonData) async {
    final jahr1 = saisonData.jahr;
    final jahr2 = saisonData.jahr2;

    // Überprüfen, ob das Startjahr gültig ist
    if (jahr1 == -1) {
      return; // Kein gültiges Startjahr
    }

    isLoading = true;
    notifyListeners();

    try {
      // Ligaspiele für das Startjahr laden (wird bereits von _loadLigaSpieleForYear überprüft und gecached)
      await loadLigaSpieleForYear(jahr1);

      // Wenn ein Endjahr vorhanden ist, auch dieses Jahr laden
      if (jahr2 != -1) {
        await loadLigaSpieleForYear(jahr2);
      }
    } catch (e) {
      debugPrint(
          "Fehler beim Laden der Ligaspiele für Saison ${saisonData.key}: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// **Filtert Ligaspiele nach Saison, Jahr oder Altersklasse**
  List<TennisMatch> getFilteredSpiele(
      {String? saisonKey, int? jahr, String? altersklasse}) {
    List<TennisMatch> filteredSpiele;

    if (jahr != null && _cachedLigaSpiele.containsKey(jahr)) {
      filteredSpiele = _cachedLigaSpiele[jahr]!.where((spiel) {
        final bool matchSaison = saisonKey == null || spiel.saison == saisonKey;
        final bool matchAltersklasse = altersklasse == null ||
            altersklasse == "Alle" ||
            spiel.altersklasse == altersklasse;
        return matchSaison && matchAltersklasse;
      }).toList();
    } else {
      // Falls kein spezifisches Jahr angegeben oder noch nicht geladen wurde
      filteredSpiele =
          _cachedLigaSpiele.values.expand((spiele) => spiele).where((spiel) {
        final bool matchSaison = saisonKey == null || spiel.saison == saisonKey;
        final bool matchJahr = jahr == null || spiel.datum.year == jahr;
        final bool matchAltersklasse = altersklasse == null ||
            altersklasse == "Alle" ||
            spiel.altersklasse == altersklasse;
        return matchSaison && matchJahr && matchAltersklasse;
      }).toList();
    }

    // Sortiere die gefilterten Spiele nach Datum aufsteigend
    filteredSpiele.sort((a, b) => a.datum.compareTo(b.datum));

    return filteredSpiele;
  }

  List<CalendarEvent> getLigaSpieleAsEvents(int jahr) {
    if (!_cachedLigaSpiele.containsKey(jahr)) {
      return [];
    }

    return _cachedLigaSpiele[jahr]!.map((spiel) {
      bool istHeimspiel = spiel.heim.startsWith("TeG Altmühlgrund");

      // Extrahieren der Uhrzeit
      List<String> uhrzeitParts = spiel.uhrzeit.split(":");
      int stunde = int.parse(uhrzeitParts[0]);
      int minute = int.parse(uhrzeitParts[1]);

      // Berechnen der Startzeit
      DateTime startDate = DateTime(
        spiel.datum.year,
        spiel.datum.month,
        spiel.datum.day,
        stunde,
        minute,
      );

      // Beispiel für dynamische Endzeit (falls Spieldauer in Minuten verfügbar ist)
      DateTime endDate = startDate.add(Duration(minutes: 90));

      // Dynamisches Titel-Label je nach Heim- oder Auswärtsspiel
      String spielTitle = istHeimspiel
          ? "${spiel.altersklasse} - ${spiel.gast}"
          : "${spiel.heim} - ${spiel.altersklasse}";

      return CalendarEvent(
        id: int.tryParse(spiel.id) ?? 0,
        title: spielTitle, // Dynamisches Title mit Heim- oder Auswärtsspiel
        ort: spiel.spielort,
        date: startDate, // Startzeit
        von:
            "${stunde.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
        bis:
            "${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}", // Endzeit formatieren
        category: "Ligaspiel",
        description:
            "Gruppe: ${spiel.gruppe}\n\n${spiel.heim} vs ${spiel.gast}\n\nSpielort: ${spiel.spielort}\nUhrzeit: ${spiel.uhrzeit}",
        query: "",
      );
    }).toList();
  }

  bool updateRequired(int jahr) {
    return !_cachedLigaSpiele.containsKey(jahr);
  }

  Future<int> saveLigaSpiele(List<TennisMatch> spiele) async {
    if (_token == null || _token.isEmpty) return 400;

    try {
      for (var spiel in spiele) {
        final jahr = spiel.datum.year;
        final url = Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/LigaSpiele/$jahr/${spiel.id}.json?auth=$_token");
        final response = await http.put(
          url,
          body: json.encode(spiel.toJson(
            includeErgebnis: true,
            includeSpielbericht: true,
            includePhotoBlob: true,
          )),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode != 200) {
          debugPrint("Fehler beim Speichern von Spiel ID: ${spiel.id}");
          return response.statusCode;
        }
      }
      return 200;
    } catch (error) {
      debugPrint("Fehler beim Speichern der Ligaspiele: $error");
      return 400;
    }
  }

  Future<int> updateLigaSpiel(TennisMatch spiel) async {
    if (_token == null || _token.isEmpty) return 400;

    try {
      final jahr = spiel.datum.year;
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/LigaSpiele/$jahr/${spiel.id}.json?auth=$_token");
      // Datum und Uhrzeit in String umwandeln
      String formattedDatum = DateFormat('dd.MM.yyyy').format(spiel.datum);
      String formattedUhrzeit = spiel
          .uhrzeit; // Uhrzeit als String (kann angepasst werden, falls nötig)

      final updateResponse = await http.patch(
        url,
        body: json.encode({
          "ergebnis": spiel.ergebnis,
          "datum": formattedDatum, // Datum an Firebase übergeben
          "uhrzeit": formattedUhrzeit, // Uhrzeit an Firebase übergeben
          "spielbericht": spiel.spielbericht,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (updateResponse.statusCode == 200) {
        _cachedLigaSpiele.remove(jahr); // Cache für das Jahr invalidieren
        await loadLigaSpieleForYear(jahr);
        notifyListeners();
        return 200;
      } else {
        return updateResponse.statusCode;
      }
    } catch (error) {
      debugPrint("Fehler beim Aktualisieren des Ergebnisses: $error");
      return 400;
    }
  }

  Future<int> deleteLigaSpiel(TennisMatch spiel) async {
    if (_token == null || _token.isEmpty) return 400;

    try {
      final jahr = spiel.datum.year;
      final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/LigaSpiele/$jahr/${spiel.id}.json?auth=$_token",
      );

      final deleteResponse = await http.delete(url);

      if (deleteResponse.statusCode == 200) {
        _cachedLigaSpiele.remove(jahr); // Cache für das Jahr invalidieren
        await loadLigaSpieleForYear(jahr);
        notifyListeners();
        return 200;
      } else {
        return deleteResponse.statusCode;
      }
    } catch (error) {
      debugPrint("Fehler beim Löschen des Spiels: $error");
      return 400;
    }
  }
}
