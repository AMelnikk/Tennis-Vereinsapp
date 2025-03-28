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

  Future<int> saveTermineToFirebase(List<CalendarEvent> termine) async {
    if (_token == null || _token.isEmpty) {
      return 400; // Fehler: Kein Token vorhanden
    }

    try {
      // Finde alle Jahre aus den Terminen im Upload-File
      Set<int> jahre = termine.map((t) => t.date.year).toSet();

      // Lade alle Termine für diese Jahre auf einmal
      List<Map<String, dynamic>> allData = await loadAllTermineForYears(jahre);

      // Gehe durch alle Termine und prüfe, ob sie existieren oder neu hinzugefügt werden müssen
      for (var termin in termine) {
        // Überprüfe, ob der Termin schon existiert
        bool terminGefunden = await updateExistingTermin(allData, termin);
        if (terminGefunden) {
          continue; // Termin wurde aktualisiert, fahre mit dem nächsten fort
        }

        // Wenn der Termin nicht gefunden wurde, lege ihn als neuen Termin an
        await createNewTermin(termin);
      }

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
      try {
        final Map<String, dynamic> responseJson = json.decode(response.body);

        return Termin.fromMap(responseJson);
      } catch (e) {
        // print("Fehler beim Parsen des Termins: $e");
      }
    }

    return null; // Falls kein Termin gefunden wurde oder ein Fehler aufgetreten ist
  }

  Future<List<Map<String, dynamic>>> loadAllTermineForYears(
      Set<int> jahre) async {
    List<Map<String, dynamic>> allTermine = [];

    for (var jahr in jahre) {
      final url = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr.json?auth=$_token");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        dynamic responseJson =
            (response.body.isNotEmpty && response.body != "null")
                ? json.decode(response.body)
                : {};

        if (responseJson is Map<String, dynamic>) {
          allTermine
              .addAll(responseJson.values.whereType<Map<String, dynamic>>());
        } else if (responseJson is List) {
          allTermine.addAll(responseJson.whereType<Map<String, dynamic>>());
        }
      }
    }

    return allTermine;
  }

// Die Methode erwartet die Liste, also iteriere durch die Liste, um die Map zu übergeben
  Future<bool> updateExistingTermin(
      List<Map<String, dynamic>> allData, CalendarEvent termin) async {
    for (var event in allData) {
      final eventDate = DateTime.tryParse(event['date'] ?? '');
      final eventTitle = event['title'] ?? '';
      if (eventDate != null &&
          eventDate.year == termin.date.year &&
          eventDate.month == termin.date.month &&
          eventDate.day == termin.date.day &&
          eventTitle == termin.title) {
        // Termin existiert, also aktualisiere ihn
        final eventId = event['id'];
        final updateUrl = Uri.parse(
            "https://db-teg-default-rtdb.firebaseio.com/Termine/${termin.date.year}/$eventId.json?auth=$_token");

        final responsePut = await http.put(
          updateUrl,
          body: json.encode({
            'id': eventId,
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

        if (responsePut.statusCode == 200) {
          debugPrint("✅ Termin mit ID $eventId erfolgreich aktualisiert.");
          return true;
        } else {
          debugPrint("⚠️ Fehler beim Aktualisieren des Termins ID $eventId");
          return false;
        }
      }
    }
    return false; // Termin wurde nicht gefunden
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

    if (responsePut.statusCode == 200) {
      debugPrint("✅ Neuer Termin mit ID $newId gespeichert.");
    } else {
      debugPrint("⚠️ Fehler beim Speichern von Termin ID: $newId");
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
