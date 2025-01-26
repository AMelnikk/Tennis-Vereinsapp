import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:verein_app/models/CalendarEvent.dart';

class TermineProvider with ChangeNotifier {
  TermineProvider(this._token);

  final String? _token;
  List<CalendarEvent> events = [];
  bool isLoading = false;

  /// Speichert die Liste der Termine in Firebase
  Future<int> saveTermineToFirebase(List<Map<String, dynamic>> termine) async {
    if (_token == null || _token.isEmpty) {
      return 400; // Fehler: Kein Token vorhanden
    }

    try {
      for (var termin in termine) {
        // Erstelle eindeutige URL basierend auf Firebase-Pfad
        final url = Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Termine/${termin['id']}.json?auth=$_token");

        // Sende die Daten an Firebase
        final response = await http.put(
          url,
          body: json.encode({
            'id': termin['id'], // ID des Termins
            'datum':
                termin['datum'].toIso8601String(), // Datum im ISO8601-Format
            'ereignis': termin['ereignis'], // Ereignisbeschreibung
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode != 200) {
          // Fehler beim Speichern des Termins
          debugPrint("Fehler beim Speichern von Termin ID: ${termin['id']}");
          return response.statusCode;
        }
      }

      // Erfolgreich verarbeitet
      return 200;
    } on SocketException {
      // Netzwerkfehler
      debugPrint("Netzwerkfehler beim Speichern der Termine");
      return 500;
    } catch (error) {
      // Allgemeiner Fehler
      debugPrint("Fehler beim Speichern der Termine: $error");
      return 400;
    }
  }

  /// Lädt die Termine vom Server (z. B. Firebase) und speichert sie in der Liste
  Future<void> loadEvents() async {
    isLoading = true;

    try {
      final url =
          Uri.parse("https://db-teg-default-rtdb.firebaseio.com/Termine.json");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Überprüfe, ob die Antwort eine Map oder Liste ist
        if (data is Map<String, dynamic>) {
          // Firebase gibt eine Map zurück
          events = data.entries
              .map((entry) {
                final eventData = entry.value;

                // Null-Prüfung für eventData, bevor auf die Daten zugegriffen wird
                if (eventData != null) {
                  return CalendarEvent(
                    id: eventData['id'] ??
                        'Unknown', // Falls 'id' fehlt, wird 'Unknown' gesetzt
                    date: DateTime.tryParse(eventData['datum'] ?? '') ??
                        DateTime
                            .now(), // Wenn Datum fehlt, setze das aktuelle Datum
                    title: eventData['ereignis'] ??
                        'Kein Titel', // Falls kein Titel vorhanden, 'Kein Titel' setzen
                  );
                } else {
                  debugPrint("Ungültige Daten für Event: $entry");
                  return null; // Überspringe ungültige Events
                }
              })
              .whereType<CalendarEvent>()
              .toList(); // Entferne null-Events
        } else if (data is List) {
          // Firebase gibt eine Liste zurück
          events = data
              .map((item) {
                // Null-Prüfung für item
                if (item != null) {
                  return CalendarEvent(
                    id: item['id'] ?? 'Unknown',
                    date: DateTime.tryParse(item['datum'] ?? '') ??
                        DateTime.now(),
                    title: item['ereignis'] ?? 'Kein Titel',
                  );
                } else {
                  debugPrint("Ungültige Daten für Event in Liste: $item");
                  return null;
                }
              })
              .whereType<CalendarEvent>()
              .toList();
        } else {
          // Unbekanntes Format
          events = [];
        }
      } else {
        throw Exception("Fehler beim Laden der Termine");
      }
    } catch (error) {
      debugPrint("Fehler beim Laden der Termine: $error");
      events = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
