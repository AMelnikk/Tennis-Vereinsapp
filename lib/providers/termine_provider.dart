import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ANGENOMMENE MODELLE:
class Termin {
  final String id;
  final String title;
  // Fügen Sie hier alle weiteren Felder hinzu, die Ihr Termin-Modell benötigt
  Termin(this.id, this.title);
  static Termin fromMap(Map<String, dynamic> data) =>
      Termin(data['id'] ?? '', data['title'] ?? '');
}

class CalendarEvent {
  final DateTime date;
  final String title;
  final String category;
  final String description;
  final String von;
  final String bis;
  final String ort;
  final String query;

  CalendarEvent({
    required this.date,
    required this.title,
    required this.category,
    required this.description,
    required this.von,
    required this.bis,
    required this.ort,
    required this.query,
  });
}
// ENDE DER ANGENOMMENEN MODELLE

class TermineProvider extends ChangeNotifier {
  // === FELDER FÜR DIE KLASSE ===
  final String? _token;
  bool _isLoading =
      false; // Hinzugefügt, um den Fehler 'Setter not found: isLoading' zu beheben

  // Da die App anscheinend Events pro Jahr lädt, speichern wir diese hier.
  List<Map<String, dynamic>> _termineCache = [];

  // Getter
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get termine => _termineCache;

  TermineProvider(this._token);

  // === HILFSMETHODE: Termin in Firebase erstellen ===
  Future<bool> createNewTermin(CalendarEvent termin) async {
    if (_token == null || _token!.isEmpty) return false;

    final jahr = termin.date.year;
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr.json?auth=$_token");

    final response = await http.post(
      url,
      body: json.encode({
        'date': DateFormat('yyyy-MM-dd').format(termin.date),
        'von': termin.von,
        'bis': termin.bis,
        'title': termin.title,
        'category': termin.category,
        'details': termin.description,
        'ort': termin.ort,
        'query': termin.query,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final newId = responseBody['name'];

      // Patch, um die ID in den Daten zu speichern (optional)
      final patchUrl = Uri.parse(
          "https://db-teg-default-rtdb.firebaseio.com/Termine/$jahr/$newId.json?auth=$_token");
      await http.patch(patchUrl, body: json.encode({'id': newId}));

      debugPrint("✅ Neuer Termin mit ID $newId erfolgreich angelegt.");
      return true;
    } else {
      debugPrint("⚠️ Fehler beim Anlegen des Termins: ${response.body}");
      return false;
    }
  }

  // === HILFSMETHODE: Termin in Firebase aktualisieren (Behebt den Fehler '_updateTermin' not defined) ===
  Future<bool> _updateTermin(
      Map<String, dynamic> existingEvent, CalendarEvent newTermin) async {
    if (_token == null || _token!.isEmpty) return false;

    final eventId = existingEvent['id'] ?? '';
    final jahr = newTermin.date.year;

    if (eventId.isEmpty) {
      debugPrint("⚠️ Termin ID fehlt für Update.");
      return false;
    }

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
        'details': newTermin.description,
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
      debugPrint(
          "⚠️ Fehler beim Aktualisieren des Termins ID $eventId: ${responsePut.body}");
      return false;
    }
  }

  // === HAUPTMETHODE: Speichert eine Liste von Terminen ===
  Future<int> saveTermineToFirebase(List<CalendarEvent> termine) async {
    if (_token == null || _token!.isEmpty) {
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
          continue; // Termin wurde aktualisiert oder war unverändert, fahre mit dem nächsten fort
        }

        // Wenn der Termin nicht gefunden wurde, lege ihn als neuen Termin an
        await createNewTermin(termin);
      }

      // Aktualisiere den Cache und benachrichtige Listener nach dem Speichern/Aktualisieren
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

  // === Methode zur Überprüfung und Aktualisierung eines existierenden Termins (Korrigierte Syntax) ===
  Future<bool> updateExistingTermin(
      List<Map<String, dynamic>> allData, CalendarEvent termin) async {
    // Fehlerbehebung: Die Schleife und der Rückgabewert müssen vollständig im Methoden-Body sein
    for (var existingEvent in allData) {
      final eventDate = DateTime.tryParse(existingEvent['date'] ?? '');
      final eventTitle = existingEvent['title'] ?? '';

      // 1. Prüfe, ob Datum und Titel übereinstimmen
      if (eventDate != null &&
          eventDate.year == termin.date.year &&
          eventDate.month == termin.date.month &&
          eventDate.day == termin.date.day &&
          eventTitle == termin.title) {
        // 2. Prüfe auf Änderungen in den Details
        final isModified = existingEvent['category'] != termin.category ||
            existingEvent['details'] != termin.description ||
            existingEvent['von'] != termin.von ||
            existingEvent['bis'] != termin.bis ||
            existingEvent['ort'] != termin.ort ||
            existingEvent['query'] != termin.query;

        if (isModified) {
          // Änderungen gefunden → Aktualisieren
          debugPrint(
              "✅ Änderungen gefunden für '${termin.title}'. Wird aktualisiert.");
          return await _updateTermin(existingEvent, termin);
        } else {
          // Keine Änderungen notwendig
          debugPrint(
              "☑️ Termin: '${termin.title}' - Keine Änderungen, übersprungen.");
          return true;
        }
      }
    }

    // Termin wurde nicht gefunden. Dieser return-Wert war zuvor fehlerhaft platziert.
    return false;
  }

  // === NEUE METHODE: Lädt Events für ein Jahr (Behebt den Fehler 'loadEvents' not defined) ===
  Future<void> loadEvents(int jahr) async {
    _isLoading = true; // Behebt den Fehler 'Setter not found: isLoading'
    notifyListeners(); // Behebt den Fehler 'Method not found: notifyListeners'

    try {
      Set<int> jahre = {jahr};
      _termineCache = await loadAllTermineForYears(jahre);
      debugPrint("Geladene Termine für Jahr $jahr: ${_termineCache.length}");
    } catch (e) {
      debugPrint("Fehler beim Laden der Events: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // === HILFSMETHODE: Lädt alle Termine für eine Reihe von Jahren ===
  Future<List<Map<String, dynamic>>> loadAllTermineForYears(
      Set<int> jahre) async {
    if (_token == null || _token!.isEmpty) return [];

    List<Map<String, dynamic>> allTermine = [];

    for (var jahr in jahre) {
      // Korrigierte Verwendung von _token
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
          // Fallback, obwohl Realtime DB Maps bevorzugt
          allTermine.addAll(responseJson.whereType<Map<String, dynamic>>());
        }
      }
    }

    return allTermine;
  }

  // === HILFSMETHODE: Lädt einen einzelnen Termin ===
  Future<Termin?> loadTerminForYear(int jahr, String terminId) async {
    if (_token == null || _token!.isEmpty) return null;

    // Korrigierte Verwendung von _token
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
        debugPrint("Fehler beim Parsen des Termins: $e");
      }
    }

    return null;
  }
}
