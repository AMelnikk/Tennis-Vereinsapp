import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:verein_app/utils/app_utils.dart';
import '../models/team.dart';

class TeamProvider with ChangeNotifier {
  TeamProvider(this._writeToken);
  final String? _writeToken;
  List<Team> _teams = [];
  String _saisonKey = '';

  Future<List<Team>> getData(
      ScaffoldMessengerState messenger, saisonKey) async {
    //if (_token == null || _token.isEmpty) {
    //  throw Exception("Token fehlt");
    //}

    if (_teams.isNotEmpty && _saisonKey == saisonKey) {
      return _teams;
    }

    final List<Team> loadedData = [];
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/$saisonKey.json");
    //final url = Uri.parse("https://db-teg-default-rtdb.firebaseio.com/Mannschaften.json?auth=$_token");

    try {
      final response = await http.get(url);

      // Prüfe den HTTP-Statuscode
      if (response.statusCode == 200) {
        final extractedData =
            json.decode(response.body) as Map<String, dynamic>?;

        // Überprüfen, ob Daten existieren
        if (extractedData != null) {
          // Daten in GameResult-Objekte umwandeln
          extractedData.forEach((resId, resData) {
            loadedData.add(Team.fromJson(resData, resId));
          });

          _teams = loadedData;
          _saisonKey = saisonKey;
          appError(messenger, 'Team Daten geladen for Saison: $saisonKey');
        } else {
          appError(messenger, 'Keine Daten vorhanden.');
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

    return loadedData; // Gibt die Liste (ggf. leer) zurück
  }

  Future<int> addTeam(Team newResult) async {
    if (_writeToken == null || _writeToken.isEmpty) {
      if (kDebugMode) print("Token fehlt");
      return 400;
    }
    // final timestamp = DateTime.now().millisecondsSinceEpoch;
    final date = DateTime.now().toIso8601String();
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/${newResult.saison}/${newResult.mannschaft}.json?auth=$_writeToken");

    try {
      final response = await http.put(
        url,
        body: json.encode({
          'url': newResult.url,
          'saison': newResult.saison,
          'mannschaft': newResult.mannschaft,
          'liga': newResult.liga,
          'gruppe': newResult.gruppe, // Standardwert setzen
          'mf_name': newResult.mfName, // Standardwert setzen
          'mf_tel': newResult.mfTel, // Standardwert setzen
          'matchbilanz': newResult.matchbilanz, // Standardwert setzen
          'satzbilanz': newResult.satzbilanz, // Standardwert setzen
          'position': newResult.position, // Standardwert setzen
          'kommentar': newResult.kommentar, // Standardwert setzen
          'pdfBlob': newResult.pdfBlob != null
              ? base64Encode(newResult.pdfBlob!)
              : null,
          'photoBlob': newResult.photoBlob != null
              ? base64Encode(newResult.photoBlob!)
              : null,
          'creationDate': date,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      //resetData();

      if (kDebugMode) print("Response status: ${response.statusCode}");
      if (kDebugMode) print("Response body: ${response.body}");

      return response.statusCode;
    } on SocketException {
      if (kDebugMode) print("Netzwerkfehler aufgetreten");
      return 500; // Fehler für Netzwerkprobleme
    } catch (error) {
      if (kDebugMode) print("Ein unerwarteter Fehler ist aufgetreten: $error");
      return 400;
    }
  }

  Future<List<Team>> getFilteredData(String season, String team) async {
    List<Team> filteredResults = _teams;

    // Filtere nach Saison, wenn sie angegeben ist
    if (season.isNotEmpty) {
      filteredResults =
          filteredResults.where((game) => game.saison == season).toList();
    }

    // Filtere nach Mannschaft, wenn sie angegeben ist
    if (team.isNotEmpty) {
      filteredResults =
          filteredResults.where((game) => game.mannschaft == team).toList();
    }

    return filteredResults;
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
        _teams.removeWhere((result) => result.mannschaft == id);
      } else {
        throw Exception('Failed to delete the entry.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addOrUpdateTeams(ScaffoldMessengerState messenger,
      String saisonKey, Set<Team> newteams) async {
    // Fetch existing teams
    List<Team> existingteams = await getData(messenger, saisonKey);

    // Create a map for fast look-up based on team key (mannschaft + liga + gruppe)
    Map<String, Team> teamsMap = {
      for (var team in existingteams)
        team.mannschaft + team.liga + team.gruppe: team
    };

    // Iteriere durch die neuen Teams und prüfe, ob sie existieren
    for (var newTeam in newteams) {
      String key = newTeam.mannschaft + newTeam.liga + newTeam.gruppe;

      if (teamsMap.containsKey(key)) {
        // Team existiert bereits, aktualisiere es
        await updateTeam(newTeam);
      } else {
        // Team existiert noch nicht, füge es hinzu
        await addTeam(newTeam);
      }
    }
  }

  Future<int> updateTeam(Team existingTeam) async {
    if (_writeToken == null || _writeToken.isEmpty) {
      if (kDebugMode) print("Token fehlt");
      return 400; // Fehler: Kein Token vorhanden
    }

    final date = DateTime.now().toIso8601String();
    final url = Uri.parse(
      "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/${existingTeam.saison}/${existingTeam.mannschaft}.json?auth=$_writeToken",
    );

    try {
      // Aktualisiere das Team, indem du die Werte aus existingTeam verwendest
      final response = await http.patch(
        url,
        body: json.encode({
          'altersklasse': existingTeam.mannschaft,
          'spielklasse': existingTeam.liga,
          'gruppe': existingTeam.gruppe,
          'updateDate': date, // Datum der letzten Aktualisierung
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("Team erfolgreich aktualisiert: ${response.body}");
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
