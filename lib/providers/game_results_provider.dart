import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/game_result.dart';

class GameResultsProvider with ChangeNotifier {
  GameResultsProvider(this._token);
  final String? _token;
  List<GameResult> _gameResults = [];

  List<GameResult> get gameResults => _gameResults;

  Future<List<GameResult>> getData() async {
    //if (_token == null || _token.isEmpty) {
    //  throw Exception("Token fehlt");
    //}

    final List<GameResult> loadedData = [];
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Mannschaften.json");
    //final url = Uri.parse("https://db-teg-default-rtdb.firebaseio.com/Mannschaften.json?auth=$_token");

    try {
      final response = await http.get(url);

      // Prüfe den HTTP-Statuscode
      if (response.statusCode == 200) {
        final extractedData =
            json.decode(response.body) as Map<String, dynamic>?;

        // Überprüfen, ob Daten existieren
        if (extractedData != null) {
          if (kDebugMode) {
            print('Daten erhalten: $extractedData');
          }

          // Daten in GameResult-Objekte umwandeln
          extractedData.forEach((resId, resData) {
            loadedData.add(GameResult.fromJson(resData, resId));
          });

          _gameResults = loadedData;
        } else {
          if (kDebugMode) {
            print('Keine Daten vorhanden.');
          }
        }
      } else {
        // Fehlerhafte Antwort behandeln
        throw Exception(
            'Fehler beim Abrufen der Daten: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      // Generelle Fehlerbehandlung
      if (kDebugMode) {
        print('Fehler beim Abrufen der Daten: $e');
      }
      rethrow; // Fehler weitergeben, falls er weiter oben behandelt werden soll
    }

    return loadedData; // Gibt die Liste (ggf. leer) zurück
  }

  Future<int> addGameResult(GameResult newResult) async {
    if (_token == null || _token.isEmpty) {
      if (kDebugMode) print("Token fehlt");
      return 400;
    }
    final key = "${newResult.saison}_${newResult.mannschaft}";
    final date = DateTime.now().toIso8601String();
    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/Mannschaft_$key.json?auth=$_token");

    try {
      final response = await http.put(
        url,
        body: json.encode({
          'url': newResult.url,
          'saison': newResult.saison,
          'mannschaft': newResult.mannschaft,
          'liga': newResult.liga,
          'gruppe': newResult.gruppe, // Standardwert setzen
          'matchbilanz': newResult.matchbilanz, // Standardwert setzen
          'satzbilanz': newResult.satzbilanz, // Standardwert setzen
          'position': newResult.position, // Standardwert setzen
          'kommentar': newResult.kommentar, // Standardwert setzen
          'pdfBlob': newResult.pdfBlob != null
              ? base64Encode(newResult.pdfBlob!)
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

  Future<void> deleteGameResult(String id) async {
    if (_token == null || _token.isEmpty) {
      throw Exception("Token fehlt");
    }

    final url = Uri.parse(
        "https://db-teg-default-rtdb.firebaseio.com/Mannschaften/$id.json?auth=$_token");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        _gameResults.removeWhere((result) => result.id == id);
        notifyListeners();
      } else {
        throw Exception('Failed to delete the entry.');
      }
    } catch (e) {
      rethrow;
    }
  }
}
