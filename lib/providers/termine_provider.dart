// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:verein_app/models/termin.dart';
import '../models/calendar_event.dart';

class TermineProvider with ChangeNotifier {
  TermineProvider(this._token);

  final String? _token;
  Map<int, List<CalendarEvent>> eventsCache = {}; // Termine und LigaSpiele

  bool isLoading = false;
  bool isDebugMode = false;

  // Die lokale Variable allData erwartet jetzt List<CalendarEvent>.
  Future<int> saveTermineToFirebase(List<CalendarEvent> termine) async {
    if (_token == null || _token.isEmpty) {
      return 400; // Fehler: Kein Token vorhanden
    }

    try {
      // Finde alle Jahre aus den Terminen im Upload-File
      Set<int> jahre = termine.map((t) => t.date.year).toSet();

      // Lade alle Termine für diese Jahre auf einmal. NEU: allData ist jetzt typsicher.
      List<CalendarEvent> allData = await loadAllTermineForYears(jahre);

      for (var termin in termine) {
        bool found = false;

        for (var existingEvent in allData) {
          if (_isSameEventIdentity(existingEvent, termin)) {
            found = true;
            if (_areDetailsModified(existingEvent, termin)) {
              if (isDebugMode) {
                debugPrint(
                    "✅ Änderungen gefunden. Aktualisiere über _updateTermin.");
              }
              await _updateTermin(existingEvent, termin);
            } else {
              if (isDebugMode) {
                debugPrint(
                    "☑️ Termin: '${termin.title}' - Keine Änderungen, übersprungen.");
              }
            }
            break; // Termin gefunden, keine weiteren Vergleiche nötig
          }
        }

        if (!found) {
          await createNewTermin(termin);
        }
      }

      // Nach dem Speichern die Events neu laden und Benachrichtigung auslösen
      await loadEvents(DateTime.now().year);

      return 200;
    } on SocketException {
      debugPrint("⚠️ Netzwerkfehler beim Speichern der Termine");
      return 500;
    } catch (error) {
      debugPrint("⚠️ Fehler beim Speichern der Termine: $error");
      return 400;
    }
  }

  Future<Termin?> loadTerminForYear(int jahr, String terminId) async {
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr/$terminId.json?auth=$_token");

    final response = await http.get(url);

    if (response.statusCode == 200 &&
        response.body.isNotEmpty &&
        response.body != "null") {
      if (isDebugMode) {
        debugPrint(
            "loadAllTermineForYears: ✅ Termine $jahr geladen, Größe: ${response.body.length} bytes");
      }
      try {
        final Map<String, dynamic> responseJson = json.decode(response.body);

        return Termin.fromMap(responseJson);
      } catch (e) {
        // print("Fehler beim Parsen des Termins: $e");
      }
    }

    return null; // Falls kein Termin gefunden wurde oder ein Fehler aufgetreten ist
  }

  Future<List<CalendarEvent>> loadAllTermineForYears(Set<int> jahre) async {
    if (isDebugMode) {
      debugPrint("➡️ loadAllTermineForYears called with years: $jahre");
    }

    List<CalendarEvent> allTermine = [];

    if (jahre.isEmpty) {
      if (isDebugMode) {
        debugPrint("⚠️ Jahresset ist leer - nichts zu laden.");
      }
      return allTermine;
    }
    for (var jahr in jahre) {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr.json?auth=$_token");
      debugPrint("-> Requesting $url");

      try {
        final response = await http.get(url);
        debugPrint("HTTP ${response.statusCode} for $url");

        if (response.statusCode != 200) {
          if (isDebugMode) {
            debugPrint(
                "⚠️ Fehler beim Laden der Termine für $jahr: Status ${response.statusCode}");
          }
          continue;
        }

        if (response.body.isEmpty || response.body == "null") {
          if (isDebugMode) {
            debugPrint("ℹ️ Leerer Body für Jahr $jahr");
          }
          continue;
        }

        // Kurzer Body-Snippet zum schnellen Check
        final bodySnippet = response.body.length > 400
            ? response.body.substring(0, 400) + "…(truncated)"
            : response.body;

        if (isDebugMode) {
          debugPrint("Body snippet: $bodySnippet");
        }
        dynamic responseJson;
        try {
          responseJson = json.decode(response.body);
        } catch (e) {
          debugPrint("❌ JSON decode failed for year $jahr: $e");
          continue;
        }

        // Falls Firebase eine Map zurückgibt (gewöhnlicher Fall)
        if (responseJson is Map) {
          responseJson.forEach((id, value) {
            try {
              if (value == null) return;

              // Normalisiere zu Map<String, dynamic>
              if (value is Map) {
                final Map<String, dynamic> map = Map<String, dynamic>.from(
                    value.map((k, v) => MapEntry(k.toString(), v)));
                // optional: map['id'] = map['id'] ?? int.tryParse(id.toString()) ?? 0;
                final CalendarEvent t = CalendarEvent.fromMap(map);
                allTermine.add(t);
              } else {
                if (isDebugMode) {
                  debugPrint(
                      "⚠️ Ignoriere value für id $id: nicht Map (Typ: ${value.runtimeType})");
                }
              }
            } catch (e, st) {
              debugPrint(
                  "⚠️ Fehler beim Parsen von Termin ID $id für Jahr $jahr: $e");
              debugPrint("$st");
            }
          });
        } else if (responseJson is List) {
          // Falls DB als Liste geliefert wird (seltener), durchlaufen
          for (var i = 0; i < responseJson.length; i++) {
            final entry = responseJson[i];
            try {
              if (entry is Map) {
                final map = Map<String, dynamic>.from(
                    entry.map((k, v) => MapEntry(k.toString(), v)));
                final CalendarEvent t = CalendarEvent.fromMap(map);
                allTermine.add(t);
              } else {
                if (isDebugMode) {
                  debugPrint(
                      "⚠️ Ignoriere Listeneintrag $i vom Typ ${entry.runtimeType}");
                }
              }
            } catch (e, st) {
              debugPrint(
                  "⚠️ Fehler beim Parsen Listeneintrag $i für Jahr $jahr: $e");
              debugPrint("$st");
            }
          }
        } else {
          if (isDebugMode) {
            debugPrint(
                "⚠️ Unerwarteter JSON-Typ für Jahr $jahr: ${responseJson.runtimeType}");
          }
        }
      } catch (error, st) {
        debugPrint("❌ Netzwerk- oder Parsing-Fehler für Jahr $jahr: $error");
        debugPrint("$st");
      }
    }
    if (isDebugMode) {
      debugPrint(
          "⬅️ loadAllTermineForYears returning ${allTermine.length} events");
    }
    return allTermine;
  }

  // HILFSMETHODE: Führt den PUT-Request zur Aktualisierung durch
  Future<bool> _updateTermin(
      CalendarEvent existingEvent, CalendarEvent newTermin) async {
    // Stellen Sie sicher, dass die ID existiert und das Token gültig ist
    if (_token == null || _token.isEmpty) {
      return false;
    }
    // Die ID des bereits existierenden Events verwenden
    final eventId = existingEvent.id;
    final jahr = newTermin.date.year;

    final updateUrl = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr/$eventId.json?auth=$_token");

    final responsePut = await http.put(
      updateUrl,
      body: json.encode({
        'id': eventId,
        'date': DateFormat('yyyy-MM-dd').format(newTermin.date),
        'von': newTermin.von,
        'bis': newTermin.bis,
        'title': newTermin.title,
        'category': newTermin.category,
        'details':
            newTermin.description, // description wird zu 'details' für die DB
        'ort': newTermin.ort,
        'query': newTermin.query,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (responsePut.statusCode == 200) {
      debugPrint("✅ Termin mit ID $eventId erfolgreich aktualisiert.");
      return true;
    } else {
      debugPrint("⚠️ Fehler beim Aktualisieren des Termins ID $eventId");
      return false;
    }
  }

  bool _isSameEventIdentity(
      CalendarEvent existingEvent, CalendarEvent incomingTermin) {
    // Konvertierung in einen String (yyyy-MM-dd) zur Vermeidung von Problemen mit der Uhrzeit-Komponente.
    final existingDateString =
        DateFormat('yyyy-MM-dd').format(existingEvent.date);
    final incomingDateString =
        DateFormat('yyyy-MM-dd').format(incomingTermin.date);

    // Identität wird über Datum und Titel definiert
    return existingDateString == incomingDateString &&
        existingEvent.title == incomingTermin.title;
  }

  // === HILFSMETHODE: Prüft, ob sich Details eines Termins geändert haben ===
  // Wird nur aufgerufen, wenn _isSameEventIdentity true ist.
  bool _areDetailsModified(
      CalendarEvent existingEvent, CalendarEvent newTermin) {
    // Vergleich aller Detailfelder des typsicheren Objekts.
    return existingEvent.category != newTermin.category ||
        existingEvent.description != newTermin.description ||
        existingEvent.von != newTermin.von ||
        existingEvent.bis != newTermin.bis ||
        existingEvent.ort != newTermin.ort ||
        existingEvent.query != newTermin.query;
  }

// Die Methode erwartet die Liste, also iteriere durch die Liste, um die Map zu übergeben
  Future<void> createNewTermin(CalendarEvent termin) async {
    final counterUrl = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Termine/counter.json?auth=$_token");

    // 1️⃣ Counter abrufen
    final responseCounter = await http.get(counterUrl);

    int newId = 1; // Standardwert, falls der Zähler noch nicht existiert

    if (responseCounter.statusCode == 200 && responseCounter.body.isNotEmpty) {
      final counterData = json.decode(responseCounter.body);

      if (counterData is int) {
        newId = counterData; // Falls nur eine Zahl gespeichert ist
      } else if (counterData is Map<String, dynamic> &&
          counterData.containsKey('id')) {
        newId = counterData['id'];
      }
    } else {
      // Falls kein Zähler existiert, initialisiere ihn mit 1
      await http.put(
        counterUrl,
        body: json.encode(1),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // ✅ Jetzt haben wir eine eindeutige ID (newId)

    final jahr = termin.date.year;
    final newUrl = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr/$newId.json?auth=$_token");

    // 2️⃣ Neuen Termin mit der neuen ID speichern
    final responsePut = await http.put(
      newUrl,
      body: json.encode({
        'id': newId,
        'date': DateFormat('yyyy-MM-dd').format(termin.date),
        'von': termin.von,
        'bis': termin.bis,
        'title': termin.title,
        'category': termin.category,
        'details': termin.description,
        'query': termin.query,
        'lastUpdate': DateTime.now()
            .millisecondsSinceEpoch, // Stellt sicher, dass ein int verwendet wird
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (isDebugMode) {
      if (responsePut.statusCode == 200) {
        debugPrint("✅ Neuer Termin mit ID $newId gespeichert.");
      } else {
        debugPrint("⚠️ Fehler beim Speichern von Termin ID: $newId");
      }
    }
    // 3️⃣ Zähler in Firebase hochzählen
    await http.put(
      counterUrl,
      body: json.encode(newId + 1),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Lädt die Termine vom Server (z. B. Firebase) und speichert sie in der Liste
  Future<List<CalendarEvent>> loadEvents(int jahr) async {
    isLoading = true;
    List<CalendarEvent> termine = [];
    List<Map<String, dynamic>> data = [];

    try {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr.json");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Prüfen, ob die Antwort nicht leer oder "null" ist
        debugPrint(
            "loadEvents: ✅ Termine $jahr geladen, Größe: ${response.body.length} bytes");
        dynamic responseJson =
            (response.body.isNotEmpty && response.body != "null")
                ? json.decode(response.body)
                : {};

        if (responseJson is Map<String, dynamic>) {
          // Falls eine Map zurückkommt, die Werte extrahieren
          data = responseJson.values
              .where((event) => event != null && event is Map<String, dynamic>)
              .cast<Map<String, dynamic>>()
              .toList();
        } else if (responseJson is List) {
          // Falls eine Liste zurückkommt, direkt umwandeln
          data = responseJson
              .where((event) => event != null && event is Map<String, dynamic>)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      } else {
        debugPrint("⚠️ Fehler beim Abrufen der Daten: ${response.statusCode}");
      }

      // Events aus den validen Daten erstellen
      termine = data.map((eventData) {
        return CalendarEvent(
          id: eventData['id'] is int
              ? eventData['id']
              : 0, // Sicherstellen, dass die ID ein int ist
          date: DateTime.tryParse(eventData['date'] ?? '') ?? DateTime.now(),
          von: eventData['von'] ?? '',
          bis: eventData['bis'] ?? '',
          title: eventData['title'] ?? 'Kein Titel',
          ort: eventData['ort'] ?? 'Kein Titel',
          description: eventData['details'] ?? '',
          category: eventData['category'] ?? '',
          query: eventData['query'] ?? '',
        );
      }).toList();
    } catch (error) {
      debugPrint("❌ Fehler beim Laden der Termine: $error");
      termine = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return termine; // Rückgabe der geladenen Termine
  }
}
