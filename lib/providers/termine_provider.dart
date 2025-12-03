import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:verein_app/models/termin.dart';
import '../models/calendar_event.dart';
import '../models/calendar_event_registration.dart';

class TermineProvider with ChangeNotifier {
  TermineProvider(this._token);

  final String? _token;

  Map<int, List<CalendarEvent>> eventsCache = {}; // Termine und LigaSpiele

  bool isLoading = false;
  bool isDebugMode = true;

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
      await loadEvents(DateTime.now().year, true);

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

  void updateEvent(CalendarEvent updatedEvent) {
    final eventYear =
        updatedEvent.date.year; // Annahme: Datum hat das Event-Datum

    if (eventsCache.containsKey(eventYear)) {
      // 1. Die spezifische Liste für dieses Jahr abrufen
      final listToUpdate = eventsCache[eventYear]!;

      // 2. Index in dieser Liste finden
      final index = listToUpdate.indexWhere((e) => e.id == updatedEvent.id);

      if (index != -1) {
        // 3. Liste aktualisieren (immutable-freundlich)
        final updatedList = List<CalendarEvent>.from(listToUpdate);
        updatedList[index] = updatedEvent;

        // 4. Cache aktualisieren und benachrichtigen
        eventsCache[eventYear] = updatedList;
        notifyListeners();
      }
    }
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
      if (isDebugMode) {
        debugPrint("✅ Termin mit ID $eventId erfolgreich aktualisiert.");
      }
      return true;
    } else {
      if (isDebugMode) {
        debugPrint("⚠️ Fehler beim Aktualisieren des Termins ID $eventId");
      }
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
        'ort': termin.ort,
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

  /// Lädt die Termine vom Server und reichert sie mit Anmeldedaten an.
  /// **Optimiert: Anmeldungen werden jetzt in einem Bulk-Request geladen.**
  Future<List<CalendarEvent>> loadEvents(int jahr, bool forceReload) async {
    // 1. Cache-Prüfung: Wenn Daten vorhanden und kein Neuladen erzwungen wird.
    if (eventsCache.containsKey(jahr) && !forceReload) {
      debugPrint("✅ Termine $jahr aus dem Cache geladen.");
      return eventsCache[jahr]!;
    }

    isLoading = true;
    List<CalendarEvent> loadedEvents = [];
    List<Map<String, dynamic>> data = [];

    try {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr.json");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        dynamic responseJson =
            (response.body.isNotEmpty && response.body != "null")
                ? json.decode(response.body)
                : {};

        if (responseJson is Map<String, dynamic>) {
          data = responseJson.values
              .where((event) => event != null && event is Map<String, dynamic>)
              .cast<Map<String, dynamic>>()
              .toList();
        } else if (responseJson is List) {
          data = responseJson
              .where((event) => event != null && event is Map<String, dynamic>)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      } else {
        debugPrint(
            "⚠️ Fehler beim Abrufen der Termindaten: ${response.statusCode}");
      }

      // 1. Events aus den validen Daten erstellen (Initialisierung)
      loadedEvents = data.map((eventData) {
        return CalendarEvent(
          id: eventData['id'] is int ? eventData['id'] : 0,
          date: DateTime.tryParse(eventData['date'] ?? '') ?? DateTime.now(),
          von: eventData['von'] ?? '',
          bis: eventData['bis'] ?? '',
          title: eventData['title'] ?? 'Kein Titel',
          ort: eventData['ort'] ?? 'Kein Titel',
          description: eventData['details'] ?? '',
          category: eventData['category'] ?? '',
          query: eventData['query'] ?? '',
          // WICHTIG: Hier werden die Registrierungs-Felder leer initialisiert
          registrationCount: 0,
          allRegistrations: [], // Leere Liste initialisieren
        );
      }).toList();

      // 💥 OPTIMIERUNG: Lade ALLE Anmeldungen für das gesamte Jahr in einem Request
      final allRegistrationsByTermin = await _loadAllRegistrationsForYear(jahr);

      // Durchlaufe die geladenen Termine und reicher sie mit Anmeldedaten an.
      // KEINE HTTP-AUFRUFE MEHR IN DIESER SCHLEIFE!
      for (final event in loadedEvents) {
        // Registrierungen für dieses Event aus der Bulk-Map abrufen
        final List<EventRegistration> allRegistrations =
            allRegistrationsByTermin[event.id] ?? [];

        int jaCount = 0;

        // Registrierungen filtern und cachen
        for (var reg in allRegistrations) {
          // Annahme: reg.status ist ein boolscher Wert (true = Ja)
          // (Siehe Kommentar im Original-Code: "Vergleiche mit dem String 'ja',
          // nicht mit dem Booleschen Wert true". Bei Unklarheit den Typ im Model prüfen.)
          if (reg.status) {
            jaCount += reg.peopleCount ?? 1;
          }
        }

        // Setze die Cache-Daten (Annahme: CalendarEvent ist mutierbar oder wird hier aktualisiert)
        // BESSER wäre ein event.copyWith({...}) und das Ersetzen in loadedEvents
        event.allRegistrations = allRegistrations;
        event.registrationCount = jaCount;
      }
    } catch (error) {
      debugPrint("❌ Fehler beim Laden der Termine: $error");
      loadedEvents = []; // Im Fehlerfall leere Liste zurückgeben
    } finally {
      isLoading = false;
      notifyListeners();
    }

    // 3. Cache-Aktualisierung: Speichere die angereicherten Events
    eventsCache[jahr] = loadedEvents;
    return loadedEvents;
  }

  /// Speichert die Anmeldung (JA oder NEIN) in Firebase.
  Future<bool> saveRegistration(EventRegistration anmeldung) async {
    if (_token == null || _token.isEmpty) {
      return false;
    }

    // Wir verwenden die terminId (z.B. 2) und das Jahr (z.B. 2025) für den Pfad
    // und nutzen die userId als Schlüssel, um nur eine Antwort pro Benutzer zu erlauben.
    final jahr = anmeldung.timestamp.year;

    // Struktur: /Anmeldungen/{jahr}/{terminId}/{userId}.json
    final url = Uri.parse(
      "https://db-teg-default-rtdb.firebaseio.com/EventRegistration/$jahr/${anmeldung.terminId}/${anmeldung.userId}.json?auth=$_token",
    );

    // Erstelle die Daten-Map aus dem Model, aber ohne die temporäre registrationId
    final Map<String, dynamic> dataToSend = anmeldung.toMap();
    dataToSend.remove('registrationId');

    try {
      final response = await http.put(
        url,
        body: json.encode(dataToSend),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (isDebugMode) {
          debugPrint(
              "✅ Anmeldung für Termin ${anmeldung.terminId} (${anmeldung.status}) erfolgreich gespeichert.");
        }
        // Optional: Nach der Anmeldung die Event-Details neu laden oder cache aktualisieren.
        // notifyListeners();
        return true;
      } else {
        if (isDebugMode) {
          debugPrint(
              "⚠️ Fehler beim Speichern der Anmeldung: ${response.statusCode}");
        }
        return false;
      }
    } catch (error) {
      debugPrint("❌ Netzwerkfehler beim Speichern der Anmeldung: $error");
      return false;
    }
  }

  /// OPTIMIERUNG: Lädt ALLE Anmeldungen für ein Jahr in einem einzigen Request.
  /// Struktur: {terminId: [EventRegistration, ...], ...}
  Future<Map<int, List<EventRegistration>>> _loadAllRegistrationsForYear(
      int jahr) async {
    if (_token == null || _token.isEmpty) {
      return {};
    }

    // URL, um alle Kinder unterhalb des Jahresknotens abzurufen
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/EventRegistration/$jahr.json?auth=$_token");

    final Map<int, List<EventRegistration>> registrationsByTerminId = {};

    try {
      final response = await http.get(url);

      if (response.statusCode != 200 || response.body == "null") {
        return {};
      }

      // JSON-Struktur ist: {<terminId>: {<userId>: {data}, <userId2>: {data2}}, ...}
      final Map<String, dynamic> responseJson = json.decode(response.body);

      responseJson.forEach((terminIdStr, registrationsMap) {
        final terminId = int.tryParse(terminIdStr);

        if (terminId != null && registrationsMap is Map<String, dynamic>) {
          registrationsByTerminId[terminId] = [];

          registrationsMap.forEach((userId, data) {
            if (data is Map<String, dynamic>) {
              try {
                // Firebase-Schlüssel (userId) als registrationId nutzen
                data['registrationId'] = userId;
                // Füge die terminId hinzu
                data['terminId'] = terminId;

                registrationsByTerminId[terminId]!
                    .add(EventRegistration.fromMap(data));
              } catch (e) {
                if (isDebugMode) {
                  debugPrint(
                      "Fehler beim Parsen einer Anmeldung für Termin $terminId ($userId): $e");
                }
              }
            }
          });
        }
      });
    } catch (error) {
      debugPrint(
          "❌ Fehler beim Laden aller Anmeldungen für Jahr $jahr: $error");
      return {};
    }

    return registrationsByTerminId;
  }

  /// Lädt die Anmeldungen für einen bestimmten Termin.
  Future<List<EventRegistration>> loadRegistrationsForEvent(
      int jahr, int terminId) async {
    if (_token == null || _token.isEmpty) {
      return [];
    }

    final url = Uri.parse(
      "https://db-teg-default-rtdb.firebaseio.com/EventRegistration/$jahr/$terminId.json?auth=$_token",
    );

    final List<EventRegistration> anmeldungen = [];

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != "null") {
        final Map<String, dynamic> responseJson = json.decode(response.body);

        responseJson.forEach((userId, data) {
          if (data is Map<String, dynamic>) {
            try {
              // Firebase-Schlüssel (userId) als registrationId nutzen,
              // da wir keine separate ID speichern.
              data['registrationId'] = userId;
              // Füge die terminId hinzu, da sie nicht in den Kind-Daten gespeichert ist
              data['terminId'] = terminId;

              anmeldungen.add(EventRegistration.fromMap(data));
            } catch (e) {
              debugPrint("Fehler beim Parsen einer Anmeldung ($userId): $e");
            }
          }
        });
      }
    } catch (error) {
      debugPrint("❌ Fehler beim Laden der Anmeldungen: $error");
    }

    return anmeldungen;
  }
}
