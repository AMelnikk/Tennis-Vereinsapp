import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/app_utils.dart';
import '../models/team.dart';

class TeamProvider with ChangeNotifier {
  TeamProvider(this._writeToken);
  final String? _writeToken;
  final List<Team> _teams = [];

  final Map<String, Uint8List> imageCache = {};
  bool isDebug = false;

  // Map to cache already loaded seasons
  Map<String, List<Team>> teamCache = {};

  Future<void> loadDatatoCache(
      ScaffoldMessengerState messenger, String saisonKey) async {
    // Wenn die Saison bereits im Cache vorhanden ist, gib die Daten direkt aus dem Cache zurück
    if (teamCache.containsKey(saisonKey)) {
      //appError(
      //    messenger, 'Team Daten aus Cache geladen für Saison: $saisonKey');
      return; // Keine weiteren Aktionen notwendig, wenn Daten im Cache sind
    }

    final List<Team> loadedData = [];
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/$saisonKey.json");

    try {
      final response = await http.get(url);

      if (kDebugMode) {
        final bytes = utf8.encode(response.body).length; // Größe in Bytes
        final kilobytes = (bytes / 1024)
            .toStringAsFixed(2); // Umrechnung in KB mit 2 Nachkommastellen
        if (isDebug) {
          // Ausgabe der Datenmenge im Debug-Log
          debugPrint('➡️ Teamdaten geladen für $saisonKey: $kilobytes KB');
        }
      }
      // Prüfe den HTTP-Statuscode
      if (response.statusCode == 200) {
        final extractedData =
            json.decode(response.body) as Map<String, dynamic>?;

        // Überprüfen, ob Daten existieren
        if (extractedData != null) {
          // Daten in Team-Objekte umwandeln
          extractedData.forEach((resId, resData) {
            loadedData.add(Team.fromJson(resData, resId));
          });

          // Cache mit den geladenen Daten aktualisieren
          teamCache[saisonKey] = loadedData;

          //appError(messenger, 'Team Daten geladen für Saison: $saisonKey');
        } else {
          //appError(messenger, 'Keine Daten vorhanden.');
        }
      } else {
        // Fehlerhafte Antwort behandeln
        appError(messenger,
            'Fehler beim Abrufen der Daten: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      // Generelle Fehlerbehandlung
      appError(messenger, 'Fehler beim Abrufen der Daten: $e');
      rethrow; // Fehler weitergeben, falls er weiter oben behandelt werden soll
    }
  }

  List<Team> getFilteredMannschaften({String? saisonKey, String? mannschaft}) {
    List<Team> filteredTeams = [];

    // Überprüfen, ob die Saison im Cache existiert
    if (teamCache.containsKey(saisonKey)) {
      // Falls Saison im Cache vorhanden ist, Filter anwenden
      filteredTeams = teamCache[saisonKey]!.where((team) {
        final bool matchSaison = saisonKey == null || team.saison == saisonKey;
        final bool matchMannschaft = mannschaft == null ||
            mannschaft.isEmpty ||
            team.mannschaft == mannschaft;
        return matchSaison && matchMannschaft;
      }).toList();
    } else {
      // Falls keine Saison im Cache vorhanden ist, alle Teams filtern
      filteredTeams = _teams.where((team) {
        final bool matchSaison = saisonKey == null || team.saison == saisonKey;
        final bool matchMannschaft = mannschaft == null ||
            mannschaft.isEmpty ||
            team.mannschaft == mannschaft;
        return matchSaison && matchMannschaft;
      }).toList();
    }

    // Sortiere die gefilterten Teams nach Mannschaft
    filteredTeams.sort((a, b) => a.mannschaft.compareTo(b.mannschaft));

    return filteredTeams;
  }

  Future<int> _addTeam(Team newResult) async {
    if (_writeToken == null || _writeToken.isEmpty) {
      if (kDebugMode) print("Token fehlt");
      return 400;
    }
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/${newResult.saison}/${newResult.mannschaft}.json?auth=$_writeToken");

    try {
      final response = await http.put(
        url,
        body: newResult.toJson(),
        headers: {'Content-Type': 'application/json'},
      );

      //resetData();

      if (isDebug) debugPrint("Response status: ${response.statusCode}");
      if (isDebug) debugPrint("Response body: ${response.body}");

      return response.statusCode;
    } on SocketException {
      if (kDebugMode) print("Netzwerkfehler aufgetreten");
      return 500; // Fehler für Netzwerkprobleme
    } catch (error) {
      if (kDebugMode) print("Ein unerwarteter Fehler ist aufgetreten: $error");
      return 400;
    }
  }

  Future<void> deleteTeam(String saisonkey, String id) async {
    if (_writeToken == null || _writeToken.isEmpty) {
      throw Exception("Token fehlt");
    }

    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/$saisonkey/$id.json?auth=$_writeToken");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        // Entferne das Team aus der Liste der geladenen Teams
        _teams.removeWhere((result) => result.mannschaft == id);

        // Entferne das Team auch aus dem Cache
        if (teamCache[saisonkey] != null) {
          teamCache[saisonkey] = teamCache[saisonkey]!
              .where((team) =>
                  team.mannschaft != id) // Filtere das zu löschende Team aus
              .toList();
        }
      } else {
        throw Exception('Failed to delete the entry.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Method to add or update teams in the database
// Method to add or update teams in the database
  Future<void> addOrUpdateTeams(ScaffoldMessengerState messenger,
      String saisonKey, Set<Team> newteams) async {
    // Lade die Daten in den Cache, falls noch nicht geladen
    await loadDatatoCache(messenger, saisonKey);

    // Hole die bereits geladenen Teams aus dem Cache
    List<Team> existingteams = teamCache[saisonKey] ?? [];

    // Erstelle eine Map für eine schnelle Suche der bestehenden Teams
    Map<String, Team> teamsMap = {
      for (var team in existingteams) team.saison + team.mannschaft: team
    };

    // Wenn der Cache für diese Saison nicht existiert, initialisiere ihn
    if (teamCache[saisonKey] == null) {
      teamCache[saisonKey] = [];
    }

    // Iteriere über die neuen Teams und prüfe, ob sie bereits existieren
    for (var newTeam in newteams) {
      String key = newTeam.saison + newTeam.mannschaft;

      if (teamsMap.containsKey(key)) {
        // Team existiert, update es in der Datenbank und im Cache
        await _updateTeam(newTeam);

        // Aktualisiere das Team im Cache
        teamCache[saisonKey] = teamCache[saisonKey]!
            .map((team) => team.saison + team.mannschaft == key
                ? newTeam // Ersetze das alte Team mit dem aktualisierten
                : team)
            .toList();
      } else {
        // Team existiert nicht, füge es der Datenbank und dem Cache hinzu
        await _addTeam(newTeam);

        // Füge das neue Team zum Cache hinzu
        teamCache[saisonKey]!.add(newTeam);
      }
    }
  }

  Future<int> _updateTeam(Team existingTeam) async {
    if (_writeToken == null || _writeToken.isEmpty) {
      if (kDebugMode) print("Token fehlt");
      return 400; // Fehler: Kein Token vorhanden
    }

    final url = Uri.parse(
      "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/${existingTeam.saison}/${existingTeam.mannschaft}.json?auth=$_writeToken",
    );

    try {
      // Aktualisiere das Team, indem du die Werte aus existingTeam verwendest
      final response = await http.patch(
        url,
        body: json.encode(existingTeam.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (isDebug) {
          debugPrint("Team erfolgreich aktualisiert: ${response.body}");
        }
        return response.statusCode;
      } else {
        throw Exception('Fehler beim Aktualisieren des Teams.');
      }
    } on SocketException {
      if (kDebugMode) print("Netzwerkfehler aufgetreten");
      return 500; // Fehler für Netzwerkprobleme
    } catch (error) {
      if (kDebugMode) print("Ein unerwarteter Fehler ist aufgetreten: $error");
      return 400; // Allgemeiner Fehler
    }
  }
}
